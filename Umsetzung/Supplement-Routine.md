---
title: Supplement-Routine
tags: [umsetzung, ernaehrung, erinnerung, teilweise-gebaut]
erstellt: 2026-10-16
aktualisiert: 2026-10-16
---

# Supplement-Routine

Idee von Phillip (2026-10-16): Auf der Seite Ernährung im [[Main Feed]] legt jeder eine eigene Supplement-Routine fest, mit fester Uhrzeit, und die App erinnert daran, damit man nichts vergisst. Gebaut bis auf die Erinnerungen (siehe „Stand im Code“).

## Festgelegt

| Punkt | Entscheidung | Datum |
|---|---|---|
| Darf die KI Tipps zu Supplements geben? | **Nur eintragen.** Der Nutzer legt alles selbst fest (was, wie viel, wann). Die App erinnert nur, die KI empfiehlt keine Mittel und keine Mengen. Passt zur Regel aus [[Coach-Stil]]: keine unsicheren medizinischen Tipps, stattdessen „frag deinen Arzt“. | 2026-10-16 |
| Feld auf „Heute“ | **Neu 19.10.2026 (Phillip):** Das Feld erscheint nur, solange heute noch etwas abzuhaken ist. Ohne Routine oder wenn alles genommen ist, fehlt es. Die Routine gehört zu Ernährung und wird dort eingerichtet. | 2026-10-19 |
| ~~Feld auch ohne Routine?~~ | ~~**Immer zeigen.** Ohne Routine steht dort „Supplements · Routine festlegen ›“ und führt zur Seite Ernährung, damit jeder die Funktion findet (Phillip).~~ Ersetzt am 19.10. | 2026-10-17 |
| Auch auf „Heute“? | **Nur ein kleines Feld als Erinnerung**, damit die Startseite nicht überladen wird (Phillip, ersetzt das frühere „Auch im Tagesplan“). Das Feld zeigt, wie viele Einnahmen offen sind und welche als Nächstes dran ist. Tippen führt zur Seite Ernährung. Nicht im Tagesplan „Dein Tag“. | 2026-10-16 |
| Abhaken? | **Ja, auf der Seite Ernährung.** Dort steht die ganze Routine, man tippt auf den Kreis. Abgehakte Einnahmen werden grau und durchgestrichen, oben steht „heute X von N“. | 2026-10-16 |
| Was pro Einnahme? | Uhrzeit, Name und Menge (in eigenen Worten), standardmäßig täglich. | 2026-10-16 |

## Entwurf

- Seite Ernährung und Tagesplan mit Abhaken (Beispiel Max, 2026-10-16): https://claude.ai/artifact/5sRe3bkZzSc1RTesbu9R1Y. Version 2 mit kleinem Feld auf „Heute“; Phillip hat Ja gesagt.

## Stand im Code

- Seite Ernährung: Karte „Deine Supplement-Routine“ nach dem kcal-Ziel. Leer: „Routine festlegen“. Danach jede Einnahme mit Uhrzeit, Name, Menge und Kreis zum Abhaken, „heute X von N“, „Routine ändern“ und der Hinweis „Bei Fragen zu Mitteln oder Mengen: frag deinen Arzt.“
- Eingabe: Zeilen mit Uhrzeit, Was, Menge. Kurze Uhrzeiten wie „8“ oder „8.30“ werden zu 08:00 und 08:30.
- „Heute“ (seit 19.10.2026): Feld nur, solange etwas offen ist, z. B. „Supplements · 2 offen, nächste 21:30 Magnesium ›“. Früher: kleines Feld nach der Coach-Antwort, immer sichtbar. Ohne Routine: „Supplements · Routine festlegen ›“. Mit Routine: „Supplements · 2 offen, nächste 21:30 Magnesium ›“ oder „heute alles genommen“. Tippen öffnet die Seite Ernährung.
- Gespeichert wird nur auf dem Handy; Häkchen gelten für den jeweiligen Tag.
- Fehlt noch: Erinnerungen (Handy-Version).

## Hinweis

- Erinnerungen per Benachrichtigung laufen erst in der Handy-Version der App, wie beim [[Tages-Planer]].
