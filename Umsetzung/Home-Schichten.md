---
title: Home-Feed als Wurzelwerk
tags: [umsetzung, feed, design, animation]
status: gebaut
---

# Home-Feed als Wurzelwerk (früher: Schichten)

Phillip, 24.10.2026: Der Aufbau mit den Feldern und der Leiste unten ist zu normal, wie bei allen Apps. Der Home-Feed soll animiert in jede Ebene führen, mit Wegweisern und Sprechblasen vom Coach. Hängt mit [[Main Feed]], [[Animationen]] und [[Design]] zusammen.

## Entscheidungen (mit Phillip, 24.10.2026)

| Frage | Entscheidung |
|---|---|
| Grundaufbau | **Schichten wie im Logo**: oben Heute und der Spross, darunter unter der Bodenlinie 4 Erdschichten bis zu den Wurzeln. Die Leiste unten fällt weg. |
| Reihenfolge nach unten | Training, Ernährung, Schlaf & Energie, ganz unten bei den Wurzeln Mindset (Vorschlag, nicht widersprochen). |
| Animation beim Antippen | **Wurzel wächst hin**: vom Spross wächst eine goldene Wurzel bis zur Schicht, dann klappt die Schicht zur ganzen Seite auf. |
| Wegweiser | Phillips Idee: überall ein kleines **?**, Antippen öffnet eine Sprechblase **vom Coach** mit der Info, wofür das Feld ist und was man dort macht. |
| Empfehlungen vom Coach | **Affe wandert mit**: der Nasenaffe gleitet beim Scrollen am Rand mit und sagt in einer Sprechblase eine Empfehlung, aber nur an Schichten, wo er heute wirklich etwas zu sagen hat ("nicht immer nur so besonders"). |
| Mehr als die Kacheln (25.10.) | Unten in jeder offenen Schicht steht **„Alles zu … ›“**, das öffnet die ganze Bereichsseite wie bisher. |
| Kacheln pro Schicht (25.10.) | **Fest**: Training = Heute, Woche, Verlauf, Wie war es? · Ernährung = Supplements, kcal-Ziel, Gewicht, Verlauf · Schlaf & Energie = Bettzeit, Nächte, Abendroutine, Verlauf · Mindset = Durchgezogen, Dein Warum, Wovor drückst du dich?, Verlauf. Antippen einer Kachel zeigt den konkreten Inhalt. |
| Übrige Felder von Heute (25.10.) | **Oben nur wenn fällig**: Fortschrittsfoto (Fototag), neues Muster, Reality Check, Dein Warum (schwache Phase) tauchen über der Bodenlinie nur an ihrem Tag auf. Supplements stecken in der Ernährungs-Kachel. Immer oben: Coach-Karte, Fokus, Dein Tag, Spross. |

Entwurf 4 zum Durchklicken (Prinzip am 24.10. von Phillip „sehr gut“): https://claude.ai/artifact/5C6s6w1b7kEgkUZRLC25Po. Gebaut wird nach Phillips Ja.

## Entwurf 5: Wurzelwerk (25.10.2026, Phillip: „sehr geil“)

Phillip zu Entwurf 4: noch zu einfach und unrealistisch. Neu entschieden:

- **Oben nur das Wichtigste, ganz kurz:** ein Satz vom Coach, Fokus zum Abhaken, Dein Tag (Bettzeit, Training). Fällige Felder (Fortschrittsfoto, neues Muster, Reality Check, Dein Warum) erscheinen nur an ihrem Tag als goldener Chip daneben.
- **Darunter ein echtes Wurzelwerk mit kleinem Baum** über der Bodenlinie, daneben „Tage am Stück“. Die Bereiche hängen **nicht in einer Reihe**, sondern verteilt und verschieden tief an eigenen Wurzeln: Training oben rechts, Ernährung links, Schlaf & Energie tiefer rechts, Mindset ganz unten. Durch die Wurzeln läuft ständig Licht; wo der Coach heute etwas sagt, hängt eine kleine Sprechblase am Bereich.
- **Antippen:** Licht schießt die Wurzel runter, Funken sprühen, der Bereich geht aus seinem Kreis über den ganzen Bildschirm auf. Darin: Wert mit Trend, Coach-Satz (tippt sich), die 4 festen Kacheln (Diagramme zeichnen sich, Zahlen zählen hoch, Listen zum Abhaken), ein Hauptknopf und „Alles zu … ›“. ✕ schließt zurück in den Kreis.
- Ersetzt die Schichten-Liste aus Entwurf 1 bis 4. Die Entscheidungen oben (feste Kacheln, Alles zu …, Felder nur wenn fällig, ? vom Coach) gelten weiter.

