---
title: Gewicht
tags: [datenstruktur, tabelle]
aliases: [Gewichtseinträge]
erstellt: 2026-10-12
---

# Gewicht

Teil von [[Datenmodell]]. Einträge für den Gewichtstracker im [[Main Feed]] (beschlossen 2026-10-12). Seit 2026-10-12 fest dabei: Der Nutzer trägt sein Gewicht immer wieder neu ein, das neueste Gewicht bestimmt auch das [[kcal-Profil|kcal-Ziel]]. Ein [[Nutzer]] hat beliebig viele Einträge.

| Feld | Beschreibung |
|---|---|
| Nutzer-ID | Verknüpfung zu [[Nutzer]] |
| Datum | Zeitpunkt des Eintrags |
| Kilogramm | z. B. 82,4 |

Der Wochenschnitt für das Diagramm wird aus den Einträgen berechnet und nicht extra gespeichert.
