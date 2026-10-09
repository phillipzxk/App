---
title: Check-ins
tags: [datenstruktur, tabelle]
aliases: [Check-in]
aktualisiert: 2026-10-09
---

# Check-ins

Teil von [[Datenmodell]]. Täglich, **ein Eintrag pro Tag pro Nutzer**. Entsteht im [[Kernmechanik#2. Täglicher Feed (Kernbildschirm)|täglichen Feed]].

| Feld | Beschreibung |
|---|---|
| Check-in-ID | |
| Nutzer-ID | Verknüpfung zu [[Nutzer]] |
| Datum | |
| Antwort Training | Freitext |
| Antwort Ernährung/Gefühl | Freitext |
| Antwort Schlaf & Energie | Freitext |

Jeder Check-in hat genau eine [[KI-Antworten|KI-Antwort]].

> [!note]
> Das Konzept spricht von **vier Kernfragen** (Training, Ernährung/Gefühl, Schlaf, Energie), gespeichert werden aber **drei** Freitextfelder, weil Schlaf und Energie zusammengefasst sind. Siehe [[Offene Fragen]].
