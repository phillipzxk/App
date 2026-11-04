---
thema: Echter Wecker
stand: 2026-11-01
status: beschlossen und gebaut
tags: [umsetzung, handy-version, schlaf]
---

# Echter Wecker (iPhone)

Dritter Schritt der Handy-Version nach [[Konto und Sicherung]] und [[Erinnerungen]]. Baut auf dem „Besonderen Wecker“ aus [[Schlaf und Energie komplett]] auf.

Entwurf 1: https://claude.ai/artifact/RXnj4ewgZMFePxvPxsJrE5 (ein Morgen: Sonnenaufgang, Wecker, Aufgabe, „Du bist wach“). Phillip 2026-11-01: „Ja passt“ (mit „Licht an“ bei Dunkelheit und Nachklingeln).

## Beschlossen

- **Echter Wecker über Apples AlarmKit** (ab iOS 26): klingelt auch im Lautlos-Modus, bei „Nicht stören“ und wenn die App zu ist. Weckzeit kommt aus „Deine Schlafzeiten“, bei frühem Termin früher.
- **Knöpfe:** „Aufstehen“ und „5 Min“. Schlummern geht nur einmal: Danach klingelt er mit nur noch „Aufstehen“.
- **Aufgabe:** „Aufstehen“ öffnet die App direkt mit der gewählten Aufgabe (Foto vom Himmel, Aufwach-Himmel oder 30 Schritte), noch vor dem Check-in.
- **Nachklingeln** (Claudes Vorschlag): Apple erlaubt nicht, dass nur die Aufgabe den Ton ausmacht. Darum klingelt der Wecker 3 Minuten nach „Aufstehen“ noch einmal, wenn die Aufgabe nicht erledigt ist.
- **Wenn es dunkel ist** (Phillips Frage): Ist die Sonne noch nicht aufgegangen, wird aus „Foto vom Himmel“ automatisch **„Licht an“**: großes Licht oder Tageslichtlampe an und den hellen Raum fotografieren. Die App prüft, ob das Foto hell genug ist. Sobald es morgens hell ist, kommt wieder das Himmel-Foto. „30 Schritte“ und „Aufwach-Himmel“ bleiben gleich.
- **Du bist wach:** Zeit des Aufstehens, ein Satz zum Tag (z. B. „Heute: Push 17:30.“), dann weiter zum Check-in.
- **Sonnenaufgang am Bildschirm** nur, wenn das Handy über Nacht mit offener App im Ruhezustand liegt. Ein gesperrtes iPhone schaltet den Bildschirm nicht selbst ein.
- Den Wecker-Bildschirm zeichnet Apple: Text, Knöpfe und Gold als Farbe legen wir fest, nicht den ganzen Hintergrund.
- Unter iOS 26 bleibt der Wecker eine Mitteilung mit Ton (siehe [[Erinnerungen]]).

## Stand im Code (2026-11-01)

- `code/ios/Runner/AppDelegate.swift`: die drei Knöpfe als App-Intents („aufstehen“, „schlummern“, „aufgabe“), Nachklingeln nach 180 Sekunden, Merker für die Aufgabe.
- `code/lib/erinnerungen/erinnerung_dienst.dart`: Wecker stellen über das Paket alarm_kit (dazu ein Sicherheits-Klingeln nach 10 Minuten, falls gar nichts getippt wird).
- `code/lib/schlaf/wecker_aufgabe.dart`: Aufgabe, „Licht an“ mit Helligkeitsprüfung, „Du bist wach“. Erscheint vor dem Check-in.
- Die Vorschau „Wecker testen“ auf der Schlaf-Seite zeigt ebenfalls „Licht an“, wenn es dunkel ist.

## Noch offen

- Echt testen geht erst auf Phillips iPhone (Apple-Entwicklerkonto, TestFlight).
- Eigene Weckertöne (Vögel, Gong, Regen, Gitarre) als Tondateien; bis dahin der Standard-Weckton von Apple.

## Schritte echt zählen (2026-11-04)

Phillip hat den Entwurf https://claude.ai/artifact/AFZQvGVQsiGgvKPZZC9umn am 2026-11-04 freigegeben („jo“).

- **Zählen:** Das iPhone zählt die Schritte selbst (CoreMotion, `CMPedometer`), nur solange die Aufgabe offen ist, und es wird nur die Zahl gespeichert.
- **Beim ersten Mal:** Die App fragt „Darf ich deine Schritte zählen?“ mit „Erlauben“ oder „Lieber tippen“. Danach fragt das iPhone einmal nach „Bewegung und Fitness“.
- **Ohne Erlaubnis, im Browser oder wenn das Zählen nicht klappt:** Man tippt bei jedem Schritt. Beim Zählen gibt es außerdem den Knopf „Zählt nicht? Dann tippen“.
- **Bild (Entwurf 3, freigegeben 2026-11-04 „top“):** Phillip wollte es zuerst besser designt und animiert (Entwurf 2), dann realistischer und in den Farben der App (Entwurf 3). Jetzt ist es eine Morgen-Szene in App-Farben: fast schwarz, dunkles Braun, Sand und Gold. Es gibt Hügel hintereinander mit Nebel, Gras im Wind und goldene Wurzeln unter der Bodenlinie wie im Logo. Jeder Schritt setzt einen Schuhabdruck mit kleiner Lichtwelle auf den Hügel und holt die Sonne ein Stück höher. Die Sterne verblassen, und ein goldener Ring um die Zahl füllt sich, wobei die Zahl kurz hüpft. Am Ziel bricht die Sonne mit Strahlen und Funken durch, und ein goldener Trieb wächst.
- **Du bist wach (alle Aufgaben):** Der Bildschirm bleibt in der gleichen Szene, dunkel mit goldenem Licht. Die Zeilen kommen nacheinander rein. Darunter tippt der Coach einen kurzen Satz zum Tag, zum Beispiel „Starker Start. Heute: Push 17:30. Jetzt kurz ans Licht, dann der Check-in.“ Das war Claudes Vorschlag und wurde mit Entwurf 3 freigegeben. Auch die Aufgaben Foto, Licht an und Frage haben jetzt die Nacht-Szene als Hintergrund.
- **Anzahl:** 20, 30 oder 50, wählbar auf der Wecker-Seite. Standard ist 30. Das war Claudes Vorschlag, mit dem Entwurf freigegeben.
- **Nach dem Aufstehen:** Auf dem Bildschirm „Du bist wach“ steht zusätzlich „30 Schritte in 41 Sekunden“. Der Coach bekommt im Check-in „Heute Morgen: 30 Schritte in 41 Sekunden, 2 Minuten nach dem Wecker.“ und sieht so, wie schnell man morgens in Gang kommt. Das war ebenfalls Claudes Vorschlag.

**Stand im Code:**
- `code/lib/schlaf/schritt_zaehler.dart` für Zähler, Wahl und Sätze
- `code/lib/schlaf/schritt_weg.dart` für den Bildschirm
- `code/lib/schlaf/morgen_szene.dart` für die Szene (auch auf dem Bildschirm „Du bist wach“)
- `GroundsetSchritte` in `AppDelegate.swift` (EventChannel `groundset/schritte`)
- `NSMotionUsageDescription` in `Info.plist`
