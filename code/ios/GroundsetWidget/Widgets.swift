import SwiftUI
import UIKit
import WidgetKit

// The five widgets confirmed 2026-11-15 (vault Umsetzung/Widgets.md); they
// replace the first six: "Dein Baum", "Jetzt dran" with praise, "Dafür",
// "Dein Coach spricht" (wide) and "Deine Woche".
// Look as in the app: espresso, glass, gold as the only colour.

// MARK: - Look

enum Farbe {
  static let gold = Color(red: 0.90, green: 0.79, blue: 0.56)
  static let goldHell = Color(red: 0.95, green: 0.89, blue: 0.74)
  static let goldTief = Color(red: 0.85, green: 0.72, blue: 0.47)
  static let tinte = Color(red: 0.165, green: 0.122, blue: 0.078)
  static let creme = Color(red: 0.965, green: 0.925, blue: 0.86)
  static let braun1 = Color(red: 0.227, green: 0.18, blue: 0.133)
  static let braun2 = Color(red: 0.149, green: 0.114, blue: 0.082)
}

func sora(_ size: CGFloat, fett: Bool = true) -> Font {
  .custom(fett ? "Sora-Bold" : "Sora-SemiBold", size: size)
}

func figtree(_ size: CGFloat, _ gewicht: Int = 400) -> Font {
  switch gewicht {
  case 600: return .custom("Figtree-SemiBold", size: size)
  case 500: return .custom("Figtree-Medium", size: size)
  default: return .custom("Figtree-Regular", size: size)
  }
}

func oeffnen(_ z: String) -> URL {
  URL(string: "groundset://oeffnen?ziel=\(z)&homeWidget=1")!
}

struct HellGrund: View {
  var body: some View {
    ZStack(alignment: .topTrailing) {
      LinearGradient(
        colors: [Farbe.goldHell, Farbe.goldTief],
        startPoint: .topLeading, endPoint: .bottomTrailing)
      // The concentric rings of the light tile in the app.
      ZStack {
        Circle().stroke(Farbe.tinte.opacity(0.10), lineWidth: 1).frame(width: 110, height: 110)
        Circle().stroke(Farbe.tinte.opacity(0.07), lineWidth: 1).frame(width: 150, height: 150)
        Circle().stroke(Farbe.tinte.opacity(0.05), lineWidth: 1).frame(width: 190, height: 190)
      }
      .offset(x: 70, y: -70)
    }
  }
}

struct DunkelGrund: View {
  var body: some View {
    LinearGradient(
      colors: [Farbe.braun1, Farbe.braun2],
      startPoint: .topLeading, endPoint: .bottomTrailing)
  }
}

struct Kicker: View {
  let text: String
  var farbe: Color = Farbe.gold

  var body: some View {
    Text(text.uppercased())
      .font(figtree(9, 600))
      .kerning(1.3)
      .foregroundStyle(farbe)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
  }
}

struct Ring: View {
  let anteil: Double
  let text: String
  var hell = false
  var groesse: CGFloat = 42

  var body: some View {
    ZStack {
      Circle()
        .stroke(
          hell ? Farbe.tinte.opacity(0.16) : Farbe.creme.opacity(0.14),
          lineWidth: 4)
      Circle()
        .trim(from: 0, to: max(0.001, min(1, anteil)))
        .stroke(
          hell ? Farbe.tinte : Farbe.gold,
          style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
      Text(text)
        .font(sora(groesse * 0.27))
        .foregroundStyle(hell ? Farbe.tinte : Farbe.gold)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
        .padding(6)
    }
    .frame(width: groesse, height: groesse)
  }
}

struct Pille: View {
  let text: String
  var hell = false
  var symbol: String? = nil

  var body: some View {
    HStack(spacing: 4) {
      if let s = symbol {
        Image(systemName: s).font(.system(size: 9, weight: .bold))
      }
      Text(text).font(figtree(11, 600)).lineLimit(1)
    }
    .foregroundStyle(hell ? Farbe.tinte : Farbe.goldHell)
    .padding(.horizontal, 11)
    .padding(.vertical, 6)
    .background(
      Capsule().fill(
        hell
          ? AnyShapeStyle(
            LinearGradient(
              colors: [Farbe.goldHell, Farbe.goldTief],
              startPoint: .topLeading, endPoint: .bottomTrailing))
          : AnyShapeStyle(Farbe.tinte)))
  }
}

// MARK: - Timeline

struct Eintrag: TimelineEntry {
  let date: Date
  let lage: Lage
}

struct Quelle: TimelineProvider {
  func placeholder(in context: Context) -> Eintrag {
    Eintrag(date: Date(), lage: Lage(jetzt: Date(), daten: nil))
  }

