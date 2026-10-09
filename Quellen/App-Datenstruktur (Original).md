---
title: App-Datenstruktur (Original)
tags: [quellen, datenstruktur, original]
quelle: App-Datenstruktur.docx
gespeichert: 2026-10-09
---

# App-Datenstruktur (Original)

Wortgetreue Abschrift von **App-Datenstruktur.docx**. Originaldatei: [[App-Datenstruktur.docx]]. Ausgearbeitete Notizen dazu: [[Datenmodell]], [[Nutzer]], [[Check-ins]], [[KI-Antworten]], [[Fortschritts-Verlauf]].

---

## App – Datenstruktur (Grobkonzept)

### Grundprinzip

Jeder Nutzer hat viele Check-ins, jeder Check-in hat genau eine KI-Antwort. Der Fortschritts-Graph wird aus den gesammelten Bewertungs-Kennzahlen aller KI-Antworten eines Nutzers über die Zeit gebildet – keine separate Tabelle nötig, die Werte werden direkt aus den KI-Antworten ausgelesen.

### 1. Nutzer (Users)

- Nutzer-ID (automatisch)
- Name / Anzeigename
- E-Mail
- Registrierungsdatum
- Abo-Status (kostenlos / aktiv-bezahlt / gekündigt)
- Ziel aus dem Onboarding (z. B. Muskelaufbau, mehr Energie, bessere Routinen)
- Ausgangssituation/Level aus dem Onboarding

### 2. Check-ins (täglich, ein Eintrag pro Tag pro Nutzer)

- Check-in-ID
- Nutzer-ID (Verknüpfung zu 1.)
- Datum
- Antwort Training (Freitext)
- Antwort Ernährung/Gefühl (Freitext)
- Antwort Schlaf & Energie (Freitext)

### 3. KI-Antworten (verknüpft mit jedem Check-in)

- Antwort-ID
- Check-in-ID (Verknüpfung zu 2.)
- KI-Antworttext (das eigentliche Feedback)
- Antwort-Typ (einfach/kostenlos vs. tief/bezahlt)
- Interne Bewertungs-Kennzahl (z. B. 1–10, wie viele Tipps nötig waren – Basis für den Fortschritts-Graph)

### 4. Fortschritts-Verlauf (abgeleitet, keine eigene Tabelle nötig)

- Nutzer-ID
- Datum
- Kennzahl (aggregiert aus Tabelle 3)

### Bewusst weggelassen

Keine Lebensmittel- oder Übungsdatenbank, keine Kalorien-/Makro-Felder – passend zum conversationellen, einfachen Ansatz statt detailliertem All-in-one-Tracking.
