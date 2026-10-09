---
title: App – Startseite
tags: [app, index]
erstellt: 2026-10-09
aktualisiert: 2026-10-09
---

# App – Sport & Selbstoptimierung

Adaptive KI-Coaching-App für Sport und Selbstoptimierung. Statt starrer Formulare gibt es einen täglichen, conversationellen Feed: Der Nutzer erzählt in eigenen Worten von Training, Ernährung/Gefühl, Schlaf und Energie, und eine KI antwortet individuell, mit Gedächtnis über die letzten Tage und Wochen. Ein Fortschritts-Graph zeigt, wie der Bedarf an Tipps über die Zeit sinkt.

> [!info] Obsidian-Vault
> Dieses Repository ist als **Obsidian-Vault** aufgebaut. Einfach den Repo-Ordner in Obsidian über „Ordner als Vault öffnen“ öffnen. Die Notizen sind über `[[Wiki-Links]]` verbunden und in der Graph-Ansicht sichtbar.

## Stand

- **MVP:** 1 von 5 Bausteinen erledigt (Konzept & Datenstruktur), siehe [[MVP-Fortschritt]]
- **Code:** noch keiner; geplant mit FlutterFlow (No-Code) und einer LLM-API, siehe [[Technischer Ansatz]]
- **Name/Branding:** noch offen, siehe [[Offene Fragen]]

## Notizen

### Konzept
- [[App-Konzept]]: Grundprinzip und Idee
- [[Kernmechanik]]: Onboarding, täglicher Feed, KI-Antwort, Fortschritts-Graph, freischaltbare Tipps
- [[Technischer Ansatz]]: FlutterFlow, LLM-API, bewusst kein Kalorien-Tracking

### Datenstruktur
- [[Datenmodell]]: Überblick und Beziehungen
- [[Nutzer]] · [[Check-ins]] · [[KI-Antworten]] · [[Fortschritts-Verlauf]]

### Fortschritt
- [[MVP-Fortschritt]]: was erledigt ist, was als Nächstes kommt
- [[Roadmap nach dem MVP]]: Ausbaustufen für später

### Sonstiges
- [[Offene Fragen]]: noch zu klärende Punkte und Widersprüche
- [[Quellen]]: woher die Infos in diesem Vault stammen

## Ordnerstruktur

```
Konzept/          Idee, Kernmechanik, Technik
Datenstruktur/    Datenmodell und Tabellen
Fortschritt/      MVP-Stand und Roadmap
Offene Fragen/    Ungeklärtes
Quellen/          Herkunft der Infos
```
