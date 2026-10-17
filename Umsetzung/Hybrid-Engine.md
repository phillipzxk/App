---
title: Hybrid-Progressions-Engine
tags: [umsetzung, training, ki, in-arbeit]
erstellt: 2026-10-17
aktualisiert: 2026-10-17
---

# Hybrid-Progressions-Engine

Idee von Phillip aus [[App-Fortschritt]]: „Powerlifting, Calisthenics und Ausdauer kombinieren, ohne dass sie sich ausbremsen.“ Wird seit 2026-10-17 Schritt für Schritt mit ihm ausgearbeitet. Baut auf dem eigenen [[Trainingsplan]] und dem [[Tages-Planer]] auf (eigener Plan + KI, keine Übungsdatenbank).

## Festgelegt

| Frage | Entscheidung | Datum |
|---|---|---|
| Was tut die Engine? | **Abstimmen + steigern.** Die KI prüft den eigenen Plan, ob sich Kraft, Calisthenics und Ausdauer ausbremsen, und schlägt eine bessere Reihenfolge vor. Dazu nennt sie pro Einheit den nächsten Schritt, z. B. 2,5 kg mehr, eine Wiederholung mehr, 1 km länger. Der eigene Plan bleibt. | 2026-10-17 |
| Woher kennt die KI die geschafften Werte? | **Aus den eigenen Worten.** Der Nutzer schreibt wie bisher frei, z. B. „Bank 3x8 mit 80 kg, Klimmzüge 3x6“ (Check-in oder „Wie war dein Training?“). Die KI liest es heraus, kein neues Feld. Fehlt eine Zahl, fragt die KI im Check-in nach. | 2026-10-17 |
| Wo steht der nächste Schritt? | **Im Plan.** Auf der Trainingsseite steht unter jedem Trainingstag das nächste Ziel (z. B. „Bank 3x8 mit 82,5 kg“). „Dein Tag“ auf Heute zeigt nur eine kurze Zeile, Tippen führt zur Trainingsseite. | 2026-10-17 |
| Ändert die KI den Plan bei Ausbremsen selbst? | **Selbst ändern.** Die KI tauscht oder verschiebt Einheiten selbst, mit kurzem Grund und Rückgängig per Tipp, genau wie beim [[Tages-Planer]]. | 2026-10-17 |
| Was hat Vorrang bei Konflikten? | **Schwerpunkt wählen.** Der Nutzer wählt einmal beim Plan: Kraft, Calisthenics, Ausdauer oder ausgeglichen; jederzeit änderbar. Danach richtet die KI Tausch und Steigerung aus. | 2026-10-17 |

Weniger Training nur bei klarem Muster (z. B. 2 schlechte Nächte), wie im [[Tages-Planer]] beschlossen.

## Entwurf

- Trainingsseite und Heute, Beispiel Max (2026-10-17): https://claude.ai/artifact/19NcDAD6LzaUXyuGLn8kpX

## Noch offen

- Phillips Ja zum Entwurf, dann einbauen (KI-Teile als Platzhalter bis zum KI-Anschluss).

Siehe auch [[Main Feed]], [[KI-Anschluss]].
