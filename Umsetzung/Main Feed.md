---
title: Main Feed
tags: [umsetzung, startseite, gewicht, training, ernährung, schlaf, mindset]
aliases: [Startseite, Gewichtstracker, Gewichtsanalyse, Trainingsplan, Abendroutine, kcal-Ziel]
erstellt: 2026-10-12
aktualisiert: 2026-10-12
status: gemeinsam festgelegt, Mockup abgenommen, programmiert (KI folgt)
---

# Main Feed

Die Startseite der App (Idee von Phillip, 2026-10-12). Der App-Aufbau:

1. **[[Täglicher Check-in]]**: die 4 Fragen und die KI-Antwort, jeden Tag. Kommt beim ersten Öffnen am Tag automatisch.
2. **Main Feed**: öffnet sich nach dem Check-in, individuell für den Tag, mit Graphen, Texten und weiteren Möglichkeiten. Ziel (Phillip): Die App bietet alles für die Veränderung, ohne dass man eine andere App braucht.

Mockup, von Phillip abgenommen („Sehr gut erstmal“, 2026-10-12): https://claude.ai/artifact/NF3AXG3cv8AM6Qy7wrn4xm

## Aufbau: Seiten mit Leiste unten

Nicht alles auf eine Seite (Phillip, 2026-10-12): Unten ist eine Leiste mit 5 Seiten. Jeder Bereich hat seine eigene Seite und folgt dem gleichen Muster: **Graph**, **etwas einmal Festgelegtes bzw. Hilfen**, **ein Schreibfeld für den Coach**.

| Seite | Inhalt |
|---|---|
| **Heute** | Datum, Coach-Antwort zum Check-in, Fokus der Woche, alle 4 Bereiche auf einen Blick (antippen öffnet die Seite), Deine Muster |
| **Training** | Verlauf, eigener Trainingsplan mit Wochenübersicht (heute hervorgehoben), Feld „Wie war dein Training?“ |
| **Ernährung** | Verlauf, kcal-Ziel, Feld „Wie sieht deine Ernährung heute aus?“, Gewicht mit Wochenschnitt |
| **Schlaf** | Verlauf, Abendroutine, Feld „Frag zu deinem Schlaf“ |
| **Mindset** | Verlauf, Durchgezogen, Dein Warum, Feld „Wovor drückst du dich gerade?“ |

## Beschlüsse (alle 2026-10-12, gemeinsam mit Phillip)

- **Graphen für alle 4 Bereiche**, um Veränderung und Fortschritt festzuhalten. Die KI bewertet jeden Bereich täglich aus den Check-in-Antworten, ohne Mehraufwand für den Nutzer.
- **Fokus der Woche, Deine Muster, Dein Warum, Durchgezogen** kommen alle rein. Dein Warum (die Motivation aus dem Onboarding) erscheint nur in schwachen Phasen, Durchgezogen sammelt die KI aus den Mindset-Antworten.
- **Trainingsplan** (Idee von Phillip): einmal in eigenen Worten pro Wochentag festgelegt und gespeichert, jede Sportart (Gym, Laufen, Radfahren, Kampfsport …), keine Übungsdatenbank. Im Feed die Woche mit dem heutigen Tag hervorgehoben. Schafft der Nutzer nicht alles (zu kaputt, wenig Zeit), gibt die KI Empfehlungen zum Plan. Gespeichert in [[Trainingsplan]].
- **kcal-Ziel** (Idee von Phillip): wird angezeigt, ohne Zählen und ohne Tagesbilanz. Grundlage sind Größe, Alter, Geschlecht und Aktivität im Alltag (einmal angegeben) plus das Gewicht und das Ziel aus dem Onboarding. Es passt sich mit jedem neuen Gewicht an. Eingerichtet wird es im Feed. Gespeichert in [[kcal-Profil]].
- **Ernährungs-Einschätzung**: Bei Interesse schreibt der Nutzer grob, wie seine Ernährung heute aussieht. Die KI schätzt das passend zum kcal-Ziel ein (gut, zu wenig, geht noch was) und gibt z. B. einen Tipp für ein Gericht.
- **Gewicht** ist fest dabei und wird immer wieder neu eingetragen, siehe [[Gewicht]]. Wochenschnitt statt Tageswert, getrennt vom [[Fortschritts-Verlauf]].
- **Abendroutine**: einmal festgelegt wie der Trainingsplan. Die KI arbeitet damit und passt sie an, wenn Schlafprobleme öfter auftreten. Gespeichert in [[Abendroutine]].
- **Schreibfelder** in allen 4 Bereichen: Der Nutzer schreibt, der Coach antwortet individuell. Gespeichert in [[Coach-Fragen]].

Zum kcal-Ziel: Die [[App-Gesamtübersicht (Original)|Gesamtübersicht]] sagt „Kein Kalorien- oder Makro-Zählen“. Das bleibt so: Es wird nichts gezählt, das Ziel dient nur als Orientierung für die Einschätzung der KI.

## Stand im Code (2026-10-12)

- Die 5 Seiten mit der Leiste unten sind programmiert.
- **Funktioniert und wird gespeichert:** Trainingsplan, Abendroutine, kcal-Ziel (mit erstem Gewicht, falls noch keins da ist), Gewicht, alles was in die Schreibfelder geschrieben wird.
- **kcal-Ziel bis zur KI:** berechnet nach Mifflin-St Jeor mal Aktivitätsfaktor (1,2 / 1,375 / 1,55 / 1,725), auf 50 kcal gerundet. Das ist der Bedarf, um das Gewicht zu halten. Die Anpassung an das Ziel aus dem Onboarding übernimmt die KI.
- **Platzhalter bis zur KI:** Antworten in den Schreibfeldern, die Graphen der 4 Bereiche, Fokus der Woche, Deine Muster, Durchgezogen. Dein Warum wird bis dahin immer gezeigt, mit Hinweis.
- Unten auf „Heute“: „Fragebogen neu starten“, nur zum Testen.

Farben und Stil sind Platzhalter; das Design kommt als eigener Schritt mit Name und Branding (siehe [[Roadmap nach dem MVP]]).
