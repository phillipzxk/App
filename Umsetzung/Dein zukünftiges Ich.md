---
title: Dein zukünftiges Ich
tags: [umsetzung, ki, fortschritt, foto, teilweise-gebaut]
erstellt: 2026-10-16
aktualisiert: 2026-10-16
---

# Dein zukünftiges Ich

Herzstück aus Phillips Notiz „App-Fortschritt“ (Idee vom 14.10.2026, Abschrift in [[App-Fortschritt]]). Am 2026-10-16 mit Phillip Schritt für Schritt ausgearbeitet und nach seinem „Ja“ teilweise gebaut (siehe „Stand im Code“).

**Ziel (Phillip):** Leute sehen ihren Fortschritt. Das ist der Hauptgrund, warum sie aufgeben (Buch: Kapitel 9, Testfrage 7).

## Festgelegt

| Punkt | Entscheidung | Datum |
|---|---|---|
| Wo steht es in der App? | **Karte auf „Heute“**, die eine eigene Seite öffnet. Unten bleibt es bei 5 Seiten (siehe [[Main Feed]]). | 2026-10-16 |
| Womit wird fotografiert? | **Eigenes Produkt zum Fotografieren**, das ausschließlich mit der App verbunden ist. Teil der Start-up-Idee (Phillip). Details zum Produkt folgen. Das Produkt wird nebenbei entwickelt. | 2026-10-16 |
| Fotos, bis das Produkt fertig ist? | **Erstmal mit dem Handy.** Bis das Produkt da ist, fotografiert man mit der Handykamera, mit Hinweis auf gleiche Pose und gleiches Licht. Danach übernimmt das Produkt. So läuft auch Phillips 8-Wochen-Test schon in der App. | 2026-10-16 |
| Woher kommen die Leistungswerte? | **Beides.** Jetzt legt man einmal 1 bis 3 eigene Werte in eigenen Worten fest (z. B. „Klimmzüge am Stück“, „5 km Zeit“) und trägt sie jede Woche mit dem Foto ein. Später füllt die KI sie aus den Trainings-Check-ins vor. | 2026-10-16 |
| Wie vergleicht man die Fotos? | **Beides.** Oben groß das erste Foto neben dem neuesten, mit den Werten von damals und heute darunter. Darunter eine Reihe aller Wochenfotos zum Durchwischen. | 2026-10-16 |
| Wo werden die Fotos gespeichert? | **Nur auf dem Handy.** Zur KI geht ein Foto später nur kurz für die Auswertung und wird dort nicht gespeichert. Neues Handy oder App gelöscht heißt: Fotos weg. Eine verschlüsselte Online-Sicherung kann nach dem MVP kommen. | 2026-10-16 |
| An welchem Tag ist das Wochenfoto? | **Selbst wählen.** Jeder legt seinen Fototag einmal selbst fest (Sonntag ist vorausgewählt). **Der Tag bleibt dann fest** (Phillip): Das Foto wird ausschließlich an diesem Tag gemacht, nicht irgendwann zwischendurch. Die Karte auf „Heute“ erinnert an diesem Tag. | 2026-10-16 |
| Fototag verpasst? | **Einen Tag nachholen, freiwillig.** Am Tag nach dem Fototag kann man das Foto einmal nachholen (Phillip: wer es streng gleichmäßig will, lässt es, wem das egal ist, holt nach). Danach fällt die Woche aus und steht als Lücke in der Reihe. Ein nachgeholtes Foto ist in der Reihe mit dem Wochentag markiert. (Erst „Woche fällt aus“ gewählt, kurz danach so geändert.) | 2026-10-16 |
| Welche Posen? | **Frei wählbar.** Wie viele und welche Posen, entscheidet der Nutzer selbst. Die App gibt als Tipp: jede Woche dieselben, am besten nur eine (Phillip). | 2026-10-16 |
| Wie wird ausgelöst? | **Automatisch bei exakt gleicher Position.** Die Umrisse des ersten Fotos liegen über dem Kamerabild. Erkennt die App, dass der Nutzer exakt gleich steht wie beim ersten Foto, löst sie von selbst aus. So sind die Ergebnisse immer exakt vergleichbar; das macht das Feature besonders (Phillip). Technisch: Posen-Erkennung direkt auf dem Handy, läuft erst in der Handy-Version, nicht in der Browser-Vorschau. | 2026-10-16 |

## Offen

- Wie das Foto-Produkt aussieht und wie es mit der App verbunden wird.

## Stand im Code (2026-10-16)

- **Karte auf „Heute“** unter der Coach-Antwort: „Einrichten“, am Fototag „Foto machen“, am Tag danach „Heute nachholen“, sonst „Nächstes Foto“ mit Wochentag und Woche.
- **Einrichten:** Fototag (Sonntag vorausgewählt, danach fest), eigene Posen, bis zu 3 eigene Werte. Posen und Werte lassen sich später ändern, der Fototag nicht.
- **Foto machen:** ein Foto pro Pose, daneben das Startfoto zum Vergleich, dazu die Werte der Woche. Fotos werden verkleinert und nur auf dem Handy gespeichert.
- **Eigene Seite:** Startfoto neben dem neuesten (Pose wählbar), Werte Start und neuestes, Reihe aller Wochen mit Lücke für verpasste und Wochentag für nachgeholte Fotos, Einstellungen.
- **Platzhalter bis zur KI:** „Was sich verändert hat“ und die Vorschau auf 3, 6 und 12 Monate.
- **Kommt mit der Handy-Version:** Kamera mit den Umrissen des ersten Fotos und automatisches Auslösen bei exakt gleicher Position, Erinnerung am Fototag. Bis dahin öffnet „Aufnehmen“ die normale Kamera (in der Browser-Vorschau die Dateiauswahl).

## Entwurf

- Karte auf „Heute“, eigene Seite und Foto-Bildschirm (Beispiel Max, Woche 6, 2026-10-16): https://claude.ai/artifact/HN9moCGH9xjVGspSkbeXBy. Phillip: „Ja mach mal“.

## Aus der Notiz, zur Info

- Wöchentlicher Body-Scan mit gleicher Pose und gleichem Licht, die KI zeigt Veränderungen.
- Zukunfts-Projektion für 3, 6 und 12 Monate, realistisch, lieber zu vorsichtig.
- Leistung und Aussehen zusammen; Fotos freiwillig, auch eine Version nur mit Leistungsdaten.
- Ergänzt den Fortschritts-Graphen („weniger Tipps nötig“).
