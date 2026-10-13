---
title: Offene Fragen
tags: [offen, entscheidungen]
aktualisiert: 2026-10-10
---

# Offene Fragen

## Widersprüche in den Unterlagen

- ~~**Preis:**~~ **Entschieden** laut [[App-Gesamtübersicht (Original)]]: reines Flatrate-Abo mit weicher Begrenzung, vorerst 9,99 €/Monat.
- ~~**Vier Fragen vs. drei Felder?**~~ **Entschieden 2026-10-12:** 4 Fragen und 4 Felder (Training, Ernährung, Schlaf, Mindset), Energie wird bei Schlaf oder Mindset mit abgefragt. Siehe [[Täglicher Check-in]].

## Onboarding

Aus dem Entwurf [[Onboarding-Fragebogen]] (2026-10-10):

- ~~Zwei neue Felder in [[Nutzer]]?~~ **Entschieden 2026-10-10: ja.** Seit dem 2026-10-11 ersetzt durch die sechs Freitext-Felder der neuen Fragen und `zusammenfassung`, siehe [[Datenmodell]].
- **KI-Schlüssel:** Für die Zusammenfassung „So sehe ich dich gerade“ braucht es einen API-Schlüssel von Anthropic (console.anthropic.com). Phillip legt ihn an; er kommt ins Backend, nicht in die App.
- **Backend:** Die App speichert die Antworten vorerst nur auf dem Gerät. Für Anmeldung und Online-Speicherung ist **Firebase** vorgeschlagen; dafür braucht es ein Firebase-Projekt in Phillips Google-Konto (siehe [[Technischer Ansatz]]). Noch nicht festgelegt.
- **Antworten später ändern:** Soll es eine Profil-Seite geben, auf der die Onboarding-Antworten angepasst werden können? Im MVP bisher nicht vorgesehen.

## Laut Konzept später zu klären

- Monetarisierung im Detail: was ist kostenlos, was kostenpflichtig (vgl. Antwort-Typ in [[KI-Antworten]])
- Erinnerungen/Notifications für tägliches Tracking
- Datenschutz / Datenschutzerklärung
- ~~Name und Branding der App~~ **Entschieden 2026-10-13:** Groundset, siehe [[Design]] (Logo noch offen)
- Verbindung zu Buch und Content
- Mögliche Community-Elemente

## Technik

- **Bewertungs-Richtung:** Heißt 10 „brauchte kaum Tipps“? Laut [[App-Gesamtübersicht (Original)]] noch von Phillip zu bestätigen.
- ~~FlutterFlow oder Code?~~ **Entschieden 2026-10-11:** Code von Claude. Das FlutterFlow-Projekt „Betterlifeapp“ ruht.

- Welcher LLM-Anbieter bzw. welches Modell? (siehe [[Technischer Ansatz]])
- Wie die „einfache Regellogik“ der KI-Antwort im MVP konkret aussieht
- Wie die Bewertungs-Kennzahl (1–10) genau berechnet wird (siehe [[Fortschritts-Verlauf]])
