---
tags: [umsetzung, persoenlichkeit]
status: entschieden
---

# Persönlichkeit komplett

Inhalte siehe [[Ideen neue Bereiche]] (Auswahl 2026-10-28). Aufbau wie [[Mindset komplett]] Entwurf 7.

## Entwurf 1 (2026-10-29)

**Entschieden 2026-10-29 16:54:** Phillip „passt“. Kommt mit den anderen Bereichsseiten zusammen in den Code-Bau.

Link: https://claude.ai/artifact/QxiAuqb88EsD8pYKkzj1w3

Kopf: Kreis 7, „+1 zu gestern · Routine gehalten“. Vier Seiten (Aufteilung = Vorschlag Claude):

- **Heute:** Pflege-Routine (morgens 3, abends 2 Schritte abhaken, Tage am Stück), Lern-Ziel (10 Minuten, Lektion des Skills, kurze Frage vom Coach öffnet die nächste Lektion), Stimme aufnehmen (Tempo, Füllwörter, Sicherheit).
- **Look:** Look-Analyse vom Foto (keine Punktzahl, nur 3 Hebel), Stil-Check (Outfit-Foto, Passt/Ändern, Farben die dir stehen), Haltung (aus dem Foto, Übungen landen im Training), Look-Verlauf (Woche 1 vs. jetzt, mit dem Fortschrittsfoto).
- **Pflege:** Haut-Plan über 8 Wochen (bei echten Problemen: Hautarzt), Frisur-Berater (Text für den Friseur, Styling), Die kleinen Dinge (Zahnseide, Nägel, Brauen, Duft).
- **Wissen:** Dein Skill als linearer Kurs (12 Lektionen, nächste öffnet nach der Frage), Deine Bibliothek (Coach fragt ab), Wissen umsetzen (aus Buch/Podcast ein kleiner Schritt).

Kamera und Mikrofon erst in der Handy-Version.

## Stand im Code (2026-10-29)
- Gebaut in PR #64 (Teil 5): `code/lib/home/persoenlich_seite.dart`, Felder in `code/lib/persoenlich/`, Coach-Route `/persoenlich`. Auf der Startseite eigene Wurzel „Persönlichkeit“.
- Pflege-Routine: Start morgens Gesicht waschen, Feuchtigkeitscreme, Sonnenschutz; abends Gesicht reinigen, Nachtcreme. Schritte lassen sich ändern.
- Kurs: Coach baut 12 Lektionen, jede Lektion mit Text und einer Frage. Erst die richtige Antwort öffnet die nächste. Das Lern-Ziel zählt die 10 Minuten mit einer Uhr.
- Look, Stil und Haltung gehen über ein Foto (in der Vorschau die Datei-Auswahl). Die Haltungs-Übungen kommen auf Knopfdruck an alle Trainingstage im Plan.
- Look-Verlauf zeigt das erste und das neueste Fortschrittsfoto.
- Stimme: das Feld ist da, die Aufnahme kommt mit der Handy-Version.
- Persönlichkeits-Wert, Regel von Claude: Schritte der Pflege-Routine und die 10 Minuten Lernen.
