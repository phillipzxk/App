---
title: Fortschritts-Verlauf
tags: [datenstruktur, fortschritt]
aliases: [Fortschritts-Graph]
aktualisiert: 2026-10-09
---

# Fortschritts-Verlauf (abgeleitet)

Teil von [[Datenmodell]]. **Keine eigene Tabelle**: Die Werte werden direkt aus den [[KI-Antworten]] ausgelesen.

| Feld | Herkunft |
|---|---|
| Nutzer-ID | [[Nutzer]] |
| Datum | [[Check-ins]] |
| Kennzahl | aggregiert aus den Bewertungs-Kennzahlen der [[KI-Antworten]] |

Der Graph zeigt, wie der Bedarf an Tipps über die Zeit sinkt, je mehr der Nutzer selbst richtig macht. Fortschritt wird so sichtbar, ohne Gewicht oder Kalorien (siehe [[Kernmechanik#4. Fortschritts-Graph|Kernmechanik]]).
