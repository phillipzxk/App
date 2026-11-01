import AlarmKit
import AppIntents
import Flutter
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
