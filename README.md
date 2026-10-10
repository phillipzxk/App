---
title: App – Startseite
tags: [app, index]
erstellt: 2026-10-09
aktualisiert: 2026-10-10
---

# App – Sport & Selbstoptimierung

Adaptive KI-Coaching-App für Sport und Selbstoptimierung. Statt starrer Formulare gibt es einen täglichen, conversationellen Feed: Der Nutzer erzählt in eigenen Worten von Training, Ernährung/Gefühl, Schlaf und Energie, und eine KI antwortet individuell, mit Gedächtnis über die letzten Tage und Wochen. Ein Fortschritts-Graph zeigt, wie der Bedarf an Tipps über die Zeit sinkt.

> [!info] Obsidian-Vault
> Dieses Repository ist als **Obsidian-Vault** aufgebaut. Einfach den Repo-Ordner in Obsidian über „Ordner als Vault öffnen“ öffnen. Die Notizen sind über `[[Wiki-Links]]` verbunden und in der Graph-Ansicht sichtbar.

## Stand

- **MVP:** 1 von 5 Bausteinen erledigt (Konzept & Datenstruktur), Onboarding programmiert, siehe [[MVP-Fortschritt]]
- **Code:** Flutter-App im Ordner `code/`, von Claude geschrieben; Onboarding fertig, siehe [[App-Code]] und [[Technischer Ansatz]]
- **Vorschau im Browser:** https://claude.ai/artifact/BtH78uqJJJ6vrDVTeBpvcP
- **Name/Branding:** noch offen, siehe [[Offene Fragen]]

## Notizen

### Konzept
- [[App-Konzept]]: Grundprinzip und Idee
- [[Kernmechanik]]: Onboarding, täglicher Feed, KI-Antwort, Fortschritts-Graph, freischaltbare Tipps
- [[Technischer Ansatz]]: FlutterFlow, LLM-API, bewusst kein Kalorien-Tracking

### Datenstruktur
- [[Datenmodell]]: Überblick und Beziehungen
- [[Nutzer]] · [[Check-ins]] · [[KI-Antworten]] · [[Fortschritts-Verlauf]]

### Umsetzung
- [[App-Code]]: Aufbau und Stand des Codes
- [[Onboarding-Fragebogen]]: Fragen, Bildschirmtexte und Speicherwerte

### Fortschritt
- [[MVP-Fortschritt]]: was erledigt ist, was als Nächstes kommt
- [[Roadmap nach dem MVP]]: Ausbaustufen für später

### Buch
- [[Buch – Übersicht]]: Buch „Sport & Selbstoptimierung im Alltag“, 6 von 11 Kapiteln geschrieben
- [[Buchkonzept]] · [[Der Test – Fragebogen]] · [[Buch-Fortschritt]]

### Sonstiges
- [[Offene Fragen]]: noch zu klärende Punkte und Widersprüche
- [[Quellen]]: woher die Infos in diesem Vault stammen

### Originaldokumente
- [[App-Konzept (Original)]] · [[App-Datenstruktur (Original)]] · [[App-Fortschritt]]: wortgetreue Abschriften; Originaldateien in `Quellen/Anhänge/`

## Ordnerstruktur

```
Konzept/          Idee, Kernmechanik, Technik
Datenstruktur/    Datenmodell und Tabellen
Umsetzung/        Pläne für die App-Bausteine
code/             Flutter-Code der App
Fortschritt/      MVP-Stand und Roadmap
Buch/             Buch: Konzept, Fragebogen, Fortschritt
  Kapitel/        Kapiteltexte (Abschriften)
Offene Fragen/    Ungeklärtes
Quellen/          Herkunft der Infos, Originaldokumente
  Anhänge/        Originaldateien (.docx, .html)
    Buch/         Originale des Buchs
```
