import AlarmKit
import AppIntents
import CoreMotion
import EventKit
import Flutter
import HealthKit
import SwiftUI
import UIKit
import UserNotifications
import alarm_kit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Reminders (flutter_local_notifications): taps and buttons reach the app.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    // The alarm's buttons (vault Umsetzung/Echter Wecker).
    if #available(iOS 26.0, *) {
      AlarmKitIntents.register { key in
        switch key {
        case "aufstehen": return AufstehenIntent()
        case "schlummern": return SchlummernIntent()
        case "aufgabe": return AufgabeIntent()
        default: return nil
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let r = engineBridge.pluginRegistry.registrar(forPlugin: "GroundsetHealth") {
      GroundsetHealth.shared.register(messenger: r.messenger())
    }
    if let r = engineBridge.pluginRegistry.registrar(forPlugin: "GroundsetSchritte") {
      GroundsetSchritte.shared.register(messenger: r.messenger())
    }
    if let r = engineBridge.pluginRegistry.registrar(forPlugin: "GroundsetKalender") {
      GroundsetKalender.shared.register(messenger: r.messenger())
    }
  }
}

// MARK: - Groundset alarm

/// Fixed ids, the same as in lib/schlaf/echter_wecker.dart.
enum WeckerIds {
  static let wecker = UUID(uuidString: "0E1D5A3C-6B2F-4C7E-9A11-6F3B2D8C4A01")!
  static let schlummern = UUID(uuidString: "0E1D5A3C-6B2F-4C7E-9A11-6F3B2D8C4A02")!
  static let nachklingeln = UUID(uuidString: "0E1D5A3C-6B2F-4C7E-9A11-6F3B2D8C4A03")!
}

/// Tells the app to show the task first. shared_preferences reads the
/// standard UserDefaults with the prefix "flutter.".
private func aufgabeMerken() {
  UserDefaults.standard.set(
    ISO8601DateFormatter().string(from: Date()), forKey: "flutter.wecker_aufgabe_seit")
}

@available(iOS 26.0, *)
private let weckerGold = Color(red: 0.88, green: 0.75, blue: 0.49)

/// One ringing without a snooze button, [in] seconds from now.
@available(iOS 26.0, *)
private func klingeln(id: UUID, in sekunden: TimeInterval, titel: String, knopf: String) async {
  let alert = AlarmPresentation.Alert(
    title: LocalizedStringResource(stringLiteral: titel),
    stopButton: AlarmButton(
      text: LocalizedStringResource(stringLiteral: knopf), textColor: .black,
      systemImageName: "sun.max.fill"),
    secondaryButton: nil, secondaryButtonBehavior: nil)
  let attributes = AlarmAttributes<AlarmKitMetadata>(
    presentation: AlarmPresentation(alert: alert),
    metadata: AlarmKitMetadata(kind: "wecker"),
    tintColor: weckerGold)
  let config = AlarmManager.AlarmConfiguration<AlarmKitMetadata>(
    countdownDuration: nil,
    schedule: .fixed(Date().addingTimeInterval(sekunden)),
    attributes: attributes,
    stopIntent: AufgabeIntent(),
    secondaryIntent: nil,
    sound: .default)
  _ = try? await AlarmManager.shared.schedule(id: id, configuration: config)
}

/// "Aufstehen": no second snooze ringing, the app opens with the task, and
/// if the task is not done within 3 minutes the alarm rings once more.
@available(iOS 26.0, *)
struct AufstehenIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Aufstehen"
  static var openAppWhenRun: Bool = true

  func perform() async throws -> some IntentResult {
    try? AlarmManager.shared.cancel(id: WeckerIds.schlummern)
    aufgabeMerken()
    await klingeln(
      id: WeckerIds.nachklingeln, in: 180, titel: "Deine Aufgabe wartet",
      knopf: "Aufgabe machen")
    return .result()
  }
}

/// "5 Min": rings once more in 5 minutes, then only with "Aufstehen".
@available(iOS 26.0, *)
struct SchlummernIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "5 Minuten"

  func perform() async throws -> some IntentResult {
    await klingeln(
      id: WeckerIds.schlummern, in: 300, titel: "Guten Morgen", knopf: "Aufstehen")
    return .result()
  }
}

/// The button of the second ringing: opens the task, no further ringing.
@available(iOS 26.0, *)
struct AufgabeIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Aufgabe machen"
  static var openAppWhenRun: Bool = true

  func perform() async throws -> some IntentResult {
    aufgabeMerken()
    return .result()
  }
}

// MARK: - Apple Health (vault Umsetzung/Apple Health.md)