  func getSnapshot(in context: Context, completion: @escaping (Eintrag) -> Void) {
    let jetzt = Date()
    completion(Eintrag(date: jetzt, lage: Lage(jetzt: jetzt, daten: Speicher.laden())))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Eintrag>) -> Void) {
    let jetzt = Date()
    let daten = Speicher.laden()
    let cal = Calendar.current
    let heute = cal.startOfDay(for: jetzt)
    let morgen = cal.date(byAdding: .day, value: 1, to: heute) ?? jetzt.addingTimeInterval(86400)
    // A new picture whenever a point of the day is reached, when the
    // praise ends, when the evening starts, and at midnight.
    var zeiten: [Date] = [jetzt]
    for p in daten?.punkte ?? [] where p.zeit > jetzt && p.zeit < morgen {
      zeiten.append(p.zeit.addingTimeInterval(1))
    }
    if let l = daten?.lob {
      let ende = Date(timeIntervalSince1970: l.bis)
      if ende > jetzt && ende < morgen { zeiten.append(ende.addingTimeInterval(1)) }
    }
    if let abend = cal.date(byAdding: .hour, value: 17, to: heute), abend > jetzt {
      zeiten.append(abend)
    }
    zeiten.append(morgen.addingTimeInterval(1))
    let eintraege = zeiten.sorted().prefix(40).map {
      Eintrag(date: $0, lage: Lage(jetzt: $0, daten: daten))
    }
    completion(Timeline(entries: Array(eintraege), policy: .atEnd))
  }
}

// MARK: - 1: Dein Baum

/// The sprout from the app: a leaf for every day in a row (up to eight are
/// drawn), a root for every ticked day of the week's focus.
struct Baum: View {
  let blaetter: Int
  let wurzeln: Int
  let farbe: Color

  var body: some View {
    Canvas { ctx, size in
      let w = size.width
      let h = size.height
      let boden = h * 0.60
      let mitte = w / 2
      let e = min(w, h) / 150
      ctx.stroke(
        Path { p in
          p.move(to: CGPoint(x: 0, y: boden))
          p.addLine(to: CGPoint(x: w, y: boden))
        }, with: .color(farbe.opacity(0.3)), lineWidth: 1)
      guard blaetter > 0 else {
        ctx.fill(
          Path(ellipseIn: CGRect(x: mitte - 4 * e, y: boden - 4 * e, width: 8 * e, height: 8 * e)),
          with: .color(farbe))
        return
      }
      let n = min(blaetter, 8)
      let abstand = 8.5 * e
      let hoehe = 16 * e + CGFloat(n) * abstand
      ctx.stroke(
        Path { p in
          p.move(to: CGPoint(x: mitte, y: boden))
          p.addLine(to: CGPoint(x: mitte, y: boden - hoehe))
        }, with: .color(farbe), style: StrokeStyle(lineWidth: 3 * e, lineCap: .round))
      for i in 0..<n {
        let s: CGFloat = i % 2 == 0 ? 1 : -1
        let y = boden - 8 * e - CGFloat(i) * abstand
        let gr = (20 - CGFloat(i)) * e
        var blatt = Path()
        blatt.move(to: CGPoint(x: mitte, y: y))
        blatt.addQuadCurve(
          to: CGPoint(x: mitte + s * gr, y: y - gr * 0.9),
          control: CGPoint(x: mitte + s * gr * 0.95, y: y - gr * 0.1))
        blatt.addQuadCurve(
          to: CGPoint(x: mitte, y: y),
          control: CGPoint(x: mitte + s * gr * 0.1, y: y - gr * 0.85))
        ctx.fill(blatt, with: .color(farbe.opacity(1 - Double(i) * 0.05)))
      }
      for i in 0..<min(max(wurzeln, 1), 7) {
        let s: CGFloat = i % 2 == 0 ? 1 : -1
        let weit = (14 + CGFloat(i / 2) * 11) * e
        let tief = (20 + CGFloat(i / 2) * 6 + CGFloat(i % 2) * 4) * e
        var wurzel = Path()
        wurzel.move(to: CGPoint(x: mitte, y: boden + 1))
        wurzel.addQuadCurve(
          to: CGPoint(x: mitte + s * weit, y: boden + tief),
          control: CGPoint(x: mitte + s * weit * 0.35, y: boden + tief * 0.75))
        ctx.stroke(
          wurzel, with: .color(farbe.opacity(0.75)),
          style: StrokeStyle(lineWidth: max(1, (2.4 - CGFloat(i) * 0.2) * e), lineCap: .round))
      }
    }
  }
}

