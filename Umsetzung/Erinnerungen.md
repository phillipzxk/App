---
thema: Erinnerungen
stand: 2026-11-01
status: beschlossen und gebaut
tags: [umsetzung, handy-version, erinnerung]
---

# Erinnerungen (Handy-Version)

Wie sich Groundset auf dem Handy meldet. Zweiter Schritt der Handy-Version nach [[Konto und Sicherung]]. Entwurf 1: https://claude.ai/artifact/B1M2z6wBxW6Ufed2AC6rzt (ein Tag auf dem Sperrbildschirm). Phillip 2026-11-01: „Sehr gut … übernehmen und die goldenen auf jeden Fall auch“. Sein Handy: **iPhone**.

## Die Erinnerungen

| Art | Wann | Text (Beispiel) | Ein Tipp öffnet |
|---|---|---|---|
| Wecker | Aufstehzeit aus „Deine Schlafzeiten“ | „Guten Morgen, Phillip. Zeit aufzustehen.“ | Schlaf & Routine |
| Check-in am Morgen (neu) | 20 Min. nach dem Aufstehen, nur wenn noch nicht gemacht | „Morgen, Phillip. 30 Sekunden, dann sag ich dir, wo es heute hängt.“ | Check-in |
| Supplements | zu den eigenen Uhrzeiten, nur was offen ist | „Kreatin und Vitamin D sind noch offen.“ Knopf **Abhaken** | Ernährung |
| Termine | 30 Min. vorher | „In 30 Minuten: Zahnarzt, 14:00.“ | Dein Tag |
| Training | 1 Std. vor der Uhrzeit im Namen des Trainingstags („Push 17:30“) | „Letztes Mal Bankdrücken 80 kg × 8. Heute 82,5 kg × 8 drin?“ | Training |
| Fokus am Abend (neu) | 20:00, nur wenn „Heute geschafft“ noch offen | „Handy nach 21 Uhr weg. Tag 4 von 7. Heute geschafft?“ Knöpfe **Geschafft**, **Heute nicht** | Fokus der Woche |
| Abendroutine | Start der [[Abendroutine]], sonst 30 Min. vor der Bettzeit | „Bettzeit 22:45, morgen um 6:45 raus. Erst das Abend-Journal, dann Gute Nacht.“ | Schlaf & Routine |
| Fototag | am eigenen Fototag, 1 Std. nach dem Aufstehen, nur wenn das Foto fehlt | „Gleiche Stelle, gleiches Licht wie letzte Woche.“ | Fortschrittsfoto |
| Reality Check (neu) | am Tag vom Fokus-Wechsel, 1,5 Std. nach dem Aufstehen | „Die Woche ist rum. Vorgenommen 7, geschafft 5.“ | [[Reality Check]] |

„Neu“ = Claudes Vorschläge, von Phillip angenommen.

## Regeln

1. Nur wenn etwas offen ist (Check-in gemacht, Supplements abgehakt, Fokus getippt, Training schon eingetragen, Foto schon da → keine Erinnerung).
2. Höchstens 5 am Tag. Termine und Wecker zählen nicht mit. Zu viele: erst alle Supplements in eine Erinnerung zusammenfassen, dann fällt das Unwichtigste weg (Reihenfolge der Wichtigkeit: Training, Abendroutine, Check-in, Supplements, Reality Check, Fototag, Fokus).
3. Nachts Ruhe: ab der Bettzeit und nach „Gute Nacht“ bis zum Wecker kommt nichts außer dem Wecker.
4. Ein Tipp öffnet genau die passende Stelle.
5. Im Ton vom Coach (siehe [[Coach-Stil]]): kurz, direkt, mit Namen und echten Zahlen, keine Emojis.
6. Jede Art einzeln abschaltbar, dazu der Schalter „Höchstens 5 am Tag“, in **Konto und Sicherung → Erinnerungen** (runder Knopf oben rechts auf Heute).

## Stand im Code (2026-11-01)

- Ordner `code/lib/erinnerungen/`: `erinnerung_plan.dart` (welche Erinnerung wann, alle Regeln), `erinnerung_dienst.dart` (legt sie aufs Handy, Paket flutter_local_notifications).
- Die App plant die nächsten 3 Tage neu, sobald Heute geladen ist und 2 Sekunden nach jeder Änderung.
- Die Erlaubnis für Mitteilungen fragt das iPhone beim ersten Öffnen von Heute ab (nur einmal).
- In der Browser-Vorschau erscheinen keine Erinnerungen, nur die Schalter in den Einstellungen.
- Prüfung: GitHub baut die iPhone-Version ohne Signatur (`.github/workflows/iphone-build.yml`).

## Noch offen

- **Echter Wecker:** Bis jetzt ist der Wecker eine Mitteilung mit Ton. Ein Wecker, der auch im Lautlos-Modus klingelt und sich nur mit Aufgabe ausschalten lässt (siehe [[Schlaf und Energie komplett]]), braucht Apples Wecker-Schnittstelle (AlarmKit, ab iOS 26). Kommt als eigener Schritt.
- Zum Testen auf Phillips iPhone braucht es das Apple-Entwicklerkonto (99 € im Jahr) und TestFlight.
