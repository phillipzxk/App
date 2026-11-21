---
thema: Android nachziehen
stand: 2026-11-21
status: beschlossen und gebaut (Test auf echtem Android-Handy steht aus)
tags: [umsetzung, handy-version, android, beta]
---

# Android nachziehen

Vier Dinge gab es bisher nur auf dem iPhone: [[Echter Wecker]], Schritte-Zählen, [[Apple Health]] und [[Kalender verbinden]]. Jetzt gibt es sie auch auf Android. Aussehen und Ablauf bleiben wie auf dem iPhone.

Entwurf: https://claude.ai/artifact/8cqmVa7vVg7BYk6cv61cXz. Phillip 2026-11-21: „ja“ = bauen.

## 1 · Wecker
- Klingelt zur Aufstehzeit, auch bei gesperrtem Handy, lautlos oder „Nicht stören“ (Wecker-Ton von Android, läuft bis man antwortet).
- Bei gesperrtem Handy öffnet sich der eigene Wecker-Bildschirm über der Sperre: Morgenhimmel mit halb aufgegangener Sonne, Datum, große Uhrzeit, „Guten Morgen, Name“, unten „5 Min“ (nur wenn Schlummern an ist) und „Aufstehen“ in Gold.
- „5 Min“: klingelt in 5 Minuten noch einmal, dann nur noch mit „Aufstehen“. „Aufstehen“: die Aufgabe kommt zuerst; ist sie nach 3 Minuten nicht gemacht, klingelt es noch einmal („Deine Aufgabe wartet“). Wird gar nicht getippt, klingelt es nach 10 Minuten nochmal. Alles wie auf dem iPhone.
- Die Weckertöne aus der App gibt es nur auf dem iPhone; Android nimmt seinen eigenen Wecker-Ton.
- Über der Sperre nur, solange der Wecker klingelt oder seine Aufgabe wartet. Sonst öffnet sich die App nie ohne Entsperren.

## 2 · Einmal erlauben
- Einmal fragt die App in eigenen Worten: „Groundset als Wecker erlauben? Damit dein Wecker pünktlich klingelt, auch wenn das Handy gesperrt ist.“ (Später / Erlauben), danach kommt die Android-Einstellung.
- Ohne Erlaubnis bleibt der Wecker eine Erinnerung, und Erinnerungen kommen höchstens etwas später.
- Schritte: Android fragt einmal nach „Körperliche Aktivität“. Wer nicht erlaubt, tippt stattdessen.

## 3 · Gesundheitsdaten
- Health Connect statt Apple Health, gleiche Seite: Schlaf und Schlafphasen, Ruhepuls und HRV, Training, Schritte, Gewicht. Samsung Health, Fitbit, Garmin, Oura und andere kommen darüber.
- Tageslicht misst Android nicht: die Wurzel und das Feld fallen dort weg (6 statt 7 Wurzeln).
- Fehlt Health Connect (ältere Handys), öffnet sich der Play Store.

## 4 · Kalender
- Heißt auf Android „Handy-Kalender“ und liest alle Kalender vom Handy, also auch Google Kalender. Neue Termine gehen in den gewählten Kalender.

## Gut zu wissen
- Kostenlos, kein Konto und kein Geld nötig.
- Testen: Ein Tester mit Android muss den Wecker einmal klingeln lassen (gesperrt, lautlos).

## Stand im Code
- `lib/plattform/plattform.dart`: Namen je Handy (Handy/iPhone, Health Connect/Apple Health).
- `lib/erinnerungen/erinnerung_dienst.dart`: `AndroidWecker` (Ids ab 9000, Vollbild-Wecker, 5 Min im Hintergrund), `weckerAntworten`, `weckerErlaubnisFehlt`, `weckerErlauben`.
- `lib/schlaf/wecker_klingelt.dart`: der Wecker-Bildschirm. `lib/home/erinnerungen_home.dart`: die eigene Frage vorher.
- `lib/health/health_android.dart`: Health Connect über das Paket `health` (nur lesen).
- `android/.../MainActivity.kt`: Schritte (Schrittsensor) und Kalender über dieselben Kanäle wie `AppDelegate.swift`; über der Sperre nur für den Wecker.
- Android braucht jetzt mindestens Android 8.
