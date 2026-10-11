---
title: Offene Fragen
tags: [offen, entscheidungen]
aktualisiert: 2026-10-10
---

# Offene Fragen

## Widersprüche in den Unterlagen

- ~~**Preis:**~~ **Entschieden** laut [[App-Gesamtübersicht (Original)]]: reines Flatrate-Abo mit weicher Begrenzung, vorerst 9,99 €/Monat.
- **Vier Fragen vs. drei Felder:** Der tägliche Feed hat vier Kernfragen (Training, Ernährung/Gefühl, Schlaf, Energie), die [[Check-ins]] speichern aber drei Freitextfelder (Schlaf & Energie zusammen). Bleibt das so?

## Onboarding

Aus dem Entwurf [[Onboarding-Fragebogen]] (2026-10-10):

- ~~Zwei neue Felder in [[Nutzer]]?~~ **Entschieden 2026-10-10: ja.** `ausgangssituation` und `onboarding_notiz` sind im [[Datenmodell]] ergänzt.
- **Backend:** Die App speichert die Antworten vorerst nur auf dem Gerät. Für Anmeldung und Online-Speicherung ist **Firebase** vorgeschlagen; dafür braucht es ein Firebase-Projekt in Phillips Google-Konto (siehe [[Technischer Ansatz]]). Noch nicht festgelegt.
- **Antworten später ändern:** Soll es eine Profil-Seite geben, auf der Ziel und Level angepasst werden können? Im MVP bisher nicht vorgesehen.

## Laut Konzept später zu klären

- Monetarisierung im Detail: was ist kostenlos, was kostenpflichtig (vgl. Antwort-Typ in [[KI-Antworten]])
- Erinnerungen/Notifications für tägliches Tracking
- Datenschutz / Datenschutzerklärung
- Name und Branding der App
- Verbindung zu Buch und Content
- Mögliche Community-Elemente

## Technik

- **Bewertungs-Richtung:** Heißt 10 „brauchte kaum Tipps“? Laut [[App-Gesamtübersicht (Original)]] noch von Phillip zu bestätigen.
- **FlutterFlow oder Code?** Die Gesamtübersicht sieht FlutterFlow („Betterlifeapp“) vor, am 2026-10-10 wurde Code von Claude entschieden. Klärung läuft.

- Welcher LLM-Anbieter bzw. welches Modell? (siehe [[Technischer Ansatz]])
- Wie die „einfache Regellogik“ der KI-Antwort im MVP konkret aussieht
- Wie die Bewertungs-Kennzahl (1–10) genau berechnet wird (siehe [[Fortschritts-Verlauf]])
