---
tags: [umsetzung, beta]
---
# Beta für Tester

Entschieden am 2026-11-20 mit Phillip: **beides kostenlos**. Entwurf der Einladung: https://claude.ai/artifact/By2MH3aBvhk8BKh7SFnmCD ("okay weiter").

## Wie Tester die App bekommen
- Ein Link für alle: `…/beta/` der Vorschau. Die Seite erkennt das Handy selbst.
- **iPhone:** Web-App über Safari > Teilen > Zum Home-Bildschirm. Widgets und Wecker kommen erst mit der iPhone-App.
- **Android:** echte App (APK) direkt von der Seite, ohne Play Store.

## In der App
- **Neue Version da:** Die Android-App prüft beim Start `beta/version.json`. Ist eine neuere Build-Nummer da, erscheint eine goldene Karte mit „Jetzt laden“.
- **Feedback geben:** In den Einstellungen (Gruppe „Beta“). Die Nachricht geht an den Coach-Server und wird dort gesammelt. Claude fasst sie für Phillip zusammen.

## Technik
- Android-Name „Groundset“, Groundset-Logo, dunkler Startbildschirm.
- Gebaut wird mit dem Workflow „Android-Beta bauen“ (von Hand gestartet). Danach wird die App mit dem Beta-Schlüssel signiert. Der Schlüssel liegt nur in den Projektdateien (`.notes/beta-key`), nie im Repo. Ohne ihn lassen sich keine Updates installieren.
- Offen: Impressum und Datenschutz.
