---
title: App – Gesamtübersicht (Original)
tags: [quelle, app, original]
quelle: Phillips Obsidian, Ordner Business/App
stand: 2026-10-11
gespeichert: 2026-10-11
---

# App – Gesamtübersicht

Abschrift von Phillips Notiz „App – Gesamtübersicht“ aus seinem eigenen Obsidian (Business/App), am 2026-10-11 im Chat geschickt. Weitere Quellen: [[Quellen]].

---

Stand: 11.10.2026 · alles, was wir bisher zur App erarbeitet haben.

## 1. Die Idee in einem Satz

Eine Coaching-App für Sport und Selbstoptimierung im Alltag: Der Nutzer trackt täglich in einem Gespräch statt in Formularen, eine KI antwortet individuell und persönlich, und eine Grafik zeigt, wie wenig Führung er mit der Zeit noch braucht.

## 2. Warum die App

- Du willst ein besonderes, hilfreiches Produkt zum Thema Sport/Gym und Selbstoptimierung bauen, das Menschen im Alltag wirklich hilft.
- Die App ist die Kombination aus freischaltbaren persönlichen Coaching-Tipps und etwas Essenziellem, das nicht jede App bietet.
- Der Kern, den Nutzer täglich nutzen sollen: Coaching (Tipps und Hilfen) plus Tracking.
- Sie ist die logische Fortsetzung des Buchs: Der Selbsttest im Buch (Fragebogen mit Kapitel-Pfaden) ist die Vorstufe zur adaptiven App.
- Zielgruppe wie beim Buch: Fortgeschrittene, die stagnieren, und alle, die ihr Leben verbessern wollen.

## 3. Kernprinzip

Tracking speist adaptives Coaching. Der Nutzer trackt täglich, die App leitet daraus individuelle Tipps ab – statt eines generischen Plans.

Tracking-Bereiche für den Start:

- Training
- Ernährung (grob, als Gefühl/Beschreibung)
- Schlaf
- Energie/Tag

## 4. Wie die App funktioniert

### 4.1 Onboarding

Ein Einstiegs-Fragebogen personalisiert die App direkt: Ziel (z. B. Muskelaufbau, mehr Energie, bessere Routinen), aktuelles Level, Ausgangssituation.

### 4.2 Täglicher Feed (Kernbildschirm)

Conversationelle, offene Fragen statt starrer Formulare, zum Beispiel:

- „Wie war dein Training heute?“
- „Was hast du heute gegessen, und wie fühlst du dich damit?“
- „Wie hast du geschlafen, und wie ist dein Energielevel heute?“

Der Nutzer antwortet frei in eigenen Worten. Kein Kalorien- oder Makro-Zählen, keine Übungsdatenbank nötig.

### 4.3 KI-Antwort

Die KI reagiert individuell auf die Antworten und bezieht den bisherigen Verlauf ein (Gedächtnis über die letzten Tage und Wochen). So entstehen adaptive statt generischer Tipps.

### 4.4 Fortschritts-Graph

Bei jeder KI-Antwort wird intern zusätzlich eine Kennzahl erfasst (z. B. wie viele konkrete Verbesserungsvorschläge nötig waren, Skala 1–10). Daraus entsteht ein Graph über die Zeit: Am Anfang sind viele Tipps nötig, mit der Zeit werden es weniger, weil der Nutzer mehr richtig macht. Fortschritt wird sichtbar, ohne ihn an Gewicht oder Kalorien festzumachen.

### 4.5 Freischaltbare Coaching-Tipps

Tiefere, ausführlichere Coaching-Inhalte, die der Nutzer freischalten kann (Monetarisierungs-Baustein, siehe Abschnitt 8).

### 4.6 Fragen in der App

**Tägliche Feed-Fragen (MVP)**

- Wie war dein Training heute?
- Was hast du heute gegessen, und wie fühlst du dich damit?
- Wie hast du geschlafen, und wie ist dein Energielevel heute?

**Onboarding**

Es gibt noch keine ausformulierten Onboarding-Fragen. Festgelegt sind nur die Themen (Ziel, aktuelles Level, Ausgangssituation) und eine Beispielfrage für die Onboarding-Seite in FlutterFlow: „Was ist dein Ziel?“. Die Fragen werden als Nächstes zusammen formuliert.

## 5. Entscheidungen auf dem Weg

**Verworfen: detailliertes All-in-one-Tracking.** Zuerst war die Idee, bei Training alle Übungen einzeln einzutragen (plus Trainingsgefühl) und bei Ernährung genau zu erfassen, was gegessen wurde, inklusive automatischer Protein-/Fett-/Carb-Berechnung.

**Gewählt: täglicher Feed mit Gesprächs-Fragen.** Die KI gibt individuelle, persönliche Antworten statt starrer Formulare mit Kalorien- und Makrozählung. Passt auch zur Haltung aus Kapitel 6: Kontrolle ja, aber ohne Zählzwang.

**Gewünscht: Statistik aus den KI-Antworten.** Eine Grafik, die sich aus der KI-Bewertung ableitet (Tipps-Bedarf sinkt), statt reiner Zahlen.

## 6. Datenstruktur (Grobkonzept)

Ein Nutzer hat viele Check-ins, jeder Check-in hat genau eine KI-Antwort. Der Fortschritts-Graph wird direkt aus den Kennzahlen der KI-Antworten gebildet – dafür ist keine eigene Tabelle nötig.

**Nutzer (Users)**

- Nutzer-ID (automatisch)
- Name / Anzeigename
- E-Mail
- Registrierungsdatum
- Abo-Status (kostenlos / aktiv-bezahlt / gekündigt)
- Ziel aus dem Onboarding
- Ausgangssituation/Level aus dem Onboarding

