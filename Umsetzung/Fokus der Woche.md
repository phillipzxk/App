---
title: Fokus der Woche
tags: [umsetzung, feed, ki]
status: gebaut
---

# Fokus der Woche

Ein einziger Schwerpunkt für 7 Tage auf „Heute“ in der Karte „Deine Woche“. Siehe [[Main Feed]], [[Bereichs-Werte]] und [[Deine Muster]].

## Entscheidungen (mit Phillip, 20.10.2026)

| Frage | Entscheidung |
|---|---|
| Wer legt den Fokus fest? | **Der Coach schlägt 3 vor, die Person wählt einen.** Die Vorschläge passen zu den Werten und Mustern. Beim allerersten Mal kommen sie aus dem Onboarding. So bleibt die Entscheidung bei der Person ([[Kern der App]]: selbstständig werden). |
| Wann startet die Woche? | **Ab dem Tag der Wahl**, 7 Tage lang, egal welcher Wochentag. Phillip: „ab dem ersten Tag ist doch besser“. Man muss nicht auf Sonntag warten. Die 7 Striche stehen für Tag 1 bis 7. |
| Wie wird abgehakt? | **Auf „Heute“ selbst tippen** („Heute geschafft“). Der Check-in bleibt bei 5 Fragen. Nochmal tippen nimmt es zurück. |
| Was passiert nach 7 Tagen? | **Rückblick + neu:** Der Coach sagt in einem Satz, wie die Woche lief (z. B. 5 von 7). Dann kommen 3 neue Vorschläge. Den alten Fokus kann man behalten. |

## Entwurf

Bild im Projektordner: `ki-coach/fokus-entwurf.png`. Phillip hat am 20.10. Ja gesagt.

## So ist es gebaut

- Der Coach-Server hat die Route `/fokus`: 3 Vorschläge mit je einem kurzen „warum“. Nach einer Woche ist einer davon der alte Fokus („Behalten“), dazu ein Satz Rückblick.
- Die Vorschläge werden gespeichert, bis die Person einen wählt, damit der Coach nicht bei jedem Öffnen neu gefragt wird.
- „Behalten“ startet eine neue Woche mit demselben Text, die Striche beginnen wieder bei Tag 1.
- „Tage am Stück“ ist jetzt eine eigene kleine Karte unter dem Fokus.
- Bild aus der App: `ki-coach/fokus-app.png`.
