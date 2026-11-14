import AppIntents
import SwiftUI
import UIKit
import WidgetKit

// The six widgets confirmed 2026-11-14 (vault Umsetzung/Widgets.md):
// A "Jetzt dran" (small, light), B "Fokus der Woche" (small, dark, with
// "Heute geschafft"), C "Coach und Tag" (wide), and for the lock screen
// D the line above the clock, E two round fields, F one wide field.
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
    let morgen =
      cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: jetzt))
      ?? jetzt.addingTimeInterval(86400)
    // A new picture whenever a point of the day is reached, and at midnight.
    var zeiten: [Date] = [jetzt]
    for p in daten?.punkte ?? [] where p.zeit > jetzt && p.zeit < morgen {
      zeiten.append(p.zeit.addingTimeInterval(1))
    }
    zeiten.append(morgen.addingTimeInterval(1))
    let eintraege = zeiten.sorted().prefix(40).map {
      Eintrag(date: $0, lage: Lage(jetzt: $0, daten: daten))
    }
    completion(Timeline(entries: Array(eintraege), policy: .atEnd))
  }
}

// MARK: - A: Jetzt dran

struct JetztInhalt {
  let titel: String
  let unter: String
  let bis: Date?
  let knopf: String
  let ziel: String

  init(_ l: Lage) {
    if !l.aktuell {
      titel = "Dein Tag"
      unter = "Öffne Groundset für heute."
      bis = nil
      knopf = "Öffnen"
      ziel = "heute"
    } else if !l.checkin {
      titel = "Check-in"
      unter = "30 Sekunden für deinen Coach."
      bis = nil
      knopf = "Starten"
      ziel = "heute"
    } else if let p = l.naechster {
      titel = p.titel
      unter = "um \(uhrzeit(p.zeit))"
      bis = p.zeit
      knopf = p.ziel == "training" ? "Starten" : "Öffnen"
      ziel = p.ziel
    } else {
      titel = "Alles geschafft"
      unter = "Für heute ist nichts mehr offen."
      bis = nil
      knopf = "Ansehen"
      ziel = "tag"
    }
  }
}

struct JetztAnsicht: View {
  let lage: Lage

  var body: some View {
    let i = JetztInhalt(lage)
    VStack(alignment: .leading, spacing: 2) {
      Kicker(text: "Jetzt dran", farbe: Farbe.tinte.opacity(0.7))
      Text(i.titel)
        .font(sora(17))
        .foregroundStyle(Farbe.tinte)
        .lineLimit(2)
        .minimumScaleFactor(0.75)
      Text(i.unter)
        .font(figtree(11.5, 500))
        .foregroundStyle(Farbe.tinte.opacity(0.75))
        .lineLimit(2)
      if let b = i.bis {
        (Text("in ") + Text(b, style: .relative))
          .font(figtree(11))
          .foregroundStyle(Farbe.tinte.opacity(0.7))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }
      Spacer(minLength: 2)
      HStack(alignment: .bottom) {
        Pille(text: i.knopf)
        Spacer(minLength: 4)
        Ring(
          anteil: lage.aktuell ? lage.anteil : 0,
          text: lage.aktuell ? "\(lage.geschafft)/\(lage.gesamt)" : "–",
          hell: true)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(oeffnen(i.ziel))
    .containerBackground(for: .widget) { HellGrund() }
  }
}

struct GroundsetJetzt: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "GroundsetJetzt", provider: Quelle()) { e in
      JetztAnsicht(lage: e.lage)
    }
    .configurationDisplayName("Jetzt dran")
    .description("Das Nächste aus deinem Tag und wie viel von heute geschafft ist.")
    .supportedFamilies([.systemSmall])
  }
}

// MARK: - B: Fokus der Woche

