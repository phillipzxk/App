---
thema: Apple Health
stand: 2026-11-01
status: beschlossen
tags: [umsetzung, handy-version, schlaf]
---

# Apple Health

Vierter Schritt der Handy-Version nach [[Konto und Sicherung]], [[Erinnerungen]] und [[Echter Wecker]]. Löst „Mehr Daten“ aus [[Schlaf und Energie komplett]] ein.

- Entwurf 1 (Inhalt): https://claude.ai/artifact/A5qgWVYXvAURbxEMtsaPFy, Phillip 2026-11-01: „jo aber anders designen“, alle 4 goldenen Vorschläge rein.
- Entwurf 2 (Design „deine Nacht als Wurzeln“): https://claude.ai/artifact/3rqEZHhMQoWCScm9UeEbGa, Phillip 2026-11-01 17:28: „OK“.

## Was die App liest und wofür

| Aus Apple Health | Wofür in Groundset |
|---|---|
| Schlaf (Dauer, Phasen, Wachzeiten) | Schlafwert: Länge, Durchschlafen, Rhythmus. Schlaf-Mond. Bettzeit eingehalten? |
| Ruhepuls, Herzfrequenzvariabilität | Schlafwert-Teil „Erholung“, Energie, Coach passt Training an |
| Trainings von der Uhr | Feld „Von deiner Uhr: … Übernehmen“, Check-in „Gut trainiert“ vorausgefüllt |
| Gewicht (z. B. Waage) | Gewichts-Tracker füllt sich selbst |
| Schritte | „30 Schritte“ beim Wecker, Energie |
| Zeit bei Tageslicht (Apple Watch) | Sonnenlicht-Ziel hakt sich selbst ab |

## Regeln

- Groundset **liest nur**, schreibt nichts in Apple Health. Jede Art lässt sich in Apples Abfrage einzeln aus lassen.
- Was der Nutzer selbst einträgt, gilt immer vor dem, was das Handy misst. Der Aufwach-Himmel zählt bei „Erholung“ weiter mit.
- Daten bleiben auf dem Handy und in der verschlüsselten Sicherung (Frankfurt).
- Google Health Connect (Android) kommt später mit der Android-Version.

## Design „deine Nacht als Wurzeln“

1. **Verbinden** (Schlaf-Seite „Mehr Daten“ und Einstellungen): Ein Herzschlag läuft vom Apple-Health-Herz durch einen goldenen Stamm unter die Bodenlinie, dann leuchten 7 Wurzeln nacheinander auf: Schlaf, Puls, HRV, Trainings, Gewicht, Schritte, Tageslicht.
2. **Apples Abfrage**: zeichnet Apple, nicht gestaltbar.
3. **Deine Nacht**: Schlafwert zählt hoch, Mond. Die Nacht läuft links (eingeschlafen) nach rechts (aufgewacht). Die goldene Wurzel geht so tief, wie man geschlafen hat (REM oben, Kern Mitte, Tief unten). Wo man wach war, wächst ein kleiner Trieb über den Boden („wach“). Darunter die 4 Teile als Glasfeld: Länge, Erholung, Durchschlafen, Rhythmus.
4. **Coach und Heute**: Messwerte fallen als goldene Samen in die Coach-Karte, der Coach schreibt seinen Satz. Darunter erscheinen Glasfelder nur, wenn etwas Neues gemessen wurde: Training von der Uhr („Übernehmen“), Gewicht von der Waage, Tageslicht-Minuten.

## Stand im Code (2026-11-01)

- `code/lib/health/`: Daten (`health_daten.dart`), Lesen (`health_dienst.dart`: iPhone über `AppDelegate.swift` mit HealthKit, Vorschau im Browser mit Beispielwerten aus Entwurf 2), Logik (`health_logik.dart`), Verbinden-Seite mit Herzschlag und 7 Wurzeln (`health_verbinden.dart`), Nacht als Wurzel (`nacht_wurzel.dart`), Samen und Felder auf Heute (`health_heute.dart`).
- Verbinden: Schlaf & Energie unter „Mehr Daten für deinen Schlafwert“ und in „Konto und Sicherung“ unter „Apple Health“.
- Schlafwert: gemessene Länge (wenn nicht selbst geändert), Erholung = halb Aufwach-Himmel, halb Ruhepuls und HRV gegen den eigenen 30-Tage-Schnitt, Durchschlafen aus den Wachphasen (eigene Angabe wie „Einmal wach“ zählt zuerst), Rhythmus aus dem gemessenen Einschlafen gegen die Bettzeit.
- Coach: Messwerte gehen mit dem Check-in an den Coach (Feld `messwerte`) und in alle Schlaf-Fragen. Regel im Coach-Prompt: Was die Person selbst sagt, zählt zuerst, aus Puls oder HRV keine Krankheit.
- Heute: Samen fallen einmal am Tag in die Coach-Karte. Felder darunter: Uhr-Training „Übernehmen“ (zählt als Training des Tages, Check-in schlägt „Gut trainiert“ vor), Gewicht von der Waage geht automatisch in den Verlauf (außer es gibt für den Tag schon einen eigenen Eintrag), Tageslicht-Minuten. Sonnenlicht-Karte hakt sich ab 5 gemessenen Minuten selbst ab.
- Daten bleiben auf dem Handy (letzte 14 Tage) und kommen mit in die Sicherung.

## Noch offen

- Echt testen geht erst auf dem iPhone mit Apple-Entwicklerkonto (TestFlight).
- „30 Schritte“ beim Wecker zählt noch per Tippen. Echte Schritte live zu zählen braucht den Bewegungssensor, nicht Apple Health (später).
- Google Health Connect mit der Android-Version.
