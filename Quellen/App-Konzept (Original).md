---
title: App-Konzept (Original)
tags: [quellen, konzept, original]
quelle: App-Konzept.docx
gespeichert: 2026-10-09
---

# App-Konzept (Original)

Wortgetreue Abschrift von **App-Konzept.docx**. Originaldatei: [[App-Konzept.docx]]. Ausgearbeitete Notizen dazu: [[App-Konzept]], [[Kernmechanik]], [[Technischer Ansatz]].

---

## App-Konzept & Struktur

**Sport & Selbstoptimierung – adaptive Coaching-App**

### Grundprinzip

Der Nutzer trackt täglich in einem conversationellen Feed sein Training, seine Ernährung/sein Gefühl dabei sowie Schlaf und Energie. Eine KI reagiert darauf individuell und gibt persönliche, adaptive Coaching-Tipps – statt starrer Formulare, Kalorienzählung oder generischer Pläne. Über die Zeit entsteht daraus eine Statistik, die zeigt, wie viel Führung der Nutzer noch braucht – mit dem Ziel, dass diese Kennzahl sinkt, je mehr der Nutzer selbst richtig macht.

### Kernmechanik im Detail

#### 1. Onboarding

Ein Einstiegs-Fragebogen zu Beginn, um die App direkt zu personalisieren (z. B. Ziel, aktuelles Level, Ausgangssituation).

#### 2. Täglicher Feed (Kernbildschirm)

Conversationelle, offene Fragen statt starrer Formulare, z. B.:

- „Wie war dein Training heute?“
- „Was hast du heute gegessen, und wie fühlst du dich damit?“
- „Wie hast du geschlafen, und wie ist dein Energielevel heute?“

Der Nutzer antwortet frei in eigenen Worten (kein Kalorien-/Makro-Zählen, keine Übungsdatenbank nötig).

#### 3. KI-Antwort

Die KI reagiert individuell auf die Antworten des Nutzers, unter Einbezug des bisherigen Verlaufs (Gedächtnis über die letzten Tage/Wochen), um wirklich adaptive statt generische Tipps zu geben.

#### 4. Fortschritts-Graph

Bei jeder KI-Antwort wird zusätzlich intern eine Kennzahl erfasst (z. B. wie viele konkrete Verbesserungsvorschläge nötig waren). Daraus entsteht ein Graph über die Zeit, der zeigt, wie der Bedarf an Tipps abnimmt, je mehr der Nutzer richtig macht – Fortschritt wird so sichtbar gemacht, ohne ihn an Gewicht oder Kalorien festzumachen.

#### 5. Freischaltbare Coaching-Tipps

Zusätzliche, tiefere Coaching-Inhalte, die der Nutzer freischalten kann (Monetarisierungs-Baustein, Details folgen später).

### Technischer Ansatz

- Umsetzung geplant über No-Code (empfohlen: FlutterFlow), da noch keine Programmiererfahrung vorhanden ist.
- KI-Anbindung über eine LLM-API für die individuellen Antworten und die interne Bewertung/Kennzahl.
- Kein Aufbau einer eigenen Lebensmittel- oder Übungsdatenbank nötig, da bewusst auf freie, conversationelle Eingabe statt exakter Kalorien-/Makro-Erfassung gesetzt wird.

### MVP-Fokus

Für den ersten Test-Umfang: Onboarding-Fragebogen, täglicher Feed mit den vier Kernfragen (Training, Ernährung/Gefühl, Schlaf, Energie), KI-Antwort mit einfacher Regellogik, sowie eine einfache Fortschritts-Ansicht. Freischaltbare Tipps und weitere Ausbaustufen folgen später.

### Später zu klären (nicht Teil des aktuellen Plans)

- Monetarisierung im Detail (was ist kostenlos, was kostenpflichtig)
- Erinnerungen/Notifications für tägliches Tracking
- Datenschutz/Datenschutzerklärung
- Name/Branding der App
- Verbindung zu Buch und Content
- Mögliche Community-Elemente
