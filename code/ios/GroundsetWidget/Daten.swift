import Foundation

// What the widgets show (vault Umsetzung/Widgets.md). The app writes one
// JSON text into the shared group (lib/startwidget/widget_daten.dart); the
// widgets work out by themselves what is next, so they stay right during
// the day without the app being opened.

let gruppe = "group.de.phillipzxk.coachApp"
let datenKey = "groundset_widget"

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
}

struct Lob: Codable {
  let titel: String
  let bis: Double
}

struct WidgetDaten: Codable {
  var tag: String
  var name: String
  var checkin: Bool
  var punkte: [Punkt]
  var serie: Int
  var rekord: Int
  var wurzeln: Int
  var lob: Lob?
  var ziel: String
  var grund: String
  var coach: String
  var fokus: FokusDaten?
  var abend: String?
  var woche: [Bool]
  var letzteWoche: Int
}

enum Speicher {
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
    guard let text = UserDefaults(suiteName: gruppe)?.string(forKey: datenKey),
      let data = text.data(using: .utf8)
    else { return nil }
    return try? JSONDecoder().decode(WidgetDaten.self, from: data)
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

  var name: String { daten?.name ?? "" }

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

  var anteil: Double { Double(geschafft) / Double(gesamt) }

  /// Everything of today is done.
  var komplett: Bool { aktuell && checkin && geschafft >= gesamt }

  /// What was just done, while its praise lasts.
  var lob: String? {
    guard aktuell, let l = daten?.lob,
      Date(timeIntervalSince1970: l.bis) > jetzt
    else { return nil }
    return l.titel
  }

  /// From 17:00 the coach looks back instead of ahead.
  var abend: Bool { Calendar.current.component(.hour, from: jetzt) >= 17 }

  // The streak only holds while the data is at most a day old.
  var serie: Int {
    guard let d = daten, let t = Speicher.datum(d.tag) else { return 0 }
    let tage =
      Calendar.current.dateComponents(
        [.day], from: Calendar.current.startOfDay(for: t),
        to: Calendar.current.startOfDay(for: jetzt)
      ).day ?? 9
    if tage <= 0 { return d.serie }
    // Yesterday's data: the streak still stands if yesterday was in it.
    return tage == 1 && d.checkin ? d.serie : 0
  }

  /// The next mark a streak grows towards: 3, 7, 14, 30, then every 30.
  var marke: Int {
    for m in [3, 7, 14, 30] where serie < m { return m }
    return (serie / 30 + 1) * 30
  }

  /// A mark was reached today.
  var markeErreicht: Bool {
    serie > 0 && ([3, 7, 14].contains(serie) || serie % 30 == 0)
  }

  /// "Tag 4 von 7" of the week's focus, nil without one.
  var fokusTag: Int? {
    guard let f = daten?.fokus, let s = Speicher.datum(f.start) else { return nil }
    let cal = Calendar.current
    let n =
      (cal.dateComponents(
        [.day], from: cal.startOfDay(for: s), to: cal.startOfDay(for: jetzt)
      ).day ?? 98) + 1
    return n >= 1 && n <= 7 ? n : nil
  }
}

func uhrzeit(_ d: Date) -> String {
  let f = DateFormatter()
  f.dateFormat = "HH:mm"
  return f.string(from: d)
}
