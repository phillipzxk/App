---
title: Technischer Ansatz
tags: [technik]
aliases: [Tech-Stack, Stack]
aktualisiert: 2026-10-10
---

# Technischer Ansatz

Teil von [[App-Konzept]].

> [!important] Entscheidung 2026-10-10: Code statt FlutterFlow
> Claude schreibt die App direkt als **Flutter-Code** im Ordner `code/` dieses Repositorys. Phillip muss nichts mehr zusammenklicken, sondern testet nur. Flutter ist dieselbe Technik, die FlutterFlow im Hintergrund nutzt; die App lässt sich danach aber nicht mehr in FlutterFlow bearbeiten.

| Baustein | Wofür |
|---|---|
| **Flutter** (Code, von Claude geschrieben) | App-Oberfläche und Logik für Android, iPhone und Browser |
| **LLM-API** | individuelle KI-Antworten und die interne Bewertungs-Kennzahl |

## Bewusst nicht gebaut

- Keine eigene Lebensmittel- oder Übungsdatenbank
- Keine Kalorien-/Makro-Erfassung

Grund: Die App setzt auf freie, conversationelle Eingabe statt exaktes All-in-one-Tracking.

## Noch offen

- Welcher LLM-Anbieter bzw. welches Modell
- Wo die Daten online liegen (Vorschlag: Firebase). Bis dahin speichert die App lokal auf dem Gerät.

Siehe [[Offene Fragen]]. Datenmodell: [[Datenmodell]].