/// Reads Apple Health for lib/health/health_dienst.dart. Only reads, never
/// writes. Times go to Dart as milliseconds since 1970.
final class GroundsetHealth {
  static let shared = GroundsetHealth()
  private let store = HKHealthStore()
  private var channel: FlutterMethodChannel?

  func register(messenger: FlutterBinaryMessenger) {
    let c = FlutterMethodChannel(name: "groundset/health", binaryMessenger: messenger)
    c.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "verbinden":
        self.verbinden(result)
      case "lesen":
        let args = call.arguments as? [String: Any] ?? [:]
        let tag = GroundsetHealth.datum(args["tag"]) ?? Calendar.current.startOfDay(for: Date())
        let jetzt = GroundsetHealth.datum(args["jetzt"]) ?? Date()
        self.lesen(tag: tag, jetzt: jetzt, result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    channel = c
  }

  private static func datum(_ v: Any?) -> Date? {
    guard let n = v as? NSNumber else { return nil }
    return Date(timeIntervalSince1970: n.doubleValue / 1000)
  }

  private static func ms(_ d: Date) -> Double { d.timeIntervalSince1970 * 1000 }

  private var leseTypen: Set<HKObjectType> {
    var t = Set<HKObjectType>()
    if let x = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { t.insert(x) }
    let mengen: [HKQuantityTypeIdentifier] = [
      .restingHeartRate, .heartRateVariabilitySDNN, .stepCount, .bodyMass,
    ]
    for id in mengen {
      if let x = HKObjectType.quantityType(forIdentifier: id) { t.insert(x) }
    }
    if #available(iOS 17.0, *) {
      if let x = HKObjectType.quantityType(forIdentifier: .timeInDaylight) { t.insert(x) }
    }
    t.insert(HKObjectType.workoutType())
    return t
  }

