---
title: Schnell-Eintrag
status: gebaut
datum: 2026-11-08
tags: [umsetzung, schnell-eintrag, coach]
---

# Schnell-Eintrag

Entschieden mit Phillip am 2026-11-08 („sehr geil“). Entwurf: https://claude.ai/artifact/KD19xehq644JGXPivba2KK
Gehört zu [[Heute und Fundament]] (Knopf neben der Glas-Leiste).

## Ablauf
1. Goldener **+ Knopf** rechts neben der Glas-Leiste, auf Heute und Fundament. Gedrückt halten startet sofort das Mikro.
2. Blatt „Was gibt's, Phillip?“: großer Mikro-Knopf (Wörter erscheinen live) oder Textfeld, dazu kleine Anfänge zum Antippen.
3. Der Coach (Route `/schnell`) zerlegt den Text in einzelne Karten, jede mit Bereich, Titel und was die App damit macht. Ist er unsicher, fragt die Karte mit Ja/Nein.
4. **Gegenfragen** (Phillips Idee): nach dem Sortieren fragt der Coach höchstens 2 Dinge, nur wirklich Wichtiges (Phillip: „nur ernste Sachen“): ein geplantes Training, dessen Uhrzeit über eine Stunde vorbei ist und das nicht eingetragen ist, und Hauptmahlzeiten, die über 2 Stunden vorbei sind. Keine Snacks, keine Supplements.
5. „Passt so“: Karten werden gespeichert, Lichtpunkte fliegen hoch, der Coach freut sich kurz. Mit dem Kreuz nimmt man eine Karte raus.

## Was wohin geht
- Mahlzeit → passende Mahlzeit heute als gegessen
- Training → Übung mit Gewicht, Wiederholungen, Sätzen in die heutige Einheit; „Training fertig“ setzt sie fertig
- Termin → Dein Tag (Tag + Uhrzeit)
- Gewicht, Schlafstunden → wie bei den Feldern
- Supplement → passendes als genommen
- Durchgezogen → Mindset, Durchgezogen
- Alles andere → Notiz an den Coach im passenden Bereich

## Stand im Code
- `code/lib/schnell/` (`schnell_eintrag.dart` Logik + Gegenfragen, `schnell_blatt.dart` Knopf, Blatt, Lichtpunkte)
- `home_page.dart`: `_schnellEintrag`, `_ablegen`
- Worker: `backend/src` Route `/schnell` (`schnellPrompt`, `parseSchnell`)
- Mikro über das Paket `speech_to_text` (iPhone: Mikro- und Spracherkennungs-Hinweis in Info.plist)
- Offen: Worker online stellen (wartet auf Phillips OK), GitHub gesperrt, deshalb nur lokal gesichert.
