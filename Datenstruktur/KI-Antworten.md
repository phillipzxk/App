---
title: KI-Antworten
tags: [datenstruktur, tabelle, ki]
aliases: [KI-Antwort]
aktualisiert: 2026-10-09
---

# KI-Antworten

Teil von [[Datenmodell]]. Verknüpft mit jedem [[Check-ins|Check-in]] (genau eine pro Check-in).

| Feld | Beschreibung |
|---|---|
| Antwort-ID | |
| Check-in-ID | Verknüpfung zu [[Check-ins]] |
| KI-Antworttext | das eigentliche Feedback |
| Antwort-Typ | einfach/kostenlos vs. tief/bezahlt |
| Interne Bewertungs-Kennzahl | z. B. 1–10: wie viele Tipps nötig waren; Basis für den [[Fortschritts-Verlauf]] |

Erzeugt über die LLM-API, siehe [[Technischer Ansatz]].