struct BaumAnsicht: View {
  let lage: Lage

  var body: some View {
    let n = lage.serie
    let gold = lage.markeErreicht
    let tinte = gold ? Farbe.tinte : Farbe.creme
    let oben = n == 0 ? "Dein Baum" : n == 1 ? "Tag 1" : "\(n) Tage am Stück"
    let unten: String = {
      if n == 0 { return "Startet mit deinem nächsten Check-in" }
      if gold { return "Marke \(n) erreicht. Stark\(lage.name.isEmpty ? "" : ", \(lage.name)")." }
      if n >= 3, n >= (lage.daten?.rekord ?? 0) { return "Dein Rekord" }
      return "Noch \(lage.marke - n) bis zur Marke \(lage.marke)"
    }()
    ZStack {
      Baum(
        blaetter: n, wurzeln: lage.daten?.wurzeln ?? 0,
        farbe: gold ? Farbe.tinte : Farbe.gold
      )
      .padding(.vertical, 14)
      VStack(alignment: .leading) {
        Kicker(text: oben, farbe: gold ? Farbe.tinte.opacity(0.75) : Farbe.gold)
        Spacer()
        Text(unten)
          .font(figtree(10.5, 500))
          .foregroundStyle(tinte.opacity(0.8))
          .lineLimit(2)
          .minimumScaleFactor(0.8)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .widgetURL(oeffnen("heute"))
    .containerBackground(for: .widget) {
      if gold { HellGrund() } else { DunkelGrund() }
    }
  }
}

struct GroundsetBaum: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "GroundsetBaum", provider: Quelle()) { e in
      BaumAnsicht(lage: e.lage)
    }
    .configurationDisplayName("Dein Baum")
    .description("Wächst mit jedem Tag am Stück. Jeder geschaffte Fokus-Tag gibt eine Wurzel.")
    .supportedFamilies([.systemSmall])
  }
}

// MARK: - 2: Jetzt dran, with praise

struct JetztAnsicht: View {
  let lage: Lage

  var body: some View {
    if lage.komplett {
      VStack(spacing: 4) {
        Image(systemName: "leaf.fill")
          .font(.system(size: 30))
          .foregroundStyle(Farbe.tinte)
        Text("Tag komplett")
          .font(sora(17))
          .foregroundStyle(Farbe.tinte)
        Text("\(lage.geschafft) von \(lage.gesamt). Dein Fundament ist heute gewachsen.")
          .font(figtree(11, 500))
          .foregroundStyle(Farbe.tinte.opacity(0.75))
          .multilineTextAlignment(.center)
          .lineLimit(3)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .widgetURL(oeffnen("tag"))
      .containerBackground(for: .widget) {
        RadialGradient(
          colors: [Color(red: 1, green: 0.945, blue: 0.81), Farbe.goldTief],
          center: .top, startRadius: 0, endRadius: 190)
      }
    } else {
      offen
    }
  }

  var offen: some View {
    let lob = lage.lob
    let n = lage.naechster
    let rest = lage.gesamt - lage.geschafft
    let kicker = lob != nil ? "Geschafft" : "Jetzt dran"
    let titel: String = {
      if let l = lob { return "\(l) ist im Kasten" }
      if !lage.aktuell { return "Dein Tag" }
      if !lage.checkin { return "Check-in" }
      return n?.titel ?? "Alles geschafft"
    }()
    let unter: String = {
      if lob != nil {
        let wer = lage.name.isEmpty ? "" : ", \(lage.name)"
        return rest > 0 ? "Noch \(rest) heute. Weiter so\(wer)." : "Stark\(wer)."
      }
      if !lage.aktuell { return "Öffne Groundset für heute." }
      if !lage.checkin { return "30 Sekunden für deinen Coach." }
      if let p = n { return "um \(uhrzeit(p.zeit))" }
      return "Für heute ist nichts mehr offen."
    }()
    let knopf: String = {
      if lob != nil { return "Was kommt" }
      if !lage.aktuell { return "Öffnen" }
      if !lage.checkin || n?.ziel == "training" { return "Starten" }
      return "Öffnen"
    }()
    let wohin: String = {
      if lob != nil { return "tag" }
      if !lage.aktuell || !lage.checkin { return "heute" }
      return n?.ziel ?? "tag"
    }()
    return VStack(alignment: .leading, spacing: 2) {
      Kicker(text: kicker, farbe: Farbe.tinte.opacity(0.7))
      Text(titel)
        .font(sora(17))
        .foregroundStyle(Farbe.tinte)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
      Text(unter)
        .font(figtree(11.5, 500))
        .foregroundStyle(Farbe.tinte.opacity(0.75))
        .lineLimit(2)
      if lob == nil, lage.aktuell, lage.checkin, let p = n {
        (Text("in ") + Text(p.zeit, style: .relative))
          .font(figtree(11))
          .foregroundStyle(Farbe.tinte.opacity(0.7))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }
      Spacer(minLength: 2)
      HStack(alignment: .bottom) {
        Pille(text: knopf)
        Spacer(minLength: 4)
        Ring(
          anteil: lage.aktuell ? lage.anteil : 0,
          text: lage.aktuell ? "\(lage.geschafft)/\(lage.gesamt)" : "–",
          hell: true)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(oeffnen(wohin))
    .containerBackground(for: .widget) { HellGrund() }
  }
}

struct GroundsetJetzt: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "GroundsetJetzt", provider: Quelle()) { e in
      JetztAnsicht(lage: e.lage)
    }
    .configurationDisplayName("Jetzt dran")
    .description("Das Nächste aus deinem Tag. Lobt dich, wenn etwas geschafft ist.")
    .supportedFamilies([.systemSmall])
  }
}

