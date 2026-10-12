---
title: App-Code
tags: [code, umsetzung]
erstellt: 2026-10-10
---

# App-Code (Flutter)

Der Code der App, geschrieben von Claude. Hintergrund: [[Technischer Ansatz]].

## Stand

- **Onboarding-Fragebogen** mit den 6 Fragen vom 2026-10-11 fertig, siehe [[Onboarding-Fragebogen]]. Die Antworten werden vorerst nur auf dem Gerät gespeichert. Die KI-Zusammenfassung fehlt noch, bis dahin steht dort ein Hinweis.
- **Täglicher Check-in** mit den 4 Leitfragen, siehe [[Täglicher Check-in]]. Die KI-Antwort fehlt noch, bis dahin steht dort ein Hinweis.
- **Main Feed** (Startseite) mit Check-in-Karte und freiwilligem Gewichtstracker, siehe [[Main Feed]].

## Aufbau

```
lib/main.dart                         Start: Onboarding beim ersten Mal, sonst Startseite
lib/data/user_profile.dart            Felder aus der Tabelle Nutzer
lib/data/profile_store.dart           Speichern (lokal, später online)
lib/onboarding/onboarding_questions.dart  Die 6 Fragen
lib/onboarding/onboarding_flow.dart   Die Onboarding-Bildschirme
lib/onboarding/onboarding_evaluator.dart  KI-Auswertung (noch Platzhalter)
lib/ui/coach_style.dart               Farben und Schriften aus dem Mockup
lib/home/home_page.dart               Main Feed (Startseite)
lib/checkin/                          Täglicher Check-in: Fragen, Ablauf, KI-Antwort (Platzhalter)
lib/weight/                           Gewicht: Wochenschnitt und Diagramm
lib/data/diary_store.dart             Speichern von Check-ins und Gewicht (lokal)
lib/ui/coach_widgets.dart             Gemeinsame Bausteine der Bildschirme
test/                                 Automatische Tests
```

## Für Entwickler

```
flutter pub get
flutter test
flutter run                 # auf Handy oder Emulator
tool/build_preview.sh       # Browser-Vorschau bauen (für das Claude-Artifact)
```