struct FokusAnsicht: View {
  let lage: Lage

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      if let f = lage.fokus {
        let fertig = lage.heuteGeschafft(f)
        Kicker(text: "Fokus · Tag \(lage.fokusTag(f)) von 7")
        Text(f.text)
          .font(sora(14.5))
          .foregroundStyle(Farbe.creme)
          .lineLimit(3)
          .minimumScaleFactor(0.75)
        HStack(spacing: 4) {
          ForEach(Array(lage.striche(f).enumerated()), id: \.offset) { _, an in
            Capsule()
              .fill(an ? Farbe.gold : Farbe.creme.opacity(0.16))
              .frame(height: 4)
          }
        }
        .padding(.top, 3)
        Spacer(minLength: 2)
        HStack(alignment: .bottom) {
          if fertig {
            Pille(text: "Geschafft", symbol: "checkmark")
          } else {
            Button(intent: GeschafftIntent()) {
              Pille(text: "Heute geschafft", hell: true)
            }
            .buttonStyle(.plain)
          }
          Spacer(minLength: 2)
          Image(systemName: "leaf.fill")
            .font(.system(size: fertig ? 20 : 15))
            .foregroundStyle(Farbe.gold.opacity(fertig ? 1 : 0.6))
        }
      } else {
        Kicker(text: "Fokus der Woche")
        Text("Kein Fokus gewählt")
          .font(sora(14.5))
          .foregroundStyle(Farbe.creme)
        Text("Wähl ihn in der App. Dann hakst du ihn hier ab.")
          .font(figtree(11))
          .foregroundStyle(Farbe.creme.opacity(0.7))
        Spacer(minLength: 2)
        Pille(text: "Öffnen", hell: true)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(oeffnen("fokus"))
    .containerBackground(for: .widget) { DunkelGrund() }
  }
}

struct GroundsetFokus: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "GroundsetFokus", provider: Quelle()) { e in
      FokusAnsicht(lage: e.lage)
    }
    .configurationDisplayName("Fokus der Woche")
    .description("Dein Fokus mit sieben Strichen. „Heute geschafft“ geht direkt hier.")
    .supportedFamilies([.systemSmall])
  }
}

// MARK: - C: Coach und Tag

struct TagAnsicht: View {
  let lage: Lage

  var coach: String {
    guard lage.aktuell, let c = lage.daten?.coach, !c.isEmpty else {
      return lage.checkin
        ? "Dein Coach meldet sich gleich."
        : "Mach deinen Check-in, dann sage ich dir, worauf es heute ankommt."
    }
    return c
  }

  var schnitt: String {
    guard let s = lage.daten?.schnitt else { return "–" }
    return String(format: "%.1f", s).replacingOccurrences(of: ".", with: ",")
  }

  var trend: String? {
    guard lage.aktuell, let t = lage.daten?.trend else { return nil }
    let r = (t * 10).rounded() / 10
    if r == 0 { return "wie gestern" }
    let z = String(format: "%.1f", abs(r)).replacingOccurrences(of: ".", with: ",")
    return (r > 0 ? "+" : "−") + z
  }

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      VStack(alignment: .leading, spacing: 6) {
        Kicker(text: "Dein Coach")
        HStack(alignment: .top, spacing: 7) {
          Image(uiImage: UIImage(named: "coach.jpg") ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(width: 26, height: 26)
            .clipShape(Circle())
            .overlay(Circle().stroke(Farbe.gold, lineWidth: 1.5))
          Text(coach)
            .font(figtree(11.5))
            .foregroundStyle(Farbe.creme.opacity(0.95))
            .lineLimit(4)
            .minimumScaleFactor(0.85)
        }
        Spacer(minLength: 2)
        HStack(spacing: 8) {
          Ring(anteil: (lage.daten?.schnitt ?? 0) / 10, text: schnitt, groesse: 38)
          VStack(alignment: .leading, spacing: 0) {
            Text("Dein Schnitt")
              .font(figtree(10.5, 500))
              .foregroundStyle(Farbe.creme.opacity(0.8))
            if let t = trend {
              Text(t).font(figtree(10.5)).foregroundStyle(Farbe.gold)
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      VStack(alignment: .leading, spacing: 6) {
        Kicker(text: "Heute dran")
        if lage.aktuell {
          ForEach(Array(lage.liste(5).enumerated()), id: \.offset) { _, r in
            HStack(spacing: 6) {
              Text(r.titel)
                .font(figtree(11.5))
                .strikethrough(r.weg)
                .foregroundStyle(Farbe.creme.opacity(r.weg ? 0.45 : 0.95))
                .lineLimit(1)
              Spacer(minLength: 2)
              Text(r.wert)
                .font(figtree(11.5, 600))
                .foregroundStyle(Farbe.gold.opacity(r.weg ? 0.45 : 1))
                .lineLimit(1)
            }
          }
        } else {
          Text("Öffne Groundset, dann steht hier dein Tag.")
            .font(figtree(11.5))
            .foregroundStyle(Farbe.creme.opacity(0.7))
        }
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(oeffnen("tag"))
    .containerBackground(for: .widget) { DunkelGrund() }
  }
}

struct GroundsetTag: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "GroundsetTag", provider: Quelle()) { e in
      TagAnsicht(lage: e.lage)
    }
    .configurationDisplayName("Coach und Tag")
    .description("Der Satz deines Coachs, dein Schnitt und was heute dran ist.")
    .supportedFamilies([.systemMedium])
  }
}

// MARK: - D: line above the clock

struct GroundsetZeile: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "GroundsetZeile", provider: Quelle()) { e in
      Text(e.lage.zeile)
        .widgetURL(oeffnen("tag"))
        .containerBackground(for: .widget) { Color.clear }
    }
    .configurationDisplayName("Training und Bettzeit")
    .description("Eine Zeile über der Uhr.")
    .supportedFamilies([.accessoryInline])
  }
}

