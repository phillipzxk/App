---
tags: [umsetzung, koerper]
status: entschieden
---

# Körper komplett

Körper ist der Einstieg zu den schon gebauten Seiten [[Training eintragen]], [[Ernährung komplett]] und [[Schlaf und Energie komplett]] (Unterbereich heißt jetzt Schlaf & Routine). Aufbau wie [[Mindset komplett]] Entwurf 7.

## Entwurf 1 (2026-10-29)

**Entschieden 2026-10-29 17:00:** Phillip „Passt super“. Frage von ihm: ob das alte Körper-Zeug drin ist. Antwort: Hub zeigt nur Auswahl, die drei fertigen Seiten bleiben komplett und öffnen über „Alles zu … ›“, bekommen beim Einbau den Glas-Look.

Link: https://claude.ai/artifact/9N955p7NjWhuc8p4HtZkzp

Kopf: Kreis 7, „+1 zu gestern · Schlaf zieht mit“. Vier Seiten (Auswahl = Vorschlag Claude), unter den Feldern „Alles zu … ›“ zur ganzen Seite (bekommt den Glas-Look):

- **Training:** Training heute (Übungen abhaken, Trainings-Modus mit Pause), Woche (4 von 5, Hybrid-Balance nur bei 2 Sportarten), Rekord.
- **Ernährung:** Tages-Teller (füllt sich gold, ohne Zahlen, Mahlzeiten heute), Supplements, Gewicht.
- **Schlaf:** Schlafwert mit Mond, Bettzeit mit Abendroutine, Abend-Journal (3 + 3 Pflicht, dann Gute Nacht).
- **Verlauf:** Training, Ernährung und Schlaf zusammen (14 Tage), Fortschrittsfoto, Hängt zusammen.

## Entwurf 2 (2026-10-29): alles schon Gebaute drin

Phillip 17:01: „das von zuvor bitte auch überall mit reinbringen also bei körper und auch falls es iwo anders fehlen sollte“. Gleicher Link wie oben (Version 2). Status: wartet auf sein OK.

„Alles zu … ›“ öffnet jetzt die ganze Seite im Glas-Look (alte Seite sinkt weg, Kreis fliegt neu ein), „‹ Körper“ geht zurück. Jede ganze Seite hat wieder 4 Seiten (Aufteilung = Vorschlag Claude):

- **Training:** Heute (Ziele vorausgefüllt mit „Letztes Mal“, Überspringen mit Grund, leicht/passt/schwer, Coach passt an mit Rückgängig, Aufwärmsätze, Training fertig → Check-in hat „Gut trainiert“, dann schlägt Phillip selbst das nächste Ziel vor), Trainings-Modus, Form filmen (4 Standbilder, Hinweise vom Coach, Vergleich) · Woche (Termin schiebt Einheit, Rückgängig), Hybrid-Balance, Stagnations-Check (fragt zuerst) · Plan (alle Einstellungen pro Übung), Sportarten & Schwerpunkt, Nächstes Ziel selbst · Verlauf (Kurve pro Übung), Rekorde (goldener Trieb), Form-Videos.
- **Ernährung:** Heute (Energie-Kurve mit Mahlzeiten, gegessen + satt/okay/Hunger), Teller, Heißhunger-Knopf · Gerichte (Kochbuch wächst, Rettungsgerichte, Kühlschrank-Foto) · Planen (Einkaufsliste, Basis-Gerichte, Teller-Foto) · Ziel (kcal-Ziel mit Gewichts-Check und „Wie sieht dein Essen heute aus?“, Gewicht, Supplements).
- **Schlaf & Routine:** Morgen (Aufwach-Himmel mit Regler, Sonnenlicht-Timer + Licht-Modus + Winterlampe, Wecker) · Nacht (Schlafwert aus 4 Teilen mit Mond, 14 Nächte, Schlafzeiten/Bettzeit) · Abend (Abend-Journal 3+3 → Gute Nacht, Abendroutine, Ruhezustand) · Tag (Dein Tag vom Coach, Erkannt bei dir mit „Stimmt nicht“, Mehr Daten: Apple Health, Health Connect, Uhr/Ring).

## Neu in allen 5 Bereichen (2026-10-29)

Damit nichts vom alten Main Feed verloren geht ([[Bereichs-Werte]], Schreibfeld pro Bereich):

- **Kreis oben antippen** = Verlauf 30 Tage mit gestrichelter Schnittlinie + „Warum gerade hier“ (ein Coach-Satz).
- **Coach-Karte antippen** (kleines „Frag mich“) = Frag den Coach: Textfeld, 2 Beispielfragen, Antwort vom Coach.
- **Mindset:** [[Deine Muster]] als Feld auf der Seite Dranbleiben (neuestes Muster + Gegenschritt), offen: alle Muster mit „Stimmt nicht“.

Auf Heute bleiben: Check-in, Coach-Karte, Fokus der Woche, Reality Check, Dein Warum, Heute dran / Sonnenbogen, Tage am Stück, Foto- und Muster-Feld, Termine.

## Entwurf 3 (2026-10-29): direkt, ohne „Alles zu“

Phillip 17:35: „nich mit einem alles zu ... Knopf sondern direkt clean modern und vor allem übersichtlich einbauen“. Gleicher Link (Version 3). **Entschieden 2026-10-29 17:40:** Phillip „Passt“.

- Unter dem Körper-Kopf eine Glas-Leiste mit 3 Feldern: Training · Ernährung · Schlaf & Routine, jedes mit Symbol, Wert und 7 Mini-Balken. Das gewählte ist gold umrandet, der Rahmen gleitet beim Wechsel mit.
- Darunter wie gewohnt die 4 Seiten des gewählten Teils (Inhalte wie Entwurf 2). Beim Wechsel tauschen Seitenleiste, Coach-Satz und Felder mit Animation.
- Die alte Hub-Seite „Verlauf“ (alle drei zusammen, Hängt zusammen, Fortschrittsfoto) liegt jetzt hinter dem Körper-Kreis.
- Coach-Karte = Frag den Coach (Fragen passend zum gewählten Teil).

## Stand im Code (2026-10-29)
- Gebaut in PR #64 (Teil 1): Körper-Seite im Glas-Look, `code/lib/home/koerper_seite.dart`, Vorlage für alle Bereiche in `code/lib/bereiche/`.
- Oben die Leiste Training · Ernährung · Schlaf & Routine, darunter je 4 Seiten mit Glas-Kacheln. Tippen auf eine Kachel lässt sie in ihre Seite wachsen.
- Ring oben = Körper-Verlauf (3 Kurven, „Hängt zusammen“, Fortschrittsfoto). Coach-Karte „Frag mich“ = Frag den Coach.
- Energie heute liegt vorerst bei Schlaf & Routine auf der Seite „Tag“, bis Produktivität gebaut ist.
- Mindset öffnet noch die alte Seite, bis Teil 2 fertig ist.