// MARK: - 3: Dafür

struct DafuerAnsicht: View {
  let lage: Lage

  var body: some View {
    let ziel = lage.daten?.ziel ?? ""
    let grund = lage.daten?.grund ?? ""
    // Goal and reason take turns from day to day.
    let tag = Calendar.current.ordinality(of: .day, in: .year, for: lage.jetzt) ?? 0
    let zeigeGrund = !grund.isEmpty && (ziel.isEmpty || tag % 2 == 1)
    let satz = zeigeGrund ? grund : ziel
    let zahltEin: String = {
      if lage.aktuell, let p = lage.naechster { return "\(p.titel) um \(uhrzeit(p.zeit))" }
      if let f = lage.daten?.fokus, lage.fokusTag != nil { return f.text }
      return lage.checkin ? "Dein Abend und dein Schlaf" : "Dein Check-in"
    }()
    VStack(alignment: .leading, spacing: 5) {
      Kicker(text: zeigeGrund ? "Darum jetzt" : "Dafür")
      if satz.isEmpty {
        Text("Dein Ziel fehlt noch")
          .font(sora(14))
          .foregroundStyle(Farbe.creme)
        Text("Trag es im Fragebogen ein, dann steht es hier.")
          .font(figtree(11))
          .foregroundStyle(Farbe.creme.opacity(0.7))
      } else {
        Text("„\(satz)“")
          .font(sora(14, fett: false))
          .foregroundStyle(Farbe.creme)
          .lineLimit(4)
          .minimumScaleFactor(0.7)
      }
      Spacer(minLength: 2)
      Text("Heute zahlt ein:")
        .font(figtree(10.5))
        .foregroundStyle(Farbe.creme.opacity(0.7))
      Text(zahltEin)
        .font(figtree(11.5, 600))
        .foregroundStyle(Farbe.gold)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(oeffnen("mindset"))
    .containerBackground(for: .widget) { DunkelGrund() }
  }
}

struct GroundsetDafuer: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "GroundsetDafuer", provider: Quelle()) { e in
      DafuerAnsicht(lage: e.lage)
    }
    .configurationDisplayName("Dafür")
    .description("Dein Ziel und dein Grund in deinen eigenen Worten.")
    .supportedFamilies([.systemSmall])
  }
}

// MARK: - 4: Dein Coach spricht

struct CoachAnsicht: View {
  let lage: Lage

