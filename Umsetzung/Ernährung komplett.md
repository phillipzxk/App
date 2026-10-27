---
tags: [umsetzung, ernährung]
status: entwurf
stand: 2026-10-27
---

# Ernährung komplett

Verbesserung der Ernährungsseite, gemeinsam mit Phillip. Grundregel bleibt: **kein Zählen** (siehe [[App-Gesamtübersicht (Original)]], [[Coach-Stil]]).

## Entscheidungen (2026-10-27)

Claude hat 7 eigene Ideen vorgeschlagen, Phillip: „Ja alle“. Dazu wollte er Einkaufsliste mit den Gerichten, einen kcal-Tipp vom Coach, wenn es falsch läuft, und Beispiel-Gerichte zum Nachmachen.

1. **Deine Mahlzeiten heute**: Anzahl einmal festlegen, Coach legt sie passend zu Training und Terminen in den Tag (Größe in Worten + Tipp). Nach dem Essen „gegessen“ + satt / okay / noch Hunger.
2. **Heißhunger-Knopf**: Coach fragt kurz nach (Echter Hunger, Stress, Langeweile, Müde, Gewohnheit) und gibt einen Schritt für jetzt. Uhrzeit und Grund werden gespeichert (14 Tage, Uhrzeiten).
3. **Teller-Foto**: Coach sagt grob Eiweiß, Gemüse, Größe in Worten + ein Tipp. Keine Zahlen, „Hinweise“, keine Messung.
4. **Deine Basis-Gerichte**: 3 bis 5 eigene Gerichte mit Zutaten. Coach schlägt an schwierigen Tagen eins vor.
5. **Zum Nachmachen**: Coach schlägt wenige Beispiel-Gerichte passend zu Ziel und Tag vor (Zutaten für 1 Portion, Schritte, warum für dich). „Zu meinen Gerichten“ und „Auf die Einkaufsliste“.
6. **Einkaufsliste**: Gerichte der Woche mit Anzahl wählen, Zutaten sortiert und zusammengezählt, abhaken, eigene Sachen dazu.
7. **Gewichts-Check**: Bewegt sich das Gewicht 3 Wochen nicht passend zum Ziel (oder zu schnell), fragt der Coach zuerst, dann neues kcal-Ziel vorschlagen, Übernehmen / So lassen, Rückgängig.
8. **Zusammenhang**: Ein Coach-Satz oben, wie Essen mit Schlaf, Training und Kopf zusammenhängt, nur wenn sichtbar.

Heute bleibt unverändert.

## Änderung 2026-10-27 18:16: Mahlzeiten und Gerichte besonderer

Phillip fand Mahlzeiten und Gerichte in Entwurf 1 „bissle langweilig“. Claudes eigene Ideen A bis E, Phillip: „Ja genauso alles übernehmen“.

- **A Energie-Kurve**: Kurve der voraussichtlichen Energie über den Tag (Schlaf, Training, Mahlzeiten). Mahlzeiten sind Punkte darauf, ziehen verschiebt sie, die Kurve ändert sich live, der Coach erklärt (z. B. Snack vor dem Training).
- **B Dein Teller heute**: ein Teller für den ganzen Tag, füllt sich mit jeder Mahlzeit in Eiweiß, Gemüse, Energie, in Worten. Abends sagt der Coach, was gefehlt hat.
- **C Kühlschrank-Foto**: Coach erkennt Zutaten (falsche antippbar) und baut ein Gericht, das zu heute passt.
- **D Rettungsgerichte**: Gerichte vom Coach, jedes gegen ein Muster des Nutzers (z. B. 21-Uhr-Heißhunger, späte Trainingstage). Ersetzt „Zum Nachmachen“ als Rezeptliste.
- **E Dein Kochbuch wächst**: Jedes gekochte und bewertete Gericht wird ein Blatt am Baum. Sitzt ein Gericht, schaltet der Coach ein neues frei. Mit 7 Blättern eigene Variante (selbstständig). Bewertung lecker / geht so / nicht meins.

## Entwurf

Entwurf 1 (7 Ansichten) und Entwurf 2 (8 Ansichten, mit A bis E) unter https://claude.ai/artifact/PLDQAye87MMzCvfLxTyaS3 — Entwurf 2 freigegeben von Phillip („Jo passt“, 2026-10-27).

## Stand im Code (2026-10-27)

- Ordner `code/lib/ernaehrung/`: Daten (`ernaehrung_data.dart`), Logik (`ernaehrung_logik.dart`: Mahlzeiten um das Training legen, Energie-Kurve, Teller, Einkaufsliste, Kochbuch, Gewichts-Check), Coach-Anbindung und alle Unterseiten (Heißhunger, Teller-Foto, Kochbuch, Gericht, Kühlschrank, Einkaufsliste, Gewichts-Check).
- Die Ernährungsseite selbst: `code/lib/home/nutrition_tab.dart`.
- Coach im Worker: Route `/ernaehrung` mit den Teilen zusammenhang, heisshunger, teller, kuehlschrank, rettung, gewicht.
- Die Mahlzeiten im Tagesplan („Dein Tag“, Sonnenbogen) kommen jetzt aus derselben Planung wie auf der Ernährungsseite, mit Namen (Frühstück, Vor dem Training …) und Haken, wenn gegessen.
- Das kcal-Ziel enthält die Änderung aus dem Gewichts-Check (rückgängig machbar).
- Alles wird auf dem Gerät gespeichert. Fotos vom Teller werden nach 7 Tagen entfernt, damit der Speicher klein bleibt (die Hinweise bleiben). Server-Backup kommt mit der Handy-Version.
- Ohne Coach (offline) gibt es feste Antworten und 3 eingebaute Rettungsgerichte.
