---
title: Dein Warum
tags: [umsetzung, feed, mindset, ki]
status: gebaut
---

# Dein Warum

Die Motivation aus dem Onboarding (Frage 2) kommt in schwachen Phasen zurück. Hängt mit [[Main Feed]], [[Coach-Stil]] und [[Home-Schichten]] zusammen.

## Entscheidungen (mit Phillip, 24.10.2026)

| Frage | Entscheidung |
|---|---|
| Wann ist eine schwache Phase? | **Der Coach entscheidet** nach jedem Check-in, ob man gerade durchhängt. |
| Wo erscheint es? | **Kleine Karte auf Heute** unter der Coach-Karte, nur an solchen Tagen. |
| Was steht drauf? | Dein Warum in deinen eigenen Worten **plus ein Coach-Satz**, der es mit dem schwachen Moment heute verbindet. |
| Mindset-Seite | Die Karte „Dein Warum“ **bleibt dort immer** stehen. |

## Entwurf (25.10.2026)

Phillip hat den Entwurf am 25.10.2026 mit „Ja“ freigegeben: https://claude.ai/artifact/7cdvnU9jaWnZ4W5x43GNf7

- Goldumrandete dunkle Karte direkt **unter der Coach-Karte** auf Heute, gleitet sanft herein.
- Oben „DEIN WARUM“ mit Herz, darunter die eigenen Worte aus Frage 2 als Zitat.
- Unter einer feinen Goldlinie ein Satz vom Coach mit kleinem Nasenaffen-Bild.
- An normalen Tagen fehlt die Karte. Auf der Mindset-Seite steht „Dein Warum“ immer (unter „Deine Basis“).

## So läuft es im Code

- Einmal am Tag nach dem Check-in fragt die App den Coach (Worker-Route `/warum`, mit dem Check-in von heute und den letzten Tagen).
- Der Coach antwortet mit einem Satz (höchstens 22 Wörter) oder mit nichts, wenn es ein normaler Tag ist. Ein einzelner mittlerer Tag zählt nicht.
- Das Ergebnis wird für den Tag gespeichert (`warum_heute`), damit der Coach nicht mehrmals gefragt wird.
- Ohne Antwort auf Frage 2 gibt es keine Karte.

## Reparatur 2026-10-31

Beim Rundgang stand in der Karte wörtlich „Was ist dein wahrer Grund?:“ mitten im Zitat. Jetzt zeigt die Karte die eigenen Worte aus dem Feld, und nur wenn das Feld leer ist, die angetippten Antworten.

## Fragebogen neu machen (2026-10-31)

„Fragebogen neu starten“ ist von der Startseite weg. Der Link „Fragebogen neu machen“ steht jetzt unten auf der Seite „Dein Warum“ (Mindset › Langfristig).
