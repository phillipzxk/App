---
thema: Konto und Sicherung
stand: 2026-11-01
status: Entwurf beschlossen, Bau folgt
---

# Konto und Sicherung (Handy-Version)

Zusammen mit Phillip Schritt für Schritt festgelegt (2026-10-31 und 2026-11-01). Teil der Vorbereitung auf die Beta, siehe [[Release-Plan]].

## Beschlüsse

1. **Anmeldung:** mit Apple, mit Google oder mit E-Mail-Code (6 Zahlen per Mail). Kein Passwort.
2. **Wann:** direkt nach dem Fragebogen, nach „So sehe ich dich gerade“, vor dem ersten Check-in. Wer schon ein Konto hat (neues Handy), tippt am Anfang „Ich habe schon ein Konto“.
3. **Was gesichert wird:** alles, auch Fortschrittsfotos und Form-Videos. Fotos und Videos lassen sich in den Einstellungen abschalten.

## Entwurf 2 (Phillip „Ja passt“ 2026-11-01)

https://claude.ai/artifact/XbTtdMtYepwTj4REPTY7oK

Entwurf 1 war Phillip zu schlicht. In Entwurf 2:

- **Start:** echtes Groundset-Logo baut sich auf (Boden, Wurzeln, Trieb, Blätter), „Bau dein Fundament fürs Leben.“, ein Satz darunter. Knöpfe: Apple (gold), Google (Glas), E-Mail-Code. „Kein Passwort. Deine Daten gehören dir.“
- **E-Mail:** kleiner Brief fliegt los, die 6 Code-Felder füllen sich golden, „Stimmt, du bist drin“, geht automatisch weiter. Coach-Satz zum Code.
- **Gesichert:** Logo wächst, Wurzeln leuchten, goldener Ring und Funken. „Phillip, dein Fundament steht.“, darunter das eigene Ziel aus dem Fragebogen und der Coach-Satz „Alles, was du mir erzählt hast, ist jetzt sicher. Ab heute wächst dein Fundament jeden Tag ein Stück.“, Knopf „Zum ersten Check-in“.
- **Einstellungen „Konto und Sicherung“:** Status (zuletzt gesichert, Größe, was alles, „Jetzt sichern“), Konto (Name, E-Mail, Anmeldeart), Abo ansehen und kündigen, angemeldete Geräte, Fotos und Videos sichern, nur im WLAN hochladen, Meine Daten herunterladen, Datenschutz, Impressum, Abmelden, Konto und alle Daten löschen.
- Hintergrund überall ruhig mit einem warmen, atmenden Licht, alles auf Glas.

## Technik

- Die App speichert weiter zuerst auf dem Handy und lädt Neues im Hintergrund hoch, sobald Netz da ist. Fotos und Videos verschlüsselt.
- Pflicht für die Stores: Konto löschen in der App (Apple), Daten herunterladen (DSGVO), Datenschutz und Impressum.
- Für Apple-Anmeldung und App Store braucht Phillip ein Apple-Entwicklerkonto (99 € im Jahr).
- Server-Anbieter: **Supabase, Server in Frankfurt** (Phillip 2026-11-01). Projekt „groundset“ angelegt.

## Stand im Code (2026-11-01)

- Ordner `code/lib/konto/`: Anmeldung (Apple, Google, E-Mail-Code), Sicherung, Bildschirme, Einstellungen.
- Ablauf: Fragebogen → „So sehe ich dich gerade“ → Konto → erster Check-in. Unter dem ersten Fragebogen-Schritt „Ich habe schon ein Konto“: anmelden und alles zurückholen („Phillip, alles ist wieder da.“).
- Gesichert wird automatisch beim Öffnen, nach dem Check-in, wenn die App in den Hintergrund geht (höchstens alle 2 Minuten) und mit „Jetzt sichern“. Zwei Dateien: Daten, und Fotos/Videos (abschaltbar).
- Einstellungen öffnen sich über den runden Knopf mit dem Anfangsbuchstaben oben rechts auf Heute.
- Server-Vorlage: `backend/supabase/schema.sql` (privater Speicher „sicherungen“, jeder sieht nur seinen eigenen Ordner, Konto-Löschen).
- Vorschau läuft noch ohne Server: jeder 6-stellige Code geht, nichts verlässt das Gerät.
- Noch offen: Supabase einrichten und echt testen (neuer Thread mit Phillips Supabase-Zugang), Google-Anmeldung einrichten, Apple-Entwicklerkonto, Texte für Datenschutz und Impressum, Abo kommt mit den Stores.
