---
title: kcal-Profil
tags: [datenstruktur, tabelle, ernährung]
aliases: [kcal-Ziel]
erstellt: 2026-10-12
---

# kcal-Profil

Teil von [[Datenmodell]]. Einmalige Angaben für das kcal-Ziel im [[Main Feed]] (beschlossen 2026-10-12). Eingerichtet über die Ernährungs-Seite.

| Feld | Beschreibung |
|---|---|
| Nutzer-ID | Verknüpfung zu [[Nutzer]] |
| Größe | in cm |
| Alter | in Jahren |
| Geschlecht | Mann oder Frau |
| Aktivität | Kaum Bewegung, Leicht aktiv, Aktiv, Sehr aktiv |

Das kcal-Ziel selbst wird nicht gespeichert, sondern aus diesen Angaben, dem neuesten [[Gewicht]] und dem Ziel aus dem Onboarding berechnet. Es wird nichts gezählt.
