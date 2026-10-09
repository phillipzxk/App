---
title: App-Fortschritt
tags: [quellen, fortschritt, original]
quelle: https://claude.ai/artifact/G9aBBq7fWyJUhrRzCFn5qd
gespeichert: 2026-10-09
---

# App-Fortschritt (Originalseite)

Wortgetreue Abschrift der Claude-Seite „App-Fortschritt“, Stand 2026-10-09. Die Originaldatei mit Layout liegt daneben: [[App-Fortschritt.html]] (im Browser öffnen). Online: https://claude.ai/artifact/G9aBBq7fWyJUhrRzCFn5qd

Ausgearbeitete Notizen dazu: [[MVP-Fortschritt]], [[Roadmap nach dem MVP]], [[Datenmodell]], [[Technischer Ansatz]].

---

*Sport & Selbstoptimierung — adaptive Coaching-App*

## Die App

Täglicher **conversationeller Feed** statt starrer Formulare: Training, Ernährung/Gefühl, Schlaf, Energie. Die KI antwortet individuell, mit Gedächtnis über die letzten Tage — daraus entsteht ein **Fortschritts-Graph**, der zeigt, wie der Bedarf an Tipps über die Zeit sinkt.

### MVP-Baustellen — 1 / 5

- [x] Konzept & Datenstruktur festgelegt
- [ ] Onboarding-Fragebogen (Ziel, Level, Ausgangssituation)
- [ ] Täglicher Feed mit den vier Kernfragen
- [ ] KI-Antwort mit einfacher Regellogik
- [ ] Einfache Fortschritts-Ansicht

### Später — nicht Teil des MVP

- Freischaltbare, tiefere Coaching-Tipps (Monetarisierung)
- Erinnerungen / Notifications fürs tägliche Tracking
- Datenschutzerklärung, Name/Branding
- Verbindung zu Buch & Content, Community-Elemente

### Datenmodell

Ein Nutzer hat viele Check-ins, jeder Check-in genau eine KI-Antwort. Der Fortschritts-Graph wird direkt daraus aggregiert — keine eigene Tabelle.

| Nutzer | → | Check-in (täglich) | → | KI-Antwort |
|---|---|---|---|---|
| Name, E-Mail | | Training (Freitext) | | Feedback-Text |
| Abo-Status | | Ernährung/Gefühl (Freitext) | | einfach / tief (bezahlt) |
| Ziel & Level (Onboarding) | | Schlaf & Energie (Freitext) | | Bewertungs-Kennzahl 1–10 |

### Technischer Ansatz

- **FlutterFlow** — No-Code UI
- **LLM-API** — Antworten & Bewertung
- Flatrate-Abo, 9,99 €/Monat

*Bewusst weggelassen: Lebensmittel- oder Übungsdatenbank, Kalorien-/Makro-Felder*
