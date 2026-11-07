---
tags: [umsetzung, design]
stand: 2026-11-07
---

# Bereiche als Bilder

Fokus & Arbeit, Ausstrahlung (Persönlichkeit) und Mindset als ein großes Bild pro Reiter, genau wie [[Körper komplett|Körper]]. Entwurf 3: https://claude.ai/artifact/9g6bQdkaxNyqkfQfF83gES. Phillip: „orientier dich mehr an Körper, farblich, bildlich“, dann „Das ist perfekt die farbe“ und „ja ins braun wechseln“. Bau freigegeben 2026-11-07. Nichts darüber hinaus.

Aufbau jeder Seite wie bei Körper: oben ‹ Heute, „Bereich“ und der Name mit Wert-Ring, Reiter, Coach-Satz, das Bild, drei Zahlen, Hauptknopf und ein runder Knopf. Jeder Teil des Bildes öffnet die Seite dahinter, die alten Kacheln werden nicht mehr gezeigt, nur geöffnet. Grund im dunklen Braun mit Goldlicht.

## Fokus & Arbeit
- **Heute:** oben die eine Sache mit Scheibe (gold mit Haken, wenn geschafft). Darunter die Energie-Kurve des Tages als leuchtendes Goldband (Aufstehen bis Bett), der Fokus-Block als Goldkreis im Hoch, das Tief und, wenn es eins gibt, das zweite Hoch. Stunden darunter, unten „Fokus-Block N Min · tippen = starten“. Zahlen: Fokus-Block, hoch bis, die eine Sache.
- **Ziele:** oben der Hebel der Woche. Ein Ast mit den Meilensteinen als Blätter (voll = geschafft, leuchtend = als Nächstes, das letzte als Knospe „dein großes Ziel“). Rechts der Skill als Leiter. Zahlen: Meilensteine, Skill-Stufe, Hebel.
- **Handy:** ein Handy mit „Heute abgelenkt N×“ und dem goldenen Knopf „Ich will ablenken“ (Tippen zählt direkt). Darunter die häufigsten Gründe als kleine Balken. Unten der handyfreie Morgen als Goldstück auf dem Tagesbalken. Zahlen: heute, vs. gestern, handyfrei.
- **Rhythmus:** der Tag als Bogen von Aufstehen bis Bett, die besten Stunden dick in Gold mit Sonne, das Tief hell, das Training. Groß die besten Stunden. Darunter „Geber und Räuber“ als Scheiben mit Pfeil (aus den Schlaf-Mustern, sonst „Kommt nach 14 Morgen“).
- **Routinen:** die angedockten Gewohnheiten als Pillen (Anker, Gewohnheit, „seit N Tagen“ oder „Tag N/21“), gold mit Haken = heute gemacht, Ring = offen, die aktuelle leuchtet. „+ Neue Gewohnheit andocken“, darunter was von allein läuft.

## Ausstrahlung
- **Heute:** ovaler Spiegel mit „N/3 morgens“, rechts die Schritte der Morgen-Routine als Tropfen (Tippen hakt direkt ab). Unten Lern-Ziel als 10 Kästchen und die Stimme als Welle.
- **Look:** Silhouette mit Goldlinie und pulsierenden Hinweis-Punkten: zwei Hebel aus der Look-Analyse, dazu Stil und Haltung. Darunter der Look-Verlauf.
- **Pflege:** Haut-Plan als Halbkreis über 8 Wochen, Nadel auf der aktuellen Woche, Striche zwischen den Phasen, darunter die Phase. Unten die kleinen Dinge und die Frisur als Scheiben (leuchtender Rand = fällig, gold = erledigt).
- **Wissen:** der Skill-Kurs als Schiene mit Lektionen (gold = geschafft, leuchtend = jetzt), darunter das Bücherregal (gold = umgesetzt, leuchtend = liest du gerade).

## Mindset
- **Heute:** Berg in der Dämmerung mit Sternen, Goldgrat und Fahne, die Steine auf dem Weg nach oben mit „seit N Tagen“. Oben „Wort gehalten“ als Scheiben.
- **Dranbleiben:** Ausreden-Spiegel als Pillen, die Treppe „Selbstständig · Stufe N“ mit Licht auf deiner Stufe, „Durchgezogen“ als Goldsteine. Der runde Knopf öffnet „Deine Muster“.
- **Ruhe:** Mond und die Frage heute Abend, die Werte als Lichter über stillem Wasser (heller = besser danach gelebt), im Wasser „Sorgen abgeben“.
- **Langfristig:** Lebensrad mit den 4 Bereichen der App (Körper, Fokus & Arbeit, Ausstrahlung, Mindset) und Schnitt in der Mitte, versiegelter Brief „öffnet in N Tagen“, Lebensziele.

Code: `code/lib/bereiche/bereich_bilder.dart` (die 13 Bilder, Teil von `koerper_bilder.dart`), Daten in `code/lib/home/produktiv_seite.dart`, `persoenlich_seite.dart`, `mindset_seite.dart`. Neue Kachel `b-skill` (Dein Skill), damit die Skill-Leiter eine Seite öffnet.
