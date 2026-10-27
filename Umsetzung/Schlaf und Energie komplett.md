---
typ: umsetzung
bereich: Schlaf & Energie
stand: 2026-10-27
---

# Schlaf & Energie komplett

Gemeinsam mit Phillip am 2026-10-27 besprochen. Er will: Energie und „wie hast du geschlafen“ rein, neuen Look, besondere Ideen.

## Beschlossen (Phillip 19:15 und 19:17)

1. **Schlafwert 1 bis 100** mit Teilen Länge, Erholung, Durchschlafen, Rhythmus, dazu der **Schlaf-Mond** (letzte 7 Nächte, voll = ausgeruht). Zuerst aus allem, was der Nutzer angibt (Aufwach-Himmel, was nachts war, Schlafzeiten, Bettzeit eingehalten, Journal, Check-in). In der Handy-Version verbinden mit Apple Health, Google Health Connect und Uhren oder Ringen, „alles was möglich ist“.
2. **Aufwach-Himmel**: Regler Nebel bis Sonnenaufgang statt Sterne, dazu antippen, was nachts war.
3. **Sonnenlicht**: Morgens 5 Minuten raus oder ans offene Fenster, mit Timer (der Bildschirm ersetzt kein Sonnenlicht).
4. **Besonderer Wecker**: personalisierbar (Sonnenaufgang 10 Minuten vorher, Klang, Schlummern höchstens einmal). Ausschalten nur mit Aufgabe, z. B. Foto vom Himmel. Echter Wecker erst in der Handy-Version, auf dem iPhone mit Einschränkungen.
5. **Energie-Vorhersage**: Coach sagt aus Schlaf, Essen, Training die Energie des Tages voraus und wann sie am höchsten ist, z. B. „dort Training“. Abends: wie war es wirklich, so lernt er die eigene Kurve.
6. **Was nur bei dir gilt**: Coach erkennt über längere Zeit persönliche Muster (Energie-Geber und -Räuber, beste Zeit) und wendet sie an. „Stimmt nicht“ entfernt eins.
7. **Dein Tag vom Coach**: Aus den Mustern stellt der Coach den optimalen persönlichen Tagesablauf zusammen (betrifft „Dein Tag“ auf Heute), mit Grund pro Punkt, Übernehmen und Rückgängig.
8. **Abend-Journal**: 3 Sachen dankbar, 3 Sachen morgen besser, Pflicht vor „Gute Nacht“. Die 3 „besser“ kommen morgens in „Dein Tag“ zurück.
9. **Runterfahren und Ruhezustand**: Nach „Gute Nacht“ alles dunkel, Abendroutine Schritt für Schritt, Nasenaffe schläft ein, Ruhezustand bis der Wecker klingt.

## Ergänzung 19:23 bis 19:24

- **Licht-Modus am Handy**: Phillip wollte Sonnenlicht am Handy erzeugen (Winter, morgens dunkel). Ehrlich besprochen: Ein Handy ist viel zu schwach, um Tageslicht zu ersetzen (Tageslichtlampe etwa 10.000 Lux). Daher: Bildschirm ein paar Minuten voll hell in kaltem Tageslicht-Weiß, macht wacher, mit ehrlichem Hinweis. Phillip: „ja“.
- **Winter**: Ist es morgens noch dunkel, empfiehlt der Coach eine Tageslichtlampe. Wer eine hat, bekommt jeden Wintermorgen den Timer dafür. Sonst Licht-Modus und „raus, sobald es hell ist“. Hinweis: nicht direkt in die Sonne schauen.
- **Eigener Himmel**: Schlaf & Energie bekommt als einziger Bereich einen Himmel nach Uhrzeit: morgens Morgenrot, tagsüber warmes Gold, abends Nachtblau mit Sternen und Mond. Gold bleibt für Knöpfe und Zahlen.

## Entwurf

Entwurf 2 (6 Ansichten, mit Himmel und Licht-Modus): https://claude.ai/artifact/XHztKsyQRmUheTu3hS7qSg — Phillip „ja“ (2026-10-27 19:27) = Bau-OK.

## Stand im Code

- Ordner `code/lib/schlaf/`: Daten (`schlaf_data.dart`), Rechnen (`schlaf_logik.dart`: Schlafwert, Mond, Energie-Kurve, Sonnenaufgang, Tag ohne Coach), Himmel/Mond/Kurve (`schlaf_widgets.dart`), Aufwachen + Sonnenlicht + Licht-Modus (`aufwachen.dart`), Wecker (`wecker_seite.dart`), Abend-Journal + Runterfahren + Ruhezustand (`abend.dart`), Muster + Dein Tag vom Coach (`muster_tag.dart`).
- Schlaf-Seite (`code/lib/home/sleep_tab.dart`): „Wie hast du geschlafen?“ bis zum Eintrag, dann Schlafwert + Mond, Energie heute mit Rückmeldung, Erkannt bei dir, 4 Kacheln (Wecker, Heute ins Bett, Abend-Journal, Dein Tag), letzte Nächte, Basis wie bisher, „Mehr Daten“ (Handy-Version).
- Coach: Worker-Route `/schlaf` (morgen, energie, muster, tag). Muster frühestens ab 14 Morgen, höchstens einmal pro Woche. Energie-Satz einmal pro Tag.
- Übernommener Tag vom Coach erscheint im Sonnenbogen von „Dein Tag“ (neue Punkte, Stern-Symbol). Die 3 „besser“ von gestern stehen in „Dein Tag“.
- Nach „Gute Nacht“ zeigt die App den Ruhezustand bis zur Weckzeit; ist die App zur Weckzeit offen, öffnet sich der Wecker-Bildschirm. Echter Wecker, Ton und Gesundheitsdaten kommen mit der Handy-Version.
- Alles wird auf dem Gerät gespeichert (Schlüssel `schlaf_daten`).