## Gebaut (25.10.2026, PR offen bis Phillips Ja)

Phillip: „wenn keine sachen verloren gehen … alles noch da unbedingt so machen“. Die Leiste unten ist weg. Wo jetzt was liegt:

| Was | Wo |
|---|---|
| Coach-Karte (Text/Stichpunkte, Jubel, Affe) | oben auf Heute, unverändert |
| Fokus der Woche, Reality Check, Fokus-Wahl | oben auf Heute, unverändert |
| Dein Tag (Termine, Mahlzeiten, Bettzeit, Foto-Zeile) | Feld „Heute dran“ unter Fokus = kleiner Sonnenbogen mit allem von heute → tippen öffnet Dein Tag |
| Fortschrittsfoto inkl. Frame Kit | am Fototag goldener Chip oben; immer auf der Training-Seite |
| Neues Muster | oben auf Heute, wenn höchstens 2 Tage alt; immer auf der Mindset-Seite (mit „Alle Muster“) |
| Supplements | Kachel in Ernährung (Antippen → Ernährung-Seite zum Abhaken) |
| Spross / Tage am Stück | Baum über der Bodenlinie; Blätter wachsen mit den Tagen am Stück, Wurzeln mit „Heute geschafft“, Funken beim Jubel |
| Bereichs-Werte | Ring und Zahl an jedem Bereich, Verlauf-Kachel in der großen Ansicht, 30-Tage-Verlauf auf der ganzen Seite |
| Trainingsplan, Schwerpunkt, kcal, Gewicht, Schlafzeiten, Abendroutine, Durchgezogen, Dein Warum, Frag den Coach | ganze Bereichsseite über „Alles zu … ›“ (wie bisher) |
| Fragebogen neu starten | ganz unten auf Heute |

Code: `code/lib/home/wurzelwerk.dart` (Wurzelwerk, Kreis-Öffnen), `code/lib/home/bereich_uebersicht.dart` (große Ansicht mit Kacheln), `code/lib/home/today_tab.dart`, `code/lib/home/home_page.dart`. Die Kacheln öffnen beim Antippen die ganze Bereichsseite.

## Feld „Heute dran“ (2026-10-25)

Phillip: unter „Heute dran“ nichts mehr, das Feld selbst größer, übersichtlicher und besonderer, mit Animation. Aus fünf Entwürfen (https://claude.ai/artifact/6EPQiBoxoCpqKTHxPxrLiJ) gewählt: **E · ein Feld mit allem**, und zwar kleiner („nur kleiner Überblick für den schnellen Blick, wenn man etwas eintragen oder genauer sehen möchte, tippt man eh drauf“).

- Das Feld ist ein kleiner Sonnenbogen. Alles von heute liegt als Zeichen darauf, gleichmäßig verteilt in der Reihenfolge des Tages: Aufstehen, Fortschrittsfoto (am Fototag), Termine, Training, Mahlzeiten, Supplements, Abendroutine, Bettzeit.
- Erledigtes leuchtet gold (genommene Supplements auch vor ihrer Uhrzeit), das Nächste pulsiert. Beim Öffnen läuft die Sonne bis „jetzt“, die Zeichen springen nacheinander auf.
- Darunter eine Zeile: Countdown bis zum Nächsten und „Danach … um …“.
- Tippen öffnet Dein Tag. Der goldene Foto-Chip und die alte Zeile sind weg, das Foto steht am Fototag auf dem Bogen.
- **Trainingszeit:** steht im Namen des Trainingstags, z. B. „Push 17:30“ oder „Push um 17 Uhr“ (Hinweis im Plan-Editor). Ohne Uhrzeit steht das Training nicht auf dem Bogen, nur „Heute noch: …“.
- **Mahlzeiten:** bis der Coach sie plant, verteilt die App die eingestellte Anzahl gleichmäßig von 30 Min. nach dem Aufstehen bis 2,5 Std. vor dem Bett.
- Gebaut 2026-10-25 (`code/lib/home/sonnenbogen.dart`, `HeuteBogen`), PR #59.
