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

## Rundgang 2026-10-31

- Unter dem Körper-Ring steht „Schnitt aus allen drei · ±x zu gestern“ statt des Werts vom Training. Die Werte der drei Teile stehen in der Leiste darunter.

## Körper, lebendig (2026-11-07)

Phillip: Seiten bei Körper „zu langweilig vom Design“, er will Animationen, besondere Dinge und das Coach-Gesicht. Entwurf https://claude.ai/artifact/37RPRTygiLr4LnzzH5R68i, Phillip: „ja sehr gut so den Stil beibehalten!“ Der Stil gilt auch für spätere Seiten.

1. **Szene oben** statt Ring: Training = Hantelscheiben fliegen auf die Stange; Ernährung = Energie-Kurve zeichnet sich, Mahlzeiten fallen als Punkte drauf, Sonne wandert bis „jetzt“; Schlaf = Nachthimmel mit funkelnden Sternen, Mond füllt sich bis zum Schlafwert. Wert des Teils zählt hoch, darunter eine Zeile (z. B. „Heute ins Bett um 22:45“). Tippen öffnet den Verlauf.
2. **Coach zeigt:** Sein Gesicht springt aus der Coach-Karte und fliegt zu der einen Kachel, die heute zählt; sie leuchtet gold. Beim Scrollen verschwindet das Gesicht wieder.
   - Training Heute → Heute-Kachel (wenn heute Training offen), Woche → Stagnations-Check (wenn fällig)
   - Ernährung Heute → Trinken (ab 13 Uhr unter halbem Ziel) sonst Dein Essen heute; Ziel → Supplements (wenn offen)
   - Schlaf Morgen → Aufwach-Himmel (wenn noch nicht eingetragen), Abend → Abend-Journal (ab 20 Uhr)
3. **Coach freut sich:** lachendes Gesicht hüpft unten rein, goldene Funken, ein Satz: Training geschafft, Wasser-Ziel erreicht, alle Supplements genommen.
4. **Kacheln leben:** Zahlen zählen hoch, Trinken-Kachel zeigt das Glas, Kochbuch eine Ranke, an der pro Gericht ein Blatt wächst.

Code: `code/lib/bereiche/koerper_szene.dart`, `code/lib/ui/coach_freude.dart`, Flug und Leuchten in `bereich_seite.dart` (`BSeite.zeigt`, `Unterbereich.szene`).

### Umbau näher am Entwurf (2026-11-07, nach Phillips „ist das wirklich der stil“)
- Die Szene füllt jetzt das ganze obere Drittel: Zurück, „Körper“ klein, der Name des Teils groß, Wert groß rechts, unten Pillen Training · Ernährung · Schlaf.
- Die Coach-Karte fällt auf diesen Seiten weg. Der Coach spricht in einer Sprechblase direkt über der Kachel, die zählt (ohne Ziel über der ersten Kachel); „Frag mich ›“ steht in der Blase. Sein Gesicht fliegt aus der Szene in die Blase.
- Lebende Bilder: Heute-Training = Felder pro Übung (gold wenn erledigt) bzw. leere Hantel ohne Plan, Woche = Punkte ploppen auf, Dein Essen heute = kleine Kurve mit Mahlzeiten und Sonne, Nächte = Balken wachsen, Trinken = Glas, Kochbuch = Ranke.
- Code: `kachel_bilder.dart`; Szene `gross` in `koerper_szene.dart`; `_CoachBlase`, `_TeilPillen` in `bereich_seite.dart`.

## Körper als Bilder (2026-11-07)

Phillip: Kacheln „nicht so Vierecke einfach reinplatzieren“, auf das Wichtigste reduzieren, Dopplungen zusammenfassen, nichts verlieren, bildlich und besonders. Entwurf 1 („die Muster stimmen“), Entwurf 2 (Farben, Aufbau), Entwurf 3 (clean, rund, Schlaf einfacher), dann Farben an Schwarz und Gold vom Homefeed angepasst: Phillip „ja sehr gut genauso“. Entwurf: https://claude.ai/artifact/3DdGoRFDmv6nQ4tiFk6rot

Aufbau jeder Seite, überall gleich:
- oben Zurück-Kreis und Pillen Training · Ernährung · Schlaf, darunter „Körper“ klein, der Teil groß, rechts der Wert-Ring (öffnet den Verlauf)
- goldene Reiter-Leiste mit drei Seiten
- eine Coach-Zeile mit Gesicht (Tippen = Frag den Coach)
- **ein Bild** pro Seite, darunter eine kurze Zeile
- eine runde Zahlenleiste mit 3 Zahlen, ein goldener Hauptknopf als Pille, daneben ein runder kleiner Knopf
- Farben: Schwarz und Gold wie Heute; pro Teil nur ein leiser Ton im Bild (Training kupfer, Ernährung hellgold, Schlaf silberner Mond). Gold heißt immer „geschafft“.

Seiten und Bilder (alles, was vorher eine Kachel war, ist im Bild, in einer Zahl oder einem Knopf):
- **Training**
  - Heute: Hantelscheiben je Übung, gold wenn erledigt, darunter die nächste Übung mit Ziel. Knopf Training starten, Kamera = Form filmen.
  - Woche: Weg durch die Woche, gold = geschafft, Ring = heute. Zahlen: Einheiten, Sportarten (Hybrid-Balance), Stagnation. Knopf Plan ändern, kleiner Knopf Sportarten.
  - Fortschritt: Kurve der besten Werte, jeder Rekord ein goldener Trieb. Knopf Nächstes Ziel vorschlagen, kleiner Knopf Form-Videos.
- **Ernährung**
  - Heute: Energie-Kurve mit Mahlzeiten und Sonne, Teller, Wasserglas (Glas tippen öffnet Trinken). Knopf Foto machen, kleiner Knopf Heißhunger.
  - Küche: Ranke, jedes Gericht ein Blatt (voll = Basis, leer = Rettung), Korb mit offenen Einkäufen. Knopf Einkaufsliste, kleiner Knopf Kochbuch.
  - Ziel: kcal-Bogen mit Gewichtslinie, Supplements als Kapseln (gold = genommen). Knopf Gewicht eintragen.
- **Schlaf & Routine**
  - Morgen: Sonnenaufgang, Ring um die Sonne für die Lichtminuten, drei runde Knöpfe „Wie bist du aufgewacht?“. Knopf Licht-Timer, kleiner Knopf Wecker.
  - Nacht: Mondbogen von Bettzeit bis Wecker mit dem Schlafwert in der Mitte, darunter 7 Monde für die letzten Nächte (kurz = klein und dunkel). Knopf Schlafzeiten, kleiner Knopf Erkannt bei dir (Muster).
  - Abend: Fenster mit 6 Sternen fürs Journal (3 dankbar, 3 morgen besser), drei Kerzen auf der Fensterbank für die Routine (brennen ab ihrer Uhrzeit). Knopf Gute Nacht, kleiner Knopf Dein Tag vom Coach.
- Weggefallen: die Seite „Tag“ (Dein Tag ist auf Heute und als Knopf auf Abend, Muster auf Nacht) und die Kachel „Mehr Daten“ (kommt mit der Handy-Version in die Einstellungen). Training „Plan“ steckt in Woche.

Code: `code/lib/bereiche/koerper_bilder.dart` (die 9 Bilder), `BBild`/`BZahl` und `_BildSeiteView` in `bereich_seite.dart`, Daten in `code/lib/home/koerper_seite.dart`. `kachel_bilder.dart` ist entfernt.
