---
title: App-Fortschritt
tags: [quellen, fortschritt, original]
quelle: https://claude.ai/artifact/G9aBBq7fWyJUhrRzCFn5qd
gespeichert: 2026-10-09
aktualisiert: 2026-10-15
---

# App-Fortschritt (Originalseite)

Wortgetreue Abschrift der Claude-Seite „App-Fortschritt“, Stand 2026-10-09; am 2026-10-15 um Phillips neue Ideen vom 14.10. ergänzt (von ihm eingefügt). Die Ideen sind noch NICHT beschlossen. Die Originaldatei mit Layout liegt daneben: [[App-Fortschritt.html]] (im Browser öffnen). Online: https://claude.ai/artifact/G9aBBq7fWyJUhrRzCFn5qd

Ausgearbeitete Notizen dazu: [[MVP-Fortschritt]], [[Roadmap nach dem MVP]], [[Datenmodell]], [[Technischer Ansatz]].

---

*Sport & Selbstoptimierung — adaptive Coaching-App*

## Die App

Täglicher **conversationeller Feed** statt starrer Formulare: Training, Ernährung/Gefühl, Schlaf, Energie. Die KI antwortet individuell, mit Gedächtnis über die letzten Tage — daraus entsteht ein **Fortschritts-Graph**, der zeigt, wie der Bedarf an Tipps über die Zeit sinkt.

### MVP-Baustellen — 1 / 5

- [x] Konzept & Datenstruktur festgelegt
- [ ] Onboarding-Fragebogen (Ziel, Level, Ausgangssituation)
- [ ] Täglicher Feed mit den vier Kernfragen
- [ ] KI-Antwort mit einfacher Regellogik
- [ ] Einfache Fortschritts-Ansicht

### 📅 Tages-Planer: Kalender + Training (Kernfeature · 14.10.)

Macht Groundset zum Betriebssystem für den Tag: Kalender, Training und Essen wissen voneinander. Ziel: Der Plan ist immer machbar, deshalb gibt es keine Ausreden mehr.

**Was es kann**
- 🗣️ Einfach schreiben: „Mathe-Klausur Donnerstag, Freitag Geburtstag“. Die KI trägt es ein, sortiert es und erinnert per Benachrichtigung.
- 🏋️ Training passt sich an: Die KI legt jede Woche Einheiten, Intensität und Volumen passend zu den Terminen fest (Klausurwoche = weniger Volumen, Ferien = Aufbauphase).
- 🍽️ Ganzer Tag sichtbar: Schule, Termine, Training, Mahlzeiten und Schlaf in einer Tagesansicht.
- 📈 Verbunden mit Tracking: Check-ins (Schlaf, Energie) fließen in die Planung der nächsten Tage ein.

**Regeln**
- 🌿 „Keine Ausreden“ heißt nicht „kein Nachgeben“: Die KI darf auch sagen „diese Woche nur 2 leichte Einheiten, Prüfungen gehen vor“.
- ⚔️ Vorsprung ist die Trainingsintelligenz. KI-Kalender gibt es schon (Motion, Reclaim, Google/Apple), die Kombination mit Trainingssteuerung und Essen nicht.

**Erster Test (ohne App)**
4 Wochen mit Claude: Termine schreiben, Claude trägt ein; jeden Sonntag die Trainingswoche passend planen. Notieren, wie oft kein Training ausgefallen ist. Gleichzeitig Content: „So plant KI meine Woche“.

### 🔮 Dein zukünftiges Ich (Herzstück · 14.10.)

Das Feature, das sonst keine App hat. Es löst den Hauptgrund, warum Leute aufgeben: Sie sehen ihren Fortschritt nicht (Buch: Kapitel 9, Testfrage 7).

**Was es kann**
- 📸 Wöchentlicher Body-Scan: Foto mit gleicher Pose und gleichem Licht. Die KI zeigt Veränderungen, die man mit bloßem Auge nicht sieht.
- 🔮 Zukunfts-Projektion: Aus den Check-in-Daten zeigt die App realistisch, wie man in 3, 6 und 12 Monaten aussieht, wenn man so weitermacht.
- 💪 Leistung + Ästhetik zusammen: Kraft und Ausdauer stehen neben dem Aussehen (These aus Kapitel 5).
- 📈 Ergänzt den Fortschritts-Graphen: Der zeigt „weniger Tipps nötig“, der Scan zeigt „der Körper verändert sich“.

**Regeln**
- ⚠️ Die Projektion bleibt realistisch, lieber zu vorsichtig als zu optimistisch.
- 🧠 Fotos sind freiwillig. Es gibt auch eine Version nur mit Leistungsdaten.
- 🌿 Kein Druck: Ruhetage feiern, keine Optimierungsfalle.

**Erster Test (ohne App)**
8 Wochen an mir selbst: jede Woche ein Foto, gleiche Pose, gleiches Licht, Vergleich mit Claude. Gleichzeitig Content: „So sehe ich laut KI in 6 Monaten aus“.

### Später — nicht Teil des MVP

- Freischaltbare, tiefere Coaching-Tipps (Monetarisierung)
- Erinnerungen / Notifications fürs tägliche Tracking
- Datenschutzerklärung, Name/Branding
- Verbindung zu Buch & Content, Community-Elemente
- Hybrid-Progressions-Engine: Powerlifting, Calisthenics und Ausdauer kombinieren, ohne dass sie sich ausbremsen
- KI-Formcheck per Handykamera (Reps, Bar-Path, Tempo)

### Datenmodell

Ein Nutzer hat viele Check-ins, jeder Check-in genau eine KI-Antwort. Der Fortschritts-Graph wird direkt daraus aggregiert — keine eigene Tabelle.

| Nutzer | → | Check-in (täglich) | → | KI-Antwort |
|---|---|---|---|---|
| Name, E-Mail | | Training (Freitext) | | Feedback-Text |
| Abo-Status | | Ernährung/Gefühl (Freitext) | | einfach / tief (bezahlt) |
| Ziel & Level (Onboarding) | | Schlaf & Energie (Freitext) | | Bewertungs-Kennzahl 1–10 |

### Technischer Ansatz

- **FlutterFlow** — No-Code UI
- **LLM-API** — Antworten & Bewertung
- Flatrate-Abo, 9,99 €/Monat

*Bewusst weggelassen: Lebensmittel- oder Übungsdatenbank, Kalorien-/Makro-Felder*