  private func verbinden(_ result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }
    store.requestAuthorization(toShare: nil, read: leseTypen) { ok, _ in
      DispatchQueue.main.async { result(ok) }
    }
  }

  private func lesen(tag: Date, jetzt: Date, _ result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(nil)
      return
    }
    let tagFrueh = tag
    let gruppe = DispatchGroup()
    let schutz = DispatchQueue(label: "groundset.health")
    var aus: [String: Any] = [:]
    func setze(_ k: String, _ v: Any) { schutz.sync { aus[k] = v } }

    // The night: from 18:00 the evening before to 14:00 today.
    if let typ = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
      gruppe.enter()
      let p = HKQuery.predicateForSamples(
        withStart: tagFrueh.addingTimeInterval(-6 * 3600),
        end: tagFrueh.addingTimeInterval(14 * 3600))
      let q = HKSampleQuery(
        sampleType: typ, predicate: p, limit: HKObjectQueryNoLimit,
        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
      ) { _, samples, _ in
        var liste: [[String: Any]] = []
        for s in (samples as? [HKCategorySample]) ?? [] {
          // 0 in bed, 1 asleep, 2 awake, 3 core, 4 deep, 5 REM.
          let art: String
          switch s.value {
          case 1: art = "schlaf"
          case 2: art = "wach"
          case 3: art = "kern"
          case 4: art = "tief"
          case 5: art = "rem"
          default: continue
          }
          liste.append([
            "von": GroundsetHealth.ms(s.startDate), "bis": GroundsetHealth.ms(s.endDate),
            "art": art,
          ])
        }
        setze("schlaf", liste)
        gruppe.leave()
      }
      store.execute(q)
    }

    // Latest value and the 30-day average.
    func zuletztUndSchnitt(_ id: HKQuantityTypeIdentifier, _ einheit: HKUnit, _ name: String) {
      guard let typ = HKObjectType.quantityType(forIdentifier: id) else { return }
      gruppe.enter()
      let p = HKQuery.predicateForSamples(
        withStart: tagFrueh.addingTimeInterval(-36 * 3600), end: jetzt)
      let q = HKSampleQuery(
        sampleType: typ, predicate: p, limit: 1,
        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
      ) { _, samples, _ in
        if let s = (samples as? [HKQuantitySample])?.first {
          setze(name, s.quantity.doubleValue(for: einheit))
        }
        gruppe.leave()
      }
      store.execute(q)
      gruppe.enter()
      let p30 = HKQuery.predicateForSamples(
        withStart: tagFrueh.addingTimeInterval(-30 * 86400), end: tagFrueh)
      let s30 = HKStatisticsQuery(
        quantityType: typ, quantitySamplePredicate: p30, options: .discreteAverage
      ) { _, stat, _ in
        if let v = stat?.averageQuantity()?.doubleValue(for: einheit) {
          setze(name + "_schnitt", v)
        }
        gruppe.leave()
      }
      store.execute(s30)
    }
    zuletztUndSchnitt(
      .restingHeartRate, HKUnit.count().unitDivided(by: .minute()), "ruhepuls")
    zuletztUndSchnitt(.heartRateVariabilitySDNN, .secondUnit(with: .milli), "hrv")

    // Sums for today.
    func summeHeute(_ id: HKQuantityTypeIdentifier, _ einheit: HKUnit, _ name: String) {
      guard let typ = HKObjectType.quantityType(forIdentifier: id) else { return }
      gruppe.enter()
      let p = HKQuery.predicateForSamples(withStart: tagFrueh, end: jetzt)
      let q = HKStatisticsQuery(
        quantityType: typ, quantitySamplePredicate: p, options: .cumulativeSum
      ) { _, stat, _ in
        if let v = stat?.sumQuantity()?.doubleValue(for: einheit) { setze(name, v) }
        gruppe.leave()
      }
      store.execute(q)
    }
    summeHeute(.stepCount, .count(), "schritte")
    if #available(iOS 17.0, *) {
      summeHeute(.timeInDaylight, .minute(), "tageslicht")
    }

    // The weight from the scale, the last 2 days.
    if let typ = HKObjectType.quantityType(forIdentifier: .bodyMass) {
      gruppe.enter()
      let p = HKQuery.predicateForSamples(
        withStart: tagFrueh.addingTimeInterval(-86400), end: jetzt)
      let q = HKSampleQuery(
        sampleType: typ, predicate: p, limit: 1,
        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
      ) { _, samples, _ in
        if let s = (samples as? [HKQuantitySample])?.first {
          setze(
            "gewicht",
            [
              "kg": s.quantity.doubleValue(for: .gramUnit(with: .kilo)),
              "zeit": GroundsetHealth.ms(s.startDate),
            ])
        }
        gruppe.leave()
      }
      store.execute(q)
    }

    // Workouts from today.
    gruppe.enter()
    let pw = HKQuery.predicateForSamples(withStart: tagFrueh, end: jetzt)
    let qw = HKSampleQuery(
      sampleType: HKObjectType.workoutType(), predicate: pw, limit: 10,
      sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
    ) { _, samples, _ in
      let liste: [[String: Any]] = ((samples as? [HKWorkout]) ?? []).map { w in
        [
          "art": GroundsetHealth.name(w.workoutActivityType),
          "start": GroundsetHealth.ms(w.startDate),
          "minuten": Int((w.duration / 60).rounded()),
        ]
      }
      setze("trainings", liste)
      gruppe.leave()
    }
    store.execute(qw)

    gruppe.notify(queue: .main) {
      result(schutz.sync { aus })
    }
  }

  private static func name(_ t: HKWorkoutActivityType) -> String {
    switch t {
    case .running: return "Laufen"
    case .walking: return "Gehen"
    case .hiking: return "Wandern"
    case .cycling: return "Radfahren"
    case .swimming: return "Schwimmen"
    case .rowing: return "Rudern"
    case .traditionalStrengthTraining, .functionalStrengthTraining: return "Krafttraining"
    case .highIntensityIntervalTraining: return "HIIT"
    case .crossTraining: return "Cross-Training"
    case .yoga: return "Yoga"
    case .pilates: return "Pilates"
    case .soccer: return "Fußball"
    case .basketball: return "Basketball"
    case .tennis: return "Tennis"
    case .boxing: return "Boxen"
    case .martialArts: return "Kampfsport"
    case .climbing: return "Klettern"
    case .elliptical: return "Crosstrainer"
    case .stairClimbing: return "Treppensteigen"
    case .coreTraining: return "Core-Training"
    case .mixedCardio: return "Cardio"
    default: return "Training"
    }
  }
}

// MARK: - Steps for the alarm task (vault Umsetzung/Echter Wecker)

/// Counts steps with CMPedometer for lib/schlaf/schritt_zaehler.dart while
/// the task is open. Sends only the number of steps since the start.
final class GroundsetSchritte: NSObject, FlutterStreamHandler {
  static let shared = GroundsetSchritte()
  private let pedometer = CMPedometer()
  private var channel: FlutterEventChannel?

  func register(messenger: FlutterBinaryMessenger) {
    let c = FlutterEventChannel(name: "groundset/schritte", binaryMessenger: messenger)
    c.setStreamHandler(self)
    channel = c
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    guard CMPedometer.isStepCountingAvailable() else {
      return FlutterError(code: "kein_zaehler", message: "Kein Schrittzähler", details: nil)
    }
    if CMPedometer.authorizationStatus() == .denied
      || CMPedometer.authorizationStatus() == .restricted
    {
      return FlutterError(code: "nicht_erlaubt", message: "Nicht erlaubt", details: nil)
    }
    events(0)
    pedometer.startUpdates(from: Date()) { data, error in
      DispatchQueue.main.async {
        if let error = error {
          events(FlutterError(code: "fehler", message: error.localizedDescription, details: nil))
          return
        }
        events(data?.numberOfSteps.intValue ?? 0)
      }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    pedometer.stopUpdates()
    return nil
  }
}

// MARK: - Groundset Kalender

/// The iPhone calendar (vault Umsetzung/Kalender verbinden): read the
/// appointments, add new ones. Same names as lib/kalender/kalender_dienst.dart.
final class GroundsetKalender {
  static let shared = GroundsetKalender()
  private let store = EKEventStore()
  private var channel: FlutterMethodChannel?

