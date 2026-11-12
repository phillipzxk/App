---
title: Umbau (neues Aussehen der ganzen App)
status: Heute, Fundament, Bereichsseiten und Dein Tag gebaut; Unterseiten offen
datum: 2026-11-12
tags: [umsetzung, design, heute, fundament, animation]
---

# Umbau

Entschieden mit Phillip am 2026-11-12 über neun Entwürfe. Entwurf (alle Versionen auf einem Link): https://claude.ai/artifact/HE4ZTUbH1vRyj3gFi3oces

Gehört zu [[Heute und Fundament]], [[Design]] und [[Animationen]].

## Warum

Phillip fand die App „zu normal“. Das Grundprinzip bleibt (Heute und Fundament mit Wurzeln, vier Bereiche, Coach, alle Funktionen, nichts wird entfernt), aber das Aussehen wird moderner, besonderer, runder und lebendiger. Nie bunt.

## Was bestätigt ist

1. **Aufbau „Ein Blick“**: ruhige Kacheln ohne Rahmen, große Zahlen, alles auf einem Bildschirm. Schrift Sora und Figtree.
2. **Farben**: Espresso-Braun statt reinem Schwarz, Glas-Kacheln mit Radius 30, Gold als einzige Farbe. Keine Bereichsfarben, auch nicht bei den Balken.
3. **Heute** („perfekt“):
   - Kopf: Datum klein, „Tag X von 7“, runder Konto-Knopf, darunter „Heute, Name“ mit goldenem Namen.
   - Coach steht frei ohne Karte: Bild mit Goldring, Antwort tippt sich, Link „Als Stichpunkte ›“.
   - Eine helle Gold-Kachel „Heute dran“: was als Nächstes kommt mit Uhrzeit, großer Countdown, Tageslinie mit Punkten, die Sonne wandert zum Jetzt.
   - Kachel Fokus der Woche (7 Striche, Knopf „Heute geschafft“).
   - Kachel Tage am Stück mit goldenem Spross, darunter Foto.
   - Breite Kachel „Dein Fundament“: Schnitt zählt hoch, vier goldene Balken.
   - Unten Glas-Pille „Heute | Fundament“ mit gleitendem Gold-Knopf, daneben der runde Plus-Knopf.
4. **Animationen auf Heute**: Kacheln federn nacheinander rein, Zahlen zählen hoch, Balken wachsen, Glas neigt sich zum Finger. „Heute geschafft“: Funken, Welle durch den Hintergrund, neues Blatt am Spross, ein Licht fliegt in die Fundament-Kachel.
5. **Hintergrund „Wurzelnetz“** (aus drei Ideen gewählt): feine goldene Wurzeln wachsen von unten hinter den Kacheln, Lichtpunkte laufen daran entlang, jede Berührung schickt eine Welle hindurch. Auf Fundament blendet es aus.
6. **Fundament** („ja okay“):
   - Oben dieselbe helle Gold-Kachel: „Dein Schnitt“ mit den vier Werten.
   - Die echten Wurzeln in Champagner-Gold mit atmendem Schein, direkt auf dem Hintergrund (keine Erde mehr). Nie grau.
   - Beim Öffnen wachsen die Wurzeln von oben nach unten.
   - An jedem Wurzelende eine runde Glas-Kapsel: Ring füllt sich golden, Zahl zählt hoch, daneben Name, Veränderung zu gestern und eine Detailzeile.
   - Lichtpunkte laufen die Wurzeln entlang.
   - Ganz unten die Kachel „Deine Lebensziele“.
7. **Wechsel**: Heute gleitet nach oben weg, Fundament steigt von unten auf.

## Verworfen

Entwurf 1 (Felder entfernt), Tageszeit-Farben und Edelstein-Töne, Aufbau B, C und D, nur Schwarz („langweilig“), farbige Lichtflecken, Pastell-Bereichsfarben („bunt“), graue Wurzeln.

## Bereichsseiten und Dein Tag (2026-11-12, Phillip „ja“)

Die Bilder-Seiten der Bereiche (siehe [[Bereiche als Bilder]]) bleiben, nur das Aussehen ist angeglichen:

- Hintergrund Espresso-Braun mit einem goldenen Licht von oben rechts, keine farbigen Lichtflecken mehr.
- Kopf: kleines Etikett, Name, darunter der Wert groß in Gold (zählt hoch) mit „+1 zu gestern“, rechts die letzten sieben Tage als Balken (heute golden). Tippen auf die Zahl öffnet weiter den Verlauf.
- Pillen-Schalter mit gleitendem Gold-Knopf, Coach steht frei ohne Sprechblase, Bild und Zahlenleiste als ruhige Glas-Kacheln.
- Dein Tag: die Countdown-Karte ist jetzt dieselbe helle Gold-Kachel wie „Heute dran“, Liste und Kalender-Karte in ruhigem Glas. Der Sonnenbogen bleibt.
- Alle Glas-Kästen der App (`GlasBox`) haben den neuen ruhigen Look ohne Goldrand und Schatten, Seitentitel sind weiß statt golden.

## Noch offen

- Die Unterseiten hinter den Kacheln (zum Beispiel „Training heute“) haben innen noch Karten mit Goldrand.
- Kleine Felder auf Heute, die nur manchmal erscheinen (Dein Warum, Muster, Gesundheitswerte), haben noch den alten Rahmen.

## Stand im Code

- `code/lib/ui/umbau.dart`: Farben und Bausteine (`GlasKachel`, `ZaehlZahl`, `Einflug`, `Wurzelnetz`, `fliegeLicht`, `funkenBei`).
- `code/lib/home/today_tab.dart`: Heute-Seite. `coach_karte.dart`: Coach ohne Karte. `sonnenbogen.dart`: `HeuteBogen(held: true)` ist die helle Kachel.
- `code/lib/home/fundament_seite.dart`: Kopf, „Dein Schnitt“, Fundament-Kachel auf Heute, Glas-Pille.
- `code/lib/home/wurzelwerk.dart`: goldene Wurzeln ohne Erde, Schein, Lichtpunkte, Kapseln.
- `code/lib/home/home_page.dart`: Hintergrund, Seitenwechsel, Fokus-Kachel, Feier bei „Heute geschafft“.
- `code/lib/bereiche/glas.dart` und `bereich_seite.dart`: Glas-Look, Hintergrund, Kopf der Bereichsseiten (`_WochenBalken`). `sonnenbogen.dart`: helle Kachel auf Dein Tag.
- Der Satz des Coaches, warum ein Bereich dort steht, erscheint nicht mehr auf der Kapsel, sondern auf der Bereichsseite. Beim schwächsten Bereich steht auf der Kapsel „Hier hängt es gerade.“
