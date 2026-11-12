---
title: Heute und Fundament
status: gebaut
datum: 2026-11-08
tags: [umsetzung, navigation, heute, fundament]
---

# Heute und Fundament

> Aussehen seit 2026-11-12 neu: siehe [[Umbau]]. Die Struktur hier gilt weiter.

Entschieden mit Phillip am 2026-11-08 (Entwurf 4 „Yes“ zur Struktur, Entwurf 6 „Sehr gut“ zum Aussehen). Entwurf: https://claude.ai/artifact/TaY5WKw9ugeYR9DzbDo5o1

## Warum
Nicht mehr alles auf einer Seite. Mehr Übersicht, echte Seitenwechsel, moderner App-Stil, kein „Vibe-Code“-Look. Das Grundprinzip (Baum, Wurzeln, Braun) bleibt.

## Aufbau
- Unten eine schlanke **Glas-Leiste** mit nur zwei Seiten: **Heute** (Sonne) und **Fundament** (Spross). Ein goldener Tropfen gleitet zur offenen Seite, nur dort steht der Name.
- **Heute** bleibt wie vorher: Coach-Karte, Fokus der Woche, Heute dran, Tage am Stück, Foto, Muster-Feld. Am Ende eine kleine Karte „Dein Fundament“ (Schnitt, schwächster Bereich, Werte der Bereiche), Tippen öffnet die Fundament-Seite.
- **Fundament** = der bisherige realistische Baum ([[Home-Schichten]] Wurzelwerk) unverändert, oben „Deine 4 Bereiche“, Titel „Fundament“ und „Schnitt heute“ mit Änderung zu gestern. Lebensziele bleiben ganz unten.

## Animationen
- Beim Öffnen wächst der Baum von oben nach unten auf, eine Lichtlinie läuft an der Kante mit.
- Licht fließt weiter durch die Wurzeln, der schwächste Bereich leuchtet (wie bisher).
- Ein Bereich öffnet sich aus seinem Kreis (wie bisher).
- Schnitt zählt hoch, Seitenwechsel gleitet weich.

## Stand im Code
- `code/lib/home/fundament_seite.dart`: `FundamentSeite`, `Wachsen`, `FundamentVorschau`, `GlasLeiste`.
- `home_page.dart`: `_zweiSeiten` schaltet zwischen Heute und Fundament.
- `today_tab.dart`: Wurzelwerk raus, `FundamentVorschau` am Ende.
- GitHub ist gerade gesperrt, deshalb noch kein PR. Vorschau ist aktualisiert.