**Check-ins** (täglich, ein Eintrag pro Tag pro Nutzer)

- Check-in-ID
- Nutzer-ID (Verknüpfung zu Nutzer)
- Datum
- Antwort Training (Freitext)
- Antwort Ernährung/Gefühl (Freitext)
- Antwort Schlaf & Energie (Freitext)

**KI-Antworten** (verknüpft mit jedem Check-in)

- Antwort-ID
- Check-in-ID (Verknüpfung zu Check-in)
- KI-Antworttext (das eigentliche Feedback)
- Antwort-Typ (einfach/kostenlos vs. tief/bezahlt)
- Interne Bewertungs-Kennzahl (1–10, wie viele Tipps nötig waren; Basis für den Graph)

**Fortschritts-Verlauf** (abgeleitet, keine eigene Tabelle)

- Nutzer-ID, Datum, Kennzahl (aggregiert aus den KI-Antworten)

Bewusst weggelassen: Lebensmittel- oder Übungsdatenbank, Kalorien-/Makro-Felder.

**Stand in FlutterFlow (Projekt „Betterlifeapp“, Firestore):**

- users: ziel (String), ausgangslevel (String), abo_status (String)
- checkins: nutzer_id (Document Reference → users), datum (DateTime), antwort_training, antwort_ernaehrung, antwort_schlaf_energie (je String)
- ki_antworten: checkin_id (Document Reference → checkins), antwort_text (String), antwort_typ (String: „einfach“ / „tief“), bewertung (Integer 1–10)

Richtung der Bewertung: ursprünglich 10 = brauchte kaum Tipps (bitte bestätigen).

## 7. Technische Umsetzung

- Du willst die App selbst bauen, hast aber noch nie programmiert.
- Entscheidung: No-Code zum Einstieg (Empfehlung: FlutterFlow), um schnell einen MVP zu testen, statt erst klassisches Programmieren zu lernen.
- Die KI-Anbindung läuft über eine LLM-API (individuelle Antworten und interne Bewertung/Kennzahl).
- Arbeitsteilung: Du baust Oberfläche und Grundstruktur in FlutterFlow (Screens, Datenbank-Tabellen). Claude übernimmt die schwierigeren Teile: die KI-Antwortlogik (Prompt, der aus den Check-in-Antworten personalisierte Tipps plus die Bewertungs-Kennzahl erzeugt), komplexere Backend-Teile und alles, was über No-Code hinausgeht. Du schickst Exporte, Screenshots oder Code-Snippets, Claude baut dazu.

## 8. Monetarisierung

- Erst überlegt: Freemium (einfache KI-Antworten kostenlos, tiefe/ausführliche personalisierte Antworten kostenpflichtig).
- Final entschieden: reines Flatrate-Abo mit weicher Begrenzung (kein Kredit-System, kein gestaffeltes Abo).
- Preis vorerst: 9,99 € pro Monat.

## 9. MVP-Umfang und Stand

Aktueller Stand: Das FlutterFlow-Projekt „Betterlifeapp“ existiert, die drei Firestore-Collections (users, checkins, ki_antworten) sind angelegt. Geplante Seiten: Onboarding, Feed (3 Textfelder + „Absenden“), Antwort (KI-Antwort + „Zurück zum Feed“), Fortschritt (vorerst Platzhalter „Graph kommt hier hin“), Login/Register. Navigation: Onboarding → Feed → Antwort → Feed, Tabs Feed/Fortschritt. Die KI-Antwort selbst braucht ein Backend (LLM-API-Aufruf), das ist noch offen.

Für den ersten Test:

- Konzept und Datenstruktur festgelegt
- Onboarding-Fragebogen
- Täglicher Feed mit den vier Kernfragen (Training, Ernährung/Gefühl, Schlaf, Energie)
- KI-Antwort mit einfacher Regellogik
- Einfache Fortschritts-Ansicht

Später, nicht Teil des MVP:

- Freischaltbare, tiefere Coaching-Tipps
- Erinnerungen/Notifications fürs tägliche Tracking
- Datenschutzerklärung
- Name und Branding der App
- Verbindung zu Buch und Content
- Mögliche Community-Elemente

## 10. Einordnung im Gesamtplan

- Reihenfolge (Stand 09.10.2026): erst das Buch zu Ende schreiben, dann die App bauen, danach aus allem den Verkauf aufziehen (mit Claude, ggf. mit Ausschnitten als Content).
- Verkauf: Das Buch soll über deinen Shopify-Shop verkauft werden (Shop „Mein Shop“, neu angelegt, noch leer).
- Social Media: Eigener Account als Personal Brand (Gym, Leben, Business), darüber werden Buch, App und Shop beworben.
- Business-Ziel insgesamt: eigenes Buch und eigene App aufbauen (dein gesamtes Wissen), Menschen helfen, Claude-Experte werden.

## 11. Nächste Schritte

1. Onboarding-Fragen zusammen formulieren.
2. Seiten in FlutterFlow fertig bauen (Onboarding, Feed, Antwort, Fortschritt, Login/Register) und mit den Collections verbinden.
3. KI-Antwortlogik mit Backend aufsetzen (zuerst einfache Regeln, dann LLM-API); Export oder Screenshots an Claude schicken.
4. Fortschritts-Graph aus dem Feld bewertung anbinden.

## 12. Zugehörige Dateien

- App-Konzept.docx und App-Datenstruktur.docx (Ausgangsdokumente)
- Angepinnte Seite „App-Fortschritt“ (Übersicht und MVP-Checkliste)
