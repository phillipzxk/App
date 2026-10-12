---
title: Main Feed
tags: [umsetzung, startseite, gewicht]
aliases: [Startseite, Gewichtstracker, Gewichtsanalyse]
erstellt: 2026-10-12
status: erste Version programmiert, wird noch gemeinsam ausgearbeitet
---

# Main Feed

Die Startseite der App (Idee von Phillip, 2026-10-12). Der App-Aufbau:

1. **[[Täglicher Check-in]]**: die 4 Fragen und die KI-Antwort, jeden Tag. Kommt beim ersten Öffnen am Tag automatisch. Deckt schnell alle Self-Improvement-Ebenen ab.
2. **Main Feed**: öffnet sich erst nach dem Check-in und ist individuell für den Tag, „cool gestaltet“ mit Grafen, Texten und weiteren Möglichkeiten (Phillip, 2026-10-12). Dazu Gewichtsanalyse und weitere Werkzeuge, die beim Self-Improvement unterstützen.

## Idee

Der Main Feed bietet **individuelle Inhalte als Reaktion auf die Check-in-Antworten**. Wer z. B. mehrmals Probleme beim Einschlafen schreibt, bekommt dort passende Hilfe zum Schlaf angezeigt. Wird noch gemeinsam ausgearbeitet.

## Gewichtstracker (beschlossen 2026-10-12)

- **Freiwillig:** Wer will, trägt sein Gewicht ein, wer nicht will, sieht nur einen kurzen Hinweis.
- **Wochenschnitt statt Tageswert:** Das Diagramm zeigt den Schnitt pro Woche (Montag bis Sonntag), damit normale Schwankungen nicht frustrieren.
- **Getrennt vom [[Fortschritts-Verlauf]]:** Der Haupt-Graph bleibt „wie viel Hilfe brauchst du noch“. Die [[App-Gesamtübersicht (Original)|Gesamtübersicht]] sagt bewusst, Fortschritt wird nicht an Gewicht festgemacht; der Tracker ist ein optionaler Zusatz.
- Die KI darf den Trend in ihren Antworten nutzen, z. B. „Dein Gewicht geht in die richtige Richtung, deine Ernährung wirkt.“
- Gespeichert in [[Gewicht]].

## Stand im Code (2026-10-12)

Erste Version auf Phillips Wunsch („gern auch die Gewichtsanalyse als Main Feed schon mal“):

- Oben das Datum, darunter die Karte **Dein Coach · heute** mit der KI-Antwort zum Check-in (bis die KI läuft, ein Hinweis).
- Karte **Gewicht**: ohne Einträge ein kurzer Hinweis und „Gewicht eintragen“; mit Einträgen der aktuelle Wochenschnitt, die Veränderung zur Vorwoche und das Diagramm der letzten 12 Wochen.
- Unten „Fragebogen neu starten“, nur zum Testen.

Farben und Stil sind Platzhalter; das Design kommt als eigener Schritt mit Name und Branding (siehe [[Roadmap nach dem MVP]]).
