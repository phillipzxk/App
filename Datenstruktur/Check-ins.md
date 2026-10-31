---
title: Check-ins
tags: [datenstruktur, tabelle]
aliases: [Check-in]
aktualisiert: 2026-10-12
---

# Check-ins

Teil von [[Datenmodell]]. Täglich, **ein Eintrag pro Tag pro Nutzer**. Entsteht im [[Täglicher Check-in|täglichen Check-in]].

| Feld | Beschreibung |
|---|---|
| Check-in-ID | |
| Nutzer-ID | Verknüpfung zu [[Nutzer]] |
| Datum | |
| Antwort Training | Freitext |
| Antwort Ernährung | Freitext |
| Antwort Schlaf | Freitext (Schlaf, Energie mit abgefragt) |
| Antwort Mindset | Freitext (neu seit 2026-10-12) |
| Energie | Hoch, Mittel oder Niedrig (zählt seit 2026-10-31 zu Produktivität) |
| Fokus | Antwort Produktivität & Fokus (neu seit 2026-10-31) |
| Business | Antwort Business & Beruf (neu seit 2026-10-31) |
| Persönlichkeit | Antwort Persönlichkeit (neu seit 2026-10-31) |

Jeder Check-in hat genau eine [[KI-Antworten|KI-Antwort]].

> [!note] Seit 2026-10-12: vier Felder
> Der Check-in hat 4 Fragen (Training, Ernährung, Schlaf, Mindset), siehe [[Täglicher Check-in]]. Das alte Feld „Schlaf & Energie“ heißt jetzt „Schlaf“, „Mindset“ ist neu. Später kommen noch die Fragen dazu, die die KI an dem Tag tatsächlich gestellt hat.
