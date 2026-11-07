---
tags: [umsetzung, business]
status: gestrichen
---

# Business & Beruf komplett

> **Gestrichen am 2026-11-04.** Phillip („Okay ja machen wir so“) auf Claudes Vorschlag: Business ist kein eigener Bereich mehr, weil die meisten Nutzer kein Business haben, es den Kern (Körper und Kopf zusammen) verwässert und das Wichtige schon in Produktivität steckt. Hebel der Woche, Meilensteine („Dein Weg zum Ziel“) und Skill-Leiter leben als Seite „Ziele“ in [[Produktivität und Fokus komplett|Fokus & Arbeit]] weiter, für Job, Studium, Schule oder eigene Firma. Umsatz-Ziel, Spar-Plan, Stundenwert, Mutige Anfrage, Erster Euro, Brainstorming, Ideen-Prüfer, Gesprächs-Hilfe und Arbeit & Körper sind nicht mehr in der App. Der Rest dieser Notiz ist Geschichte.

Inhalte siehe [[Ideen neue Bereiche]] (Auswahl 2026-10-28, Punkte 1–14). Aufbau wie [[Mindset komplett]] Entwurf 7 und [[Produktivität und Fokus komplett]].

## Entwurf 1 (2026-10-29)

**Entschieden 2026-10-29 16:46:** Phillip „jo passt“. Kommt mit den anderen Bereichsseiten zusammen in den Code-Bau.

Link: https://claude.ai/artifact/PLyMQAoKjNUVTwuJx4Nvcq

Kopf: Kreis 6, „+2 in 3 Monaten · Hebel läuft“. Vier Seiten, je drei Felder, ein Coach-Satz pro Seite (Aufteilung = Vorschlag Claude):

- **Woche:** Hebel der Woche (eine Aktion, abhaken, 3 Tipps vom Coach), Mutige Anfrage (Liste, jede geschaffte lässt ein Blatt wachsen), Der erste Euro (kleinste verkaufbare Version, Schritte, „Der erste Euro ist da“).
- **Ziele:** Umsatz-Ziel (Ring, Eingang eintragen, bei Ziel ganz großes goldenes Häkchen über den Bildschirm), Spar-Plan (Spar-Ziel, „Lohnt sich das?“, Tipps zum Mehr-Sparen), Stundenwert (pro Tätigkeit, Coach sagt worauf konzentrieren).
- **Ideen:** Brainstorming mit Gedanken-Ablage (Kernideen gold, „Mit dem Coach ausarbeiten“ macht Ziel + Plan vom Anfang bis zum Ende), Ideen-Prüfer (harte Fragen, Reife in Prozent), Gesprächs-Hilfe (Leitfaden + Antworten auf Einwände).
- **Wachstum:** Business-Baum (Meilensteine = Äste, nächster als leuchtende Knospe), Skill-Leiter (7 Stufen linear), Arbeit & Körper (Arbeit an Trainings- und Schlaftagen).
- Woche im Business läuft im Reality Check mit.

## Stand im Code (2026-10-29)
- Gebaut in PR #64 (Teil 4): `code/lib/home/business_seite.dart`, Felder in `code/lib/business/`, Coach-Route `/business`. Auf der Startseite eigene Wurzel „Business & Beruf“.
- Hebel: Coach schlägt einen vor (mit Schritten und 3 Tipps) oder man legt ihn selbst fest.
- Umsatz-Ziel, Spar-Ziel und Business-Baum: beim Erreichen das große goldene Häkchen über den Bildschirm. Der erste Euro zählt als Eingang mit.
- Ideen-Prüfer: ohne Coach 4 feste harte Fragen. Reife bis zur Antwort des Coachs = Anteil beantworteter Fragen (höchstens 60 %).
- Arbeit & Körper vergleicht den Produktivitäts-Wert an Tagen mit und ohne Training (aus dem Check-in) und nach Nächten unter 7 Stunden, je ab 3 Tagen.
- Business-Wert, Regel von Claude: Schritte des Hebels, Umsatz gegen das Monatsziel bis heute, mutige Anfragen der Woche.

## Rundgang 2026-10-31

- Überschrift wie auf der Startseite „Business & Beruf“.
- Coach-Frage ohne Hebel: „Welche Aktion bringt dich diese Woche am weitesten?“
- Mutige Anfrage bei 0: nur ein Samenkorn im Boden statt eines kahlen Stiels.