// MARK: - E: two round fields

struct RundAnsicht: View {
  let anteil: Double
  let zahl: String
  let wort: String

  var body: some View {
    Gauge(value: max(0, min(1, anteil))) {
      Text(wort)
    } currentValueLabel: {
      VStack(spacing: 0) {
        Text(zahl).font(.system(size: 14, weight: .bold, design: .rounded))
        Text(wort).font(.system(size: 7, weight: .semibold)).kerning(0.5)
      }
    }
    .gaugeStyle(.accessoryCircularCapacity)
  }
}

struct GroundsetHeuteRund: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "GroundsetHeuteRund", provider: Quelle()) { e in
      RundAnsicht(
        anteil: e.lage.aktuell ? e.lage.anteil : 0,
        zahl: e.lage.aktuell ? "\(e.lage.geschafft)/\(e.lage.gesamt)" : "–",
        wort: "HEUTE"
      )
      .widgetURL(oeffnen("tag"))
      .containerBackground(for: .widget) { Color.clear }
    }
    .configurationDisplayName("Heute geschafft")
    .description("Wie viel von heute schon geschafft ist.")
    .supportedFamilies([.accessoryCircular])
  }
}

struct GroundsetSerieRund: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "GroundsetSerieRund", provider: Quelle()) { e in
      let n = e.lage.daten?.serie ?? 0
      RundAnsicht(
        anteil: Double(n) / Double(max(1, e.lage.serieMarke)),
        zahl: "\(n)",
        wort: n == 1 ? "TAG" : "TAGE"
      )
      .widgetURL(oeffnen("heute"))
      .containerBackground(for: .widget) { Color.clear }
    }
    .configurationDisplayName("Tage am Stück")
    .description("Deine Tage am Stück bis zur nächsten Marke.")
    .supportedFamilies([.accessoryCircular])
  }
}

// MARK: - F: wide field on the lock screen

struct JetztBreitAnsicht: View {
  let lage: Lage

  var body: some View {
    let i = JetztInhalt(lage)
    VStack(alignment: .leading, spacing: 1) {
      Text("Jetzt dran").font(.system(size: 11, weight: .semibold)).opacity(0.8)
      Text(i.titel).font(.system(size: 15, weight: .bold)).lineLimit(1)
      if let b = i.bis {
        (Text("in ") + Text(b, style: .relative))
          .font(.system(size: 12))
          .lineLimit(1)
      } else {
        Text(i.unter).font(.system(size: 12)).lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .widgetURL(oeffnen(i.ziel))
    .containerBackground(for: .widget) { Color.clear }
  }
}

struct GroundsetJetztBreit: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "GroundsetJetztBreit", provider: Quelle()) { e in
      JetztBreitAnsicht(lage: e.lage)
    }
    .configurationDisplayName("Jetzt dran")
    .description("Das Nächste aus deinem Tag auf dem Sperrbildschirm.")
    .supportedFamilies([.accessoryRectangular])
  }
}

// MARK: - Bundle

@main
struct GroundsetWidgets: WidgetBundle {
  var body: some Widget {
    GroundsetJetzt()
    GroundsetFokus()
    GroundsetTag()
    GroundsetZeile()
    GroundsetHeuteRund()
    GroundsetSerieRund()
    GroundsetJetztBreit()
  }
}
