---
title: Training eintragen
tags: [umsetzung, training, ki, gebaut]
erstellt: 2026-10-26
aktualisiert: 2026-10-26
---

# Training eintragen

Phillip am 2026-10-26: Die Trainingsseite soll echtes Eintragen können. Den Plan mit Übungen legt man einmal an, er läuft automatisch weiter. Jeden Tag steht das heutige Training da. Man trägt pro Übung Gewicht und Wiederholungen ein oder drückt „Überspringen“. Wie es war, kommt aus dem [[Täglicher Check-in|Check-in]], und der Coach passt an. Das **ersetzt** in der [[Hybrid-Engine]] den Punkt „Werte nur aus den eigenen Worten“. Es gibt weiter **keine Übungsdatenbank**, die Namen schreibt man selbst.

## Entwürfe

- Entwurf 1 (die 6 Ideen): https://claude.ai/artifact/VdYqPESmsnc71URxJxurJD
- Entwurf 2 (alles zusammen), Phillip „Perfekt“ am 2026-10-26: https://claude.ai/artifact/SJZUYT9TqfSpMGuDgzy5kR

## Festgelegt

| Was | Entscheidung |
|---|---|
| 1 Letztes Mal + Ziel | Pro Übung stehen „Letztes Mal“ und „Ziel heute“. Die Felder sind schon mit dem Ziel ausgefüllt, man ändert nur, was anders war. |
| 2 Rekorde | Neuer Bestwert: der goldene Spross wächst mit Funken. |
| 3 Überspringen mit Grund | Gründe: Müde, Keine Zeit, Krank, Termin, Etwas anderes. Der Coach verschiebt die Einheit auf den nächsten freien Tag der Woche, bei „Krank“ fällt sie aus (mit „geh zum Arzt“, wenn es nicht besser wird). Immer mit „Rückgängig“. |
| 4 Tagesform | Vor dem Training sagt der Coach aus Schlaf und Energie, ob normal oder leichter. |
| 5 Gefühl pro Übung | leicht, passt, schwer. |
| 6 Selbstständig | Nach dem Training schlägt man das nächste Ziel selbst vor, der Coach bestätigt oder korrigiert. |
| 7 Stagnations-Check | Steht eine Übung 3 Wochen still, fragt der Coach zuerst, woran es liegt (Claudes Idee: erst fragen), dann zeigt er seine Sicht aus den Daten mit einem Vorschlag: „Übernehmen“ oder „So lassen“. |
| 8 Sportarten + Hybrid-Balance | Man wählt seine Sportarten (Krafttraining, Laufen, Radfahren, Schwimmen, Kampfsport, Fußball, Yoga, Klettern, eigene) und den Schwerpunkt (Kraft, Muskelaufbau, Ausdauer, Hybrid). Die App passt sich an (Ausdauer hat Strecke und Zeit statt kg). Die Balance Kraft gegen Ausdauer gibt es **nur, wenn man mehr als eine Sportart gewählt hat** (Phillip). |
| 9 Trainings-Modus | Eine Übung pro Bildschirm, große Zahlen mit −/+, „Satz geschafft“, danach der Pausen-Ring. |
| 10 Form filmen | Pro Übung ein Satz filmen, wird bei der Übung gespeichert. Die KI schaut sich ein paar Standbilder an und gibt **„Hinweise vom Coach“** (Phillip): was gut ist, was besser geht, auf welchem Bild. Vergleich mit dem letzten Video. Keine exakte Analyse, bei Schmerzen „geh zum Arzt“. |
| Coach passt an | Der Coach darf heute Sätze oder Wiederholungen ändern, sagt warum, mit „Rückgängig“. |
| Check-in | Nach dem Training ist im Check-in bei „Training“ die Antwort schon vorgemerkt (Gut trainiert, bei „schwer“ Lief zäh). |

## Einstellungen pro Übung (Plan)

Phillip: „auch Optionen von wie viele Sätze usw., schlau denken“.

- Art: Gewicht, Körpergewicht, Zusatzgewicht, Zeit, Strecke
- Sätze
- Wiederholungen: fest, Bereich (z. B. 6–8) oder „bis kurz vor Schluss“
- Startgewicht (oder Dauer, Strecke)
- Pause: 60, 90, 120, 180 Sekunden
- Aufwärmsätze: 0 bis 3
- Steigern: Coach entscheidet, +2,5 kg, +1 Wdh, Ich selbst
- Jeder Satz anders (z. B. 80 × 8, 85 × 6, 90 × 4)
- Notiz

Claudes Idee: Beim Bereich 6–8 kommt erst mehr Gewicht, wenn alle Sätze 8 schaffen, dann geht es wieder bei 6 los.

## Ansichten

1. Heute trainieren (auf der Trainingsseite)
2. Trainings-Modus
3. Form filmen und Hinweise vom Coach
4. Plan und Sportarten
5. Woche mit Balance und Stagnations-Check
6. Übung im Verlauf: Kurve, Rekorde, Form-Videos, ein Satz vom Coach

Verbunden mit [[Main Feed]], [[Hybrid-Engine]], [[Tages-Planer]], [[Coach-Stil]].

## Stand im Code (2026-10-26)

Gebaut nach Phillips „Perfekt“ zu Entwurf 2:

- Neuer Ordner `code/lib/training/`: Daten (Plan-Übungen mit allen Einstellungen, Einheiten, Sätze, Rekorde), Logik (Ziel für heute, Steigern, Verschieben, Stagnation), Bildschirme (Heute eintragen, Woche, Plan-Editor, Trainings-Modus, Form filmen, Übungs-Verlauf).
- Der Coach-Worker hat die neue Route `/training` (Tagesform, eigener Vorschlag, Stagnations-Check, Balance, Hinweise vom Coach zur Form, Verlaufs-Satz).
- Alles wird auf dem Gerät gespeichert (Plan, jede Einheit, Vorschläge, Form-Bilder). Ein Server-Backup mit Konto kommt mit der Handy-Version, siehe [[Release-Plan]].
- In der Vorschau (Browser) werden vom Video 4 Standbilder gespeichert. Das ganze Video und die Kamera mit goldenem Rahmen kommen mit der Handy-Version.
- Alte Pläne (nur Text) werden automatisch in Übungen umgewandelt.

## Plan im Glas-Look (beschlossen 2026-10-31, Phillip „ja“)

- Der Plan-Editor ist dunkles Glas. Statt sieben Kästen untereinander gibt es die Wochenleiste Mo bis So: Tag antippen, darunter Name und Übungen dieses Tages. Tage mit Training leuchten gold, beim Öffnen ist der heutige Tag gewählt.
- Ohne Plan öffnet „Plan anlegen“ (Kachel „Heute“ und „Dein Plan“ bei Körper › Training) direkt den Plan, ohne Zwischenseite. Speichern führt zurück zu Körper.
