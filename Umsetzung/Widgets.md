---
title: Widgets für Startbildschirm und Sperrbildschirm
status: gebaut (iPhone), Android folgt
datum: 2026-11-14
tags: [umsetzung, widget, handy-version, iphone]
---

# Widgets

Entschieden mit Phillip am 2026-11-14. Entwurf: https://claude.ai/artifact/J59hNYaxV5uGEVyHL8Xw4p . Die sechs Widgets waren Vorschläge von Claude, Phillip hat „alle“ gesagt. Zuerst iPhone, danach Android. „Heute geschafft“ ist direkt im Widget tippbar.

Gehört zu [[Erinnerungen]], [[Fokus der Woche]], [[Tages-Planer]] und [[Umbau]].

## Die sechs Widgets

| | Wo | Größe | Was es zeigt |
|---|---|---|---|
| A Jetzt dran | Startbildschirm | klein, hell | das Nächste aus „Dein Tag“ mit Uhrzeit und Zeit bis dahin, Ring „geschafft von heute“ |
| B Fokus der Woche | Startbildschirm | klein, dunkel | Fokus, Tag X von 7, sieben Striche, Knopf „Heute geschafft“ |
| C Coach und Tag | Startbildschirm | breit | Kern-Satz des Coachs von heute, dein Schnitt, „Heute dran“ als Liste |
| D Zeile | Sperrbildschirm | Zeile über der Uhr | Training mit Zeit und Bettzeit |
| E Rund | Sperrbildschirm | zwei runde Felder | geschafft von heute, Tage am Stück |
| F Breit | Sperrbildschirm | breites Feld | was jetzt dran ist |

## Regeln

- Stil wie in der App: Espresso, Glas, nur Gold. Auf dem Sperrbildschirm gibt das iPhone eine Farbe vor.
- „Jetzt dran“: ohne Check-in zuerst der Check-in, sonst der nächste offene Punkt des Tages, danach „Alles geschafft“.
- Der Ring zählt die Punkte des Tages plus den Check-in. Geschafft ist, was abgehakt oder vorbei ist.
- Der Kern-Satz ist der erste Satz der Coach-Antwort, mit dem zweiten, wenn beide kurz sind.
- Ein Tipp öffnet die passende Stelle: Training, Ernährung, Schlaf, Dein Tag oder Fokus.
- „Heute geschafft“ im Widget hakt sofort ab. Die App übernimmt es beim nächsten Öffnen, mit dem Jubel wie beim Tippen in der App. Zurücknehmen geht nur in der App.
- Das Widget rechnet selbst aus, was als Nächstes dran ist. So stimmt es den ganzen Tag, auch wenn die App zu bleibt. Sind die Daten von gestern, bittet es darum, die App zu öffnen.

## Stand im Code

- `code/lib/startwidget/widget_daten.dart`: baut die Daten (ein JSON-Text). `widget_dienst.dart`: schreibt sie über das Paket `home_widget` in die gemeinsame Gruppe `group.de.phillipzxk.coachApp`.
- `code/lib/home/widget_home.dart`: schickt die Daten kurz nach jeder Änderung und beim Zurückkommen in die App, übernimmt „Heute geschafft“ und öffnet die getippte Stelle.
- `code/ios/GroundsetWidget/`: die Widgets in Swift (`Daten.swift`, `Widgets.swift`, `GeschafftIntent.swift`). Schriften und Coach-Gesicht kommen aus `code/assets`.
- Tests: `code/test/startwidget_test.dart`.

## Noch offen

- Android-Version (dort gibt es keine Sperrbildschirm-Widgets, also A, B und C).
- Auf einem echten iPhone ansehen: geht erst mit Apple-Entwicklerkonto, weil die gemeinsame Gruppe eine Signatur braucht.
