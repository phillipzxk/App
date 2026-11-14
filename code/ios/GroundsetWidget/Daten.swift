import Foundation

// What the widgets show (vault Umsetzung/Widgets.md). The app writes one
// JSON text into the shared group (lib/startwidget/widget_daten.dart); the
// widgets work out by themselves what is next, so they stay right during
// the day without the app being opened.

let gruppe = "group.de.phillipzxk.coachApp"
let datenKey = "groundset_widget"
let offenKey = "groundset_fokus_offen"

struct Punkt: Codable {
  let t: Double
  let titel: String
  let ziel: String
  let erledigt: Bool

  var zeit: Date { Date(timeIntervalSince1970: t) }
}

struct FokusDaten: Codable {
  let text: String
  let start: String
  var geschafft: [String]
}

struct WidgetDaten: Codable {
  var tag: String
  var name: String
  var checkin: Bool
  var punkte: [Punkt]
  var fokus: FokusDaten?
  var coach: String
  var schnitt: Double?
  var trend: Double?
  var serie: Int
  var training: String?
  var trainingZeit: String?
  var bett: String?
}

enum Speicher {
  static var defaults: UserDefaults? { UserDefaults(suiteName: gruppe) }

  static func tagKey(_ d: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: d)
  }

  static func datum(_ key: String) -> Date? {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f.date(from: key)
  }

  static func laden() -> WidgetDaten? {
    guard let text = defaults?.string(forKey: datenKey),
      let data = text.data(using: .utf8)
    else { return nil }
    return try? JSONDecoder().decode(WidgetDaten.self, from: data)
  }

  static func speichern(_ d: WidgetDaten) {
    guard let data = try? JSONEncoder().encode(d),
      let text = String(data: data, encoding: .utf8)
    else { return }
    defaults?.set(text, forKey: datenKey)
  }

  /// "Heute geschafft" tapped in the widget: shown at once, and noted for
  /// the app, which takes it over the next time it opens.
  static func geschafftHeute() {
    let heute = tagKey(Date())
    if var d = laden(), var f = d.fokus {
      if !f.geschafft.contains(heute) { f.geschafft.append(heute) }
      d.fokus = f
      speichern(d)
    }
    var offen = (defaults?.string(forKey: offenKey) ?? "")
      .split(separator: ",").map(String.init)
    if !offen.contains(heute) { offen.append(heute) }
    defaults?.set(offen.joined(separator: ","), forKey: offenKey)
  }
}

/// The state of the day at one moment.
struct Lage {
  let jetzt: Date
  let daten: WidgetDaten?

  /// The data is from today.
  var aktuell: Bool {
    guard let d = daten else { return false }
    return d.tag == Speicher.tagKey(jetzt)
  }

  var punkte: [Punkt] { aktuell ? (daten?.punkte ?? []) : [] }

  /// The next thing that is still open.
  var naechster: Punkt? {
    punkte.first { !$0.erledigt && $0.zeit > jetzt }
  }

  var checkin: Bool { aktuell && (daten?.checkin ?? false) }

  /// Today's points plus the check-in.
  var gesamt: Int { punkte.count + 1 }

  var geschafft: Int {
    punkte.filter { $0.erledigt || $0.zeit <= jetzt }.count + (checkin ? 1 : 0)
  }

  var anteil: Double { gesamt == 0 ? 0 : Double(geschafft) / Double(gesamt) }

  // Fokus der Woche: 7 days from its start day.
  var fokus: FokusDaten? {
    guard let f = daten?.fokus, fokusTag(f) <= 7, fokusTag(f) >= 1 else { return nil }
    return f
  }

  func fokusTag(_ f: FokusDaten) -> Int {
    guard let s = Speicher.datum(f.start) else { return 99 }
    let cal = Calendar.current
    let a = cal.startOfDay(for: s)
    let b = cal.startOfDay(for: jetzt)
    return (cal.dateComponents([.day], from: a, to: b).day ?? 98) + 1
  }

  func striche(_ f: FokusDaten) -> [Bool] {
    guard let s = Speicher.datum(f.start) else { return Array(repeating: false, count: 7) }
    return (0..<7).map { i in
      let d = Calendar.current.date(byAdding: .day, value: i, to: s) ?? s
      return f.geschafft.contains(Speicher.tagKey(d))
    }
  }

  func heuteGeschafft(_ f: FokusDaten) -> Bool {
    f.geschafft.contains(Speicher.tagKey(jetzt))
  }

  /// The next mark a streak grows towards: 3, 7, 14, 30, then every 30.
  var serieMarke: Int {
    let n = daten?.serie ?? 0
    for m in [3, 7, 14, 30] where n < m { return m }
    return (n / 30 + 1) * 30
  }

  /// "Push 17:30 · Bett 22:40" for the line above the clock.
  var zeile: String {
    guard aktuell, let d = daten else { return "Groundset" }
    var teile: [String] = []
    if let t = d.training, let z = d.trainingZeit { teile.append("\(t) \(z)") }
    if let b = d.bett { teile.append("Bett \(b)") }
    return teile.isEmpty ? "Heute frei" : teile.joined(separator: " · ")
  }

  /// Up to [max] rows for "Heute dran": the check-in, then what comes
  /// next; when little is left, the last things of the day.
  func liste(_ max: Int) -> [(titel: String, wert: String, weg: Bool)] {
    var rows: [(titel: String, wert: String, weg: Bool)] = [
      (titel: "Check-in", wert: checkin ? "erledigt" : "offen", weg: checkin)
    ]
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    let alle = punkte
    let platz = max - 1
    var start = alle.firstIndex { !$0.erledigt && $0.zeit > jetzt } ?? alle.count
    start = Swift.max(0, Swift.min(start, alle.count - platz))
    for p in alle.dropFirst(start).prefix(platz) {
      rows.append(
        (titel: p.titel, wert: f.string(from: p.zeit), weg: p.erledigt || p.zeit <= jetzt))
    }
    return rows
  }
}

func uhrzeit(_ d: Date) -> String {
  let f = DateFormatter()
  f.dateFormat = "HH:mm"
  return f.string(from: d)
}
