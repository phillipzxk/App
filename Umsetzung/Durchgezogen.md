---
title: Durchgezogen
tags: [umsetzung, feed, mindset, ki]
status: gebaut
---

# Durchgezogen

Karte auf der Seite Mindset im [[Main Feed]]: was die Person trotz Unlust gemacht hat. Mindset heißt in der App, Dinge durchzuziehen, vor denen man sich drückt. Siehe auch [[Fokus der Woche]] und [[Deine Muster]].

## Entscheidungen (mit Phillip, 21.10.2026)

| Frage | Entscheidung |
|---|---|
| Was zeigt die Karte? | **Woche + Sammlung.** Oben die aktuelle Woche (ab Montag) mit Anzahl und Vergleich zur Vorwoche, darunter „Alle ansehen“ mit allem seit dem Start, nach Wochen gruppiert. |
| Wie kommen die Einträge rein? | **Coach + selbst.** Der Coach trägt nach dem Check-in ein, was durchgezogen wurde (aus Check-in, Notiz und Fokus der Woche). Die Person kann selbst etwas dazuschreiben und jeden Eintrag löschen. |

## Entwurf

Bild im Projektordner: `ki-coach/durchgezogen-entwurf.png`. Vorschlag von Claude: höchstens ein Coach-Eintrag pro Tag, und nur wenn wirklich etwas durchgezogen wurde. Jeder Eintrag zeigt, ob er vom Coach oder von der Person kommt. Phillip hat den Vorschlag am 21.10.2026 übernommen („Ja übernehmen“).

## So ist es gebaut

- **Karte auf Mindset:** „Durchgezogen · diese Woche“ mit „N Mal seit Montag · letzte Woche M“, den Einträgen der Woche (Wochentag, Text, Schild COACH oder DU), einem Feld „Was hast du durchgezogen?“ mit „Eintragen“ und „Alle ansehen ›“.
- **Alle ansehen:** eigene Seite „Durchgezogen“, nach Wochen gruppiert (neueste oben, „Diese Woche“, sonst z. B. „12. bis 18. Okt“) mit Anzahl pro Woche. Mit ✕ wird ein Eintrag gelöscht.
- **Coach:** einmal am Tag nach dem Check-in fragt die App den Coach (Route `/durchgezogen`). Er bekommt Check-in, Notiz, den laufenden Fokus der Woche und die letzten Einträge. Nur wenn klar etwas trotz Unlust gemacht wurde, kommt ein Satz in Du-Form zurück (höchstens 14 Wörter), sonst nichts.
- **Gespeichert** auf dem Gerät (`durchgezogen`, `durchgezogen_geprueft`).
- Bild der fertigen App: `ki-coach/durchgezogen-app.png`.
