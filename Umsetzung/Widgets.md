---
title: Widgets für Startbildschirm und Sperrbildschirm
status: gebaut (iPhone und Android)
datum: 2026-11-14
tags: [umsetzung, widget, handy-version, iphone]
---

# Widgets

Entschieden mit Phillip am 2026-11-14. Entwurf: https://claude.ai/artifact/J59hNYaxV5uGEVyHL8Xw4p . Die ersten sechs Widgets waren Vorschläge von Claude, Phillip hat „alle“ gesagt; sie wurden am 2026-11-15 durch fünf motivierendere ersetzt (siehe unten).

Gehört zu [[Erinnerungen]], [[Fokus der Woche]], [[Tages-Planer]] und [[Umbau]].

## Die fünf Widgets (seit 2026-11-15)

Phillip fand die ersten sechs zu wenig motivierend („mehr motivierende besondere“). Entwurf 2: https://claude.ai/artifact/SRLMngtyRF3fM9erJyeWiZ , fünf Vorschläge von Claude. Phillip am 2026-11-15: „alles und die ersetzen komplett“. Die ersten sechs (Jetzt dran, Fokus der Woche, Coach und Tag, drei für den Sperrbildschirm) sind damit raus, auch „Heute geschafft“ im Widget.

| | Größe | Was es zeigt |
|---|---|---|
| 1 Dein Baum | klein | Der Trieb aus der App. Jeder Tag am Stück ein Blatt (gezeichnet bis acht), jeder geschaffte Fokus-Tag eine Wurzel. Darunter „Noch X bis zur Marke“ oder „Dein Rekord“. An den Marken 3, 7, 14, 30 und danach alle 30 ist das Feld einen Tag lang gold. |
| 2 Jetzt dran | klein, hell | Das Nächste aus „Dein Tag“. Nach etwas Geschafftem eine Stunde lang „… ist im Kasten. Noch N heute. Weiter so, Name.“ Ist alles geschafft, volles Gold „Tag komplett“ bis Mitternacht. |
| 3 Dafür | klein | Das eigene Ziel (Frage 1) und der eigene Grund (Frage 2) in den eigenen Worten, im täglichen Wechsel. Darunter, was heute darauf einzahlt. |
| 4 Dein Coach spricht | breit | Mit Gesicht. Bis 17 Uhr der Kern-Satz des Coachs und der Fokus-Tag. Ab 17 Uhr „X von Y geschafft“ und, wenn es stimmt, „Dein bester Samstag der letzten N Wochen“. |
| 5 Deine Woche | klein | Sieben Kreise Montag bis Sonntag, dazu der Vergleich mit der letzten Woche. |

## Regeln

- Stil wie in der App: Espresso, Glas, nur Gold.
- Der Baum stirbt nicht: Ohne Check-in bleibt er stehen und startet neu.
- Gelobt wird nur, was wirklich abgehakt wurde: ein Punkt des Tages, das Training, der Fokus oder der Check-in.
- Ein Kreis der Woche wird gold, wenn der Tag einen Check-in hat. Lief an dem Tag der Fokus der Woche, muss er auch geschafft sein.
- Der Abend-Vergleich erscheint nur, wenn der heutige Schnitt die beiden letzten gleichen Wochentage schlägt. Sonst steht dort nur der Stand. Verglichen wird nur mit dir selbst.
- Der Kern-Satz ist der erste Satz der Coach-Antwort, mit dem zweiten, wenn beide kurz sind.
- Ein Tipp öffnet die passende Stelle: Heute, Training, Ernährung, Schlaf, Dein Tag oder Mindset (Dafür).
- Das Widget rechnet selbst aus, was als Nächstes dran ist. Sind die Daten von gestern, bittet es darum, die App zu öffnen.
- Widgets dürfen sich nicht frei bewegen. Ein Wechsel blendet weich über, Funken gibt es nur in der App.

## Stand im Code

- `code/lib/startwidget/widget_daten.dart`: baut die Daten (ein JSON-Text). `widget_dienst.dart`: schreibt sie über das Paket `home_widget` in die gemeinsame Gruppe `group.de.phillipzxk.coachApp`.
- `code/lib/home/widget_home.dart`: schickt die Daten kurz nach jeder Änderung und beim Zurückkommen in die App, merkt sich, was neu geschafft ist (für das Lob), und öffnet die getippte Stelle.
- `code/ios/GroundsetWidget/`: die Widgets in Swift (`Daten.swift`, `Widgets.swift`). Schriften und Coach-Gesicht kommen aus `code/assets`.
- `code/android/app/src/main/kotlin/.../Widgets.kt` mit den Layouts in `res/layout/widget_*.xml`: dieselben fünf für Android. Dort nur die Uhrzeit statt Countdown, neu etwa alle 30 Minuten.
- Tests: `code/test/startwidget_test.dart`.

## Noch offen

- Auf einem echten Handy ansehen: beim iPhone erst mit Apple-Entwicklerkonto, weil die gemeinsame Gruppe eine Signatur braucht.