  func register(messenger: FlutterBinaryMessenger) {
    let c = FlutterMethodChannel(name: "groundset/kalender", binaryMessenger: messenger)
    c.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "verbinden":
        self.verbinden(result)
      case "kalender":
        result(self.erlaubt ? self.kalender() : [])
      case "termine":
        guard self.erlaubt,
          let von = GroundsetKalender.datum(args["von"]),
          let bis = GroundsetKalender.datum(args["bis"])
        else {
          result([])
          return
        }
        let aus = Set(args["aus"] as? [String] ?? [])
        result(self.termine(von: von, bis: bis, aus: aus))
      case "anlegen":
        result(self.anlegen(args))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    channel = c
  }

  private static func datum(_ v: Any?) -> Date? {
    guard let n = v as? NSNumber else { return nil }
    return Date(timeIntervalSince1970: n.doubleValue / 1000)
  }

  private static func ms(_ d: Date) -> Double { d.timeIntervalSince1970 * 1000 }

  private var erlaubt: Bool {
    let s = EKEventStore.authorizationStatus(for: .event)
    if #available(iOS 17.0, *) { return s == .fullAccess }
    return s == .authorized
  }

  private func verbinden(_ result: @escaping FlutterResult) {
    let fertig: (Bool, Error?) -> Void = { [weak self] ok, _ in
      DispatchQueue.main.async {
        if ok { self?.store.reset() }
        result(ok)
      }
    }
    if #available(iOS 17.0, *) {
      store.requestFullAccessToEvents(completion: fertig)
    } else {
      store.requestAccess(to: .event, completion: fertig)
    }
  }

  private static func farbe(_ c: CGColor) -> Int {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    UIColor(cgColor: c).getRed(&r, green: &g, blue: &b, alpha: &a)
    func k(_ x: CGFloat) -> Int { Int((max(0, min(1, x)) * 255).rounded()) }
    return (255 << 24) | (k(r) << 16) | (k(g) << 8) | k(b)
  }

  /// All calendars, the default for new appointments first.
  private func kalender() -> [[String: Any]] {
    let standard = store.defaultCalendarForNewEvents?.calendarIdentifier
    let alle = store.calendars(for: .event).sorted { a, b in
      if a.calendarIdentifier == standard { return true }
      if b.calendarIdentifier == standard { return false }
      return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
    }
    return alle.map {
      [
        "id": $0.calendarIdentifier,
        "name": $0.title,
        "farbe": GroundsetKalender.farbe($0.cgColor),
        "schreibbar": $0.allowsContentModifications,
      ]
    }
  }

  private func termine(von: Date, bis: Date, aus: Set<String>) -> [[String: Any]] {
    let kalender = store.calendars(for: .event).filter { !aus.contains($0.calendarIdentifier) }
    if kalender.isEmpty { return [] }
    let p = store.predicateForEvents(withStart: von, end: bis, calendars: kalender)
    return store.events(matching: p)
      .sorted { $0.startDate < $1.startDate }
      .map {
        [
          "start": GroundsetKalender.ms($0.startDate),
          "titel": $0.title ?? "",
          "ganztags": $0.isAllDay,
          "kalender": $0.calendar?.title ?? "Kalender",
        ]
      }
  }

  private func anlegen(_ args: [String: Any]) -> Bool {
    guard erlaubt, let start = GroundsetKalender.datum(args["start"]),
      let titel = args["titel"] as? String
    else { return false }
    let e = EKEvent(eventStore: store)
    e.title = titel
    e.startDate = start
    let ganztags = args["ganztags"] as? Bool ?? false
    e.isAllDay = ganztags
    e.endDate = start.addingTimeInterval(ganztags ? 0 : 3600)
    if let id = args["kalender"] as? String, let k = store.calendar(withIdentifier: id),
      k.allowsContentModifications
    {
      e.calendar = k
    } else {
      e.calendar = store.defaultCalendarForNewEvents
    }
    guard e.calendar != nil else { return false }
    do {
      try store.save(e, span: .thisEvent)
      return true
    } catch {
      return false
    }
  }
}
