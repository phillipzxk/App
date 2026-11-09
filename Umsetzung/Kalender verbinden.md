---
title: Kalender verbinden
status: gebaut
datum: 2026-11-09
tags: [umsetzung, kalender, dein-tag]
---

# Kalender verbinden

Entschieden mit Phillip: Idee am 2026-11-04 (ein Knopf, danach nur noch der iPhone-Kalender, die eigenen Termine der App verschwinden), Entwurf am 2026-11-09 mit „yes“ bestätigt, auch die drei markierten Ideen von Claude.
Entwurf: https://claude.ai/artifact/D3LCrUvPPZJ9eBBDEb9BwD
Gehört zu [[Tages-Planer]] und [[Schnell-Eintrag]]. Ersetzt dort die Entscheidung „Erst eigener Kalender, später beides“.

## Ablauf
1. In **Dein Tag** steht oben die Karte „Kalender verbinden“ (kleines Kalenderblatt, langsamer Goldglanz, Knopf „Verbinden“).
2. Antippen, das iPhone fragt einmal („Vollen Zugriff erlauben“).
3. Goldene Lichtpunkte fliegen los, die Termine stehen im Sonnenbogen und in der Liste mit „KALENDER“ markiert.
4. Danach sind das Feld „z. B. Zahnarzt Do 17 Uhr“ und die eigene Terminliste weg. Statt dem Feld steht „iPhone-Kalender verbunden · N Termine heute“. Training, Mahlzeiten und Bettzeit bleiben, das sind keine Termine.
5. Termine aus dem [[Schnell-Eintrag]] kommen direkt in den iPhone-Kalender, die Karte sagt „in deinen iPhone-Kalender“.
6. Der Coach plant wie bisher um die Termine herum (Bettzeit, Tagesablauf, Erinnerungen), nur mit den echten.
7. Ohne Erlaubnis bleibt alles wie vorher, kurzer Hinweis, dass man es in den iPhone-Einstellungen erlauben kann.

## Claudes Ideen (bestätigt mit „yes“)
- Termine, die schon in der App standen (ab heute), kommen beim Verbinden mit in den Kalender, damit nichts verloren geht.
- In den Einstellungen: welche Kalender gezeigt werden (Schalter pro Kalender) und in welchen neue Termine kommen.
- „Kalender trennen“ in den Einstellungen holt die Terminliste der App zurück.

## Stand im Code
- `code/lib/kalender/kalender_dienst.dart`: `KalenderDienst` (iPhone über Kanal `groundset/kalender`, Browser-Vorschau mit Beispielterminen aus dem Entwurf, sonst keiner), `KalenderEinstellung` (verbunden, ausgeblendete Kalender, Ziel-Kalender, gespeichert unter `kalender`).
- `code/lib/kalender/kalender_logik.dart`: verbinden (mit Umzug der eigenen Termine) und trennen.
- `code/lib/home/kalender_home.dart`: lädt die Termine aus dem Kalender, legt neue dort an, liest beim Zurückkommen in die App neu.
- `code/lib/home/day_plan.dart`: Karte „Kalender verbinden“ und die Zeile „verbunden“.
- `code/lib/konto/konto_einstellungen.dart`: Gruppe Kalender.
- iPhone: EventKit in `ios/Runner/AppDelegate.swift` (`GroundsetKalender`), Texte für die Frage in `Info.plist`.
- Android: kommt mit der Android-Version (dort der Handy-Kalender, meist Google).
