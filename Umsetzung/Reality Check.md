---
title: Reality Check
tags: [umsetzung, feed, ki, fokus]
status: gebaut
---

# Reality Check

Wöchentlicher, ehrlicher Rückblick vom Coach (Idee 3 aus Phillips „5 Ideen“, 23.10.2026). Kein Motivationsgelaber, keine Schuldgefühle, sondern konkrete Vorschläge. Hängt mit [[Fokus der Woche]], [[Deine Muster]] und dem [[Coach-Stil]] zusammen.

## Entscheidungen (mit Phillip, 24.10.2026)

| Frage | Entscheidung |
|---|---|
| Wann? | **Mit dem Fokus-Wechsel**: am Tag, an dem der Fokus der Woche endet. Ein Wochenmoment statt zwei. |
| Wo? | **Eigene Seite.** Auf Heute nur ein kleines Feld „Dein Reality Check ›“. Es ersetzt an diesem Tag die Karte „Neuer Fokus · wähl einen“. |
| Was zählt als vorgenommen? | **Fokus + Training**: Fokus-Tage (X von 7) und geplante gegen tatsächliche Trainingstage (aus den Check-ins). |
| Die eine Veränderung | **Wird Vorschlag 1** für den neuen Fokus, übernehmbar mit einem Tipp. |

## Aufbau der Seite

1. Vorgenommen vs. umgesetzt: Balken für Fokus und Training (zählt die App selbst).
2. Was dich ausgebremst hat: ein ehrlicher Satz vom Coach aus Check-ins und Mustern.
3. Die eine Veränderung: ein Satz plus kurzer Grund.
4. Dein neuer Fokus: 3 Vorschläge (1 = die Veränderung, dann ggf. „Behalten“), Knopf „Diesen Fokus starten“.

Entwurf: https://claude.ai/artifact/29D2ZzgUCkKDXnuCsQfY9z, Bild `ki-coach/reality-check-entwurf.png`.

## So ist es gebaut (24.10.2026, nach Phillips „Jo“)

- Endet der Fokus, holt die App beim Öffnen einmal die Auswertung vom Coach (gleicher Aufruf wie die neuen Fokus-Vorschläge). Bis dahin steht im Feld „Dein Coach wertet deine Woche aus …“, ohne Verbindung „Nochmal“.
- Training zählt die App selbst: geplant = Tage der Woche mit Eintrag im Trainingsplan (nicht leer, nicht „Ruhetag/Pause/Frei“); gemacht = Check-ins mit „Gut trainiert“ oder „Lief zäh“. Ohne Plan steht nur „Training (kein Plan eingetragen) · N Tage“.
- „Was dich ausgebremst hat“: 1 bis 2 Sätze vom Coach, Tage als Wochentag, ohne Vorwürfe.
- „Die eine Veränderung“ ist Vorschlag 1 (neu, setzt an der Bremse an), dann der alte Fokus zum Behalten („X von 7 geschafft“), dann ein dritter.
- Startet man einen Fokus, schließt sich die Seite, das Feld verschwindet und die neue Fokus-Karte steht auf Heute.
- Der allererste Fokus nach dem Start hat keinen Reality Check (es gibt noch keine Woche).

Bild aus der App: `ki-coach/reality-check-app.png`.
