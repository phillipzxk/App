---
title: Offene Fragen
tags: [offen, entscheidungen]
aktualisiert: 2026-10-10
---

# Offene Fragen

## Widersprüche in den Unterlagen

- **Preis:** Die Fortschritts-Übersicht nennt ein **Flatrate-Abo für 9,99 €/Monat**, das App-Konzept sagt dagegen „Monetarisierung im Detail später zu klären“. Ist 9,99 €/Monat entschieden?
- **Vier Fragen vs. drei Felder:** Der tägliche Feed hat vier Kernfragen (Training, Ernährung/Gefühl, Schlaf, Energie), die [[Check-ins]] speichern aber drei Freitextfelder (Schlaf & Energie zusammen). Bleibt das so?

## Onboarding

Aus dem Entwurf [[Onboarding-Fragebogen]] (2026-10-10):

- **Zwei neue Felder in [[Nutzer]]?** Vorschlag: `ausgangssituation` (Antwort auf „Was hält dich gerade am meisten zurück?“) und `onboarding_notiz` (optionaler Freitext). Bisher sind „Ausgangssituation / Level“ ein gemeinsames Feld, das [[Datenmodell]] ist deshalb noch **nicht** geändert. Alternative: Frage 3 und 4 weglassen, dann reichen `ziel` und `level`.
- **Backend:** Die FlutterFlow-Anleitung geht von **Firebase** aus (siehe auch [[Technischer Ansatz]]). Noch nicht festgelegt.
- **Antworten später ändern:** Soll es eine Profil-Seite geben, auf der Ziel und Level angepasst werden können? Im MVP bisher nicht vorgesehen.

## Laut Konzept später zu klären

- Monetarisierung im Detail: was ist kostenlos, was kostenpflichtig (vgl. Antwort-Typ in [[KI-Antworten]])
- Erinnerungen/Notifications für tägliches Tracking
- Datenschutz / Datenschutzerklärung
- Name und Branding der App
- Verbindung zu Buch und Content
- Mögliche Community-Elemente

## Technik

- Welcher LLM-Anbieter bzw. welches Modell? (siehe [[Technischer Ansatz]])
- Wie die „einfache Regellogik“ der KI-Antwort im MVP konkret aussieht
- Wie die Bewertungs-Kennzahl (1–10) genau berechnet wird (siehe [[Fortschritts-Verlauf]])
