---
title: Nutzer
tags: [datenstruktur, tabelle]
aliases: [Users]
aktualisiert: 2026-10-13
---

# Nutzer (Users)

Teil von [[Datenmodell]].

| Feld | Beschreibung |
|---|---|
| Nutzer-ID | automatisch |
| Name / Anzeigename | Vorname; der Coach spricht den Nutzer damit an (entschieden 2026-10-13, siehe [[Coach-Stil]]). Abfrage „Wie heißt du?“ vor dem [[Onboarding-Fragebogen|Onboarding]], Feld `name`. |
| E-Mail | |
| Registrierungsdatum | |
| Abo-Status | kostenlos / aktiv-bezahlt / gekündigt |
| Ziel | Onboarding-Frage 1, in eigenen Worten |
| Motivation | Onboarding-Frage 2, in eigenen Worten (neu seit 2026-10-11) |
| Level | Onboarding-Frage 3, in eigenen Worten |
| Training | Onboarding-Frage 4, Ausgangssituation Training (neu seit 2026-10-11) |
| Ernährung | Onboarding-Frage 5, Ausgangssituation Ernährung (neu seit 2026-10-11) |
| Schlaf & Energie | Onboarding-Frage 6, Ausgangssituation Schlaf & Energie (neu seit 2026-10-11) |
| Zusammenfassung | „So sehe ich dich gerade“, von der KI aus den sechs Antworten (neu seit 2026-10-11) |

Alle Onboarding-Felder sind Freitext, die Fragen stehen in [[Onboarding-Fragebogen]]. Die Felder `ausgangssituation` und `onboarding_notiz` vom 2026-10-10 sind damit ersetzt.

Ein Nutzer hat viele [[Check-ins]].
