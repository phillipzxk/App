---
title: Tages-Planer
tags: [umsetzung, ki, training, kalender, in-arbeit]
erstellt: 2026-10-15
aktualisiert: 2026-10-15
---

# Tages-Planer: Kalender + Training

Kernfeature aus Phillips Notiz „App-Fortschritt“ (Idee vom 14.10.2026, Abschrift in [[App-Fortschritt]]). Grundlage für die KI-Automatisierung in der App. Wird ab 2026-10-15 mit Phillip Schritt für Schritt ausgearbeitet. Noch nicht gebaut.

**Ziel (Phillip):** Kalender, Training und Essen wissen voneinander. Der Plan ist immer machbar, deshalb gibt es keine Ausreden mehr.

**Grundregel (Phillip, 2026-10-15):** Der Kalender ist für alles, nicht nur für Schule: Arbeit, Termine, Schule, Privates. Kommen Termine dazu, passt die KI das Training optimal an, sodass möglichst wenig Trainingsfluss, Intensität und Fortschritt verloren geht.

## Festgelegt

| Punkt | Entscheidung | Datum |
|---|---|---|
| Wer legt das Training fest? | **Eigener Plan + KI.** Der Nutzer schreibt seinen [[Trainingsplan]] wie bisher selbst in eigenen Worten (siehe [[Main Feed]]). Die KI passt ihn jede Woche an Termine und Check-ins an. | 2026-10-15 |
| Wo stehen die Termine? | **Erst eigener Kalender, später beides.** Im MVP werden Termine nur in der App eingetragen, per Freitext an die KI. Das Verbinden mit Google- oder Apple-Kalender kommt nach dem MVP dazu. | 2026-10-15 |
| Wo kommt die Tagesansicht hin? | **In die Seite „Heute“** im [[Main Feed]]. Oben bleiben Coach-Antwort und Fokus der Woche, darunter kommt der Tagesplan mit dem Feld zum Termine-Schreiben. Es bleibt bei 5 Seiten. | 2026-10-15 |
| Was zeigt der Plan bei den Mahlzeiten? | **Essenszeiten + KI-Tipp.** Der Plan zeigt, wann man isst, passend zu Training und Terminen, dazu pro Tag ein kurzer KI-Tipp, was zum Tag passt (z. B. „Klausurtag: leicht zu Mittag, damit du wach bleibst“). Kein Zählen, keine Lebensmitteldatenbank. | 2026-10-15 |
| Wann plant die KI um? | **Sonntag + sofort.** Jeden Sonntag macht die KI den Trainingsplan für die neue Woche passend zu den Terminen. Kommt unter der Woche ein Termin dazu, passt sie die betroffenen Tage sofort an. | 2026-10-15 |
| Erinnerungen im MVP? | **Ja, ins MVP.** Die App erinnert per Benachrichtigung an Termine und an das geplante Training des Tages. (Bisher standen Erinnerungen unter „Später“, siehe [[Roadmap nach dem MVP]].) | 2026-10-15 |
| Ändert die KI selbst oder fragt sie? | **Selbst + rückgängig.** Die KI ändert den Trainingsplan sofort selbst und schreibt kurz dazu, warum. Der Nutzer kann die Änderung mit einem Tipp zurücknehmen. | 2026-10-15 |
| Passt die KI das Essen genauso stark an wie das Training? | **Nein, Fokus auf Sport.** Das Training wird voll an den Kalender angepasst. Die Ernährung läuft leicht mit: Essenszeiten richten sich nach Training und Terminen, dazu der Tipp des Tages. Keine Speisepläne, kein Zählen. Grund: Der Vorsprung ist die Trainingsintelligenz, und der Plan soll machbar bleiben. | 2026-10-15 |
| Wann macht die KI das Training wegen Schlaf/Energie leichter? | **Bei klarem Muster.** Erst ab einem klaren Muster aus den Check-ins (z. B. 2 schlechte Nächte hintereinander oder mehrere müde Tage) plant die KI leichter. Ein einzelner schlechter Tag reicht nicht. So darf die KI nachgeben („Keine Ausreden“ heißt nicht „kein Nachgeben“), ohne unnötig Fortschritt zu verlieren. | 2026-10-15 |
| Wer legt die Mahlzeiten fest? | **Nutzer gibt die Zahl vor, die KI plant.** Der Nutzer gibt einmal an, wie viele Mahlzeiten er am Tag essen möchte. Zusammen mit seinem kcal-Ziel (beides wird in der App angezeigt, siehe [[Main Feed]]) stellt die KI daraus die Mahlzeiten im Tagesplan dar, angepasst an Termine und Arbeit. | 2026-10-15 |
| Kalorien pro Mahlzeit anzeigen? | **Nein, nur Zeit + Größe.** Jede Mahlzeit zeigt Uhrzeit und Größe in Worten (z. B. „Hauptmahlzeit“, „kleiner Snack“). Das kcal-Ziel steuert im Hintergrund, wie groß die Mahlzeiten sind. Kein Zählen. | 2026-10-15 |

## Entwurf

- Seite „Heute“ mit Tagesplan (Beispieltag, 2026-10-15): https://claude.ai/artifact/919CYY84MWcJ2HX2gAWgHG. Phillip: „top“.

## Aus der Notiz, noch nicht besprochen

- Schlaf in der Tagesansicht (wie er im Tagesplan auftaucht).
- Hintergrund (Phillip): Vorsprung ist die Trainingsintelligenz: KI-Kalender gibt es schon (Motion, Reclaim, Google/Apple), die Kombination mit Trainingssteuerung und Essen nicht.
- Erster Test ohne App: 4 Wochen mit Claude planen, notieren, wie oft kein Training ausgefallen ist; dazu Content „So plant KI meine Woche“.