  var body: some View {
    let abend = lage.abend && lage.aktuell && lage.checkin
    let satz: String = {
      if abend {
        let stand = "\(lage.geschafft) von \(lage.gesamt) geschafft."
        if let v = lage.daten?.abend { return "\(stand) \(v)" }
        return lage.komplett ? "\(stand) Heute hast du alles durchgezogen." : stand
      }
      if lage.aktuell, let c = lage.daten?.coach, !c.isEmpty { return c }
      let wer = lage.name.isEmpty ? "" : "\(lage.name), "
      return lage.checkin
        ? "\(wer)ich melde mich gleich bei dir."
        : "\(wer)mach deinen Check-in. Dann sage ich dir, worauf es heute ankommt."
    }()
    let unten: String = {
      if abend {
        if let p = lage.naechster { return "Nur noch: \(p.titel) \(uhrzeit(p.zeit))" }
        return "Für heute ist nichts mehr offen."
      }
      if let t = lage.fokusTag { return "Fokus: Tag \(t) von 7" }
      return "Noch kein Fokus gewählt"
    }()
    let knopf = abend ? "Abend starten" : lage.checkin ? "Öffnen" : "Check-in"
    VStack(alignment: .leading, spacing: 8) {
      Kicker(text: abend ? "Dein Coach · Abend" : "Dein Coach · Morgen")
      HStack(alignment: .center, spacing: 12) {
        Image(uiImage: UIImage(named: "coach.jpg") ?? UIImage())
          .resizable()
          .scaledToFill()
          .frame(width: 46, height: 46)
          .clipShape(Circle())
          .overlay(Circle().stroke(Farbe.gold, lineWidth: 2))
        Text(satz)
          .font(sora(14, fett: false))
          .foregroundStyle(Farbe.creme)
          .lineLimit(4)
          .minimumScaleFactor(0.7)
      }
      Spacer(minLength: 0)
      HStack(alignment: .bottom) {
        Text(unten)
          .font(figtree(11))
          .foregroundStyle(Farbe.creme.opacity(0.75))
          .lineLimit(1)
          .minimumScaleFactor(0.8)
        Spacer(minLength: 6)
        Pille(text: knopf, hell: true)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(oeffnen(abend ? "schlaf" : "heute"))
    .containerBackground(for: .widget) { DunkelGrund() }
  }
}

struct GroundsetCoach: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "GroundsetCoach", provider: Quelle()) { e in
      CoachAnsicht(lage: e.lage)
    }
    .configurationDisplayName("Dein Coach spricht")
    .description("Morgens ein Auftrag, abends ein ehrliches Fazit.")
    .supportedFamilies([.systemMedium])
  }
}

// MARK: - 5: Deine Woche

struct WocheAnsicht: View {
  let lage: Lage

  /// The circles only count while the data is from this week.
  var kreise: [Bool] {
    guard let d = lage.daten, let t = Speicher.datum(d.tag), d.woche.count == 7 else {
      return Array(repeating: false, count: 7)
    }
    let cal = Calendar(identifier: .iso8601)
    return cal.isDate(t, equalTo: lage.jetzt, toGranularity: .weekOfYear)
      ? d.woche : Array(repeating: false, count: 7)
  }

  var body: some View {
    let k = kreise
    let n = k.filter { $0 }.count
    let davor = lage.daten?.letzteWoche ?? 0
    let heute = (Calendar(identifier: .iso8601).component(.weekday, from: lage.jetzt) + 5) % 7
    let vergleich: String = {
      if n > davor { return "Letzte Woche \(davor). Du bist vorn." }
      if n == davor { return n == 0 ? "Der erste Kreis wartet." : "Gleichstand mit letzter Woche." }
      return "Letzte Woche \(davor). Noch \(davor - n + 1) bis du vorn bist."
    }()
    VStack(alignment: .leading, spacing: 4) {
      Kicker(text: "Deine Woche")
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text("\(n)").font(sora(32)).foregroundStyle(Farbe.gold)
        Text("von 7").font(sora(13, fett: false)).foregroundStyle(Farbe.creme.opacity(0.6))
      }
      HStack(spacing: 4) {
        ForEach(0..<7, id: \.self) { i in
          ZStack {
            Circle().fill(k[i] ? Farbe.gold : Color.clear)
            Circle().stroke(
              k[i] || i == heute ? Farbe.gold : Farbe.creme.opacity(0.25), lineWidth: 1.5)
            Text(["M", "D", "M", "D", "F", "S", "S"][i])
              .font(figtree(8, 600))
              .foregroundStyle(
                k[i] ? Farbe.tinte : i == heute ? Farbe.gold : Farbe.creme.opacity(0.6))
          }
          .aspectRatio(1, contentMode: .fit)
        }
      }
      Spacer(minLength: 2)
      Text(vergleich)
        .font(figtree(10.5, 500))
        .foregroundStyle(Farbe.creme.opacity(0.8))
        .lineLimit(2)
        .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(oeffnen("heute"))
    .containerBackground(for: .widget) { DunkelGrund() }
  }
}

struct GroundsetWoche: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "GroundsetWoche", provider: Quelle()) { e in
      WocheAnsicht(lage: e.lage)
    }
    .configurationDisplayName("Deine Woche")
    .description("Sieben Kreise, die du voll haben willst. Du gegen deine letzte Woche.")
    .supportedFamilies([.systemSmall])
  }
}

// MARK: - Bundle

@main
struct GroundsetWidgets: WidgetBundle {
  var body: some Widget {
    GroundsetBaum()
    GroundsetJetzt()
    GroundsetDafuer()
    GroundsetCoach()
    GroundsetWoche()
  }
}
