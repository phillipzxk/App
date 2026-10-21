---
title: Animationen
tags: [umsetzung, design, heute]
status: gebaut
---

# Animationen

Ziel (Phillip, 21.10.2026): Die App soll sich modern und besonders anfühlen und durch Bewegung übersichtlicher werden. Siehe [[Design]], [[Main Feed]] und [[Fokus der Woche]].

## Entscheidungen (mit Phillip, 21.10.2026)

| Frage | Entscheidung |
|---|---|
| Aufbau Heute | **Switch + großes Feld.** Oben ein Switch mit Training, Ernährung, Schlaf und Mindset, darunter ein großes Feld für den gewählten Bereich. Ersetzt die vier kleinen Kacheln. Der Rest von Heute bleibt. |
| Idee 1 | Tippt man aufs große Feld, wächst es zur ganzen Bereichsseite auf. |
| Idee 2 | Nach dem Check-in fliegen die fünf Antworten in die Coach-Karte, die Antwort schreibt sich Wort für Wort. |
| Idee 4 | Der Spross aus dem Logo steht oben rechts mit „Tage am Stück“. Bei „Heute geschafft“ wachsen Blatt und **Wurzeln**, goldene Funken sprühen, der **Coach jubelt** und der Nasenaffe hüpft. |
| Abgelehnt | Hervorgehobener „Hier hängt es“-Bereich und Zusammenhangs-Karte auf den Bereichsseiten („komisch“). |

Entwurf: https://claude.ai/artifact/QsD3g16x9KfWspC7QzXP25

## So ist es gebaut

- **Switch:** goldener Knopf gleitet, das Feld wechselt mit Schieben, die Zahl zählt hoch, sieben Balken wachsen nacheinander. Im Feld steht der Satz des Coaches aus den [[Bereichs-Werte]]n.
- **Feld öffnet Seite:** das Feld wächst über den Bildschirm, dann erscheint die Bereichsseite.
- **Check-in:** Antwort-Chips fliegen in die Karte, die Karte leuchtet kurz, dann schreibt sich die Antwort.
- **Spross:** Stiel und Blätter wachsen mit den Check-in-Tagen am Stück (bis 14 Tage), die Wurzeln mit jedem geschafften Fokus-Tag der Woche (bis 7).
- **Jubel:** bei „Heute geschafft“ scrollt Heute nach oben, der Spross leuchtet mit Funken, der Coach-Affe hüpft mit goldenem Ring, und oben in der Coach-Karte steht: „Ja, Name! Fokus heute geschafft. Oben siehst du den Trieb, aber das Wichtigste wächst darunter: Deine Wurzeln sind heute wieder tiefer geworden.“ Nimmt man das Häkchen zurück, verschwindet der Jubel.
- **Offen:** Der Affe soll beim Jubeln lachen. Dafür braucht es ein zweites KI-Bild vom gleichen Affen, lachend. Sobald Phillip es hochlädt, wird es beim Jubel kurz eingeblendet.
- Bild der App: `ki-coach/animationen-app.png`.
