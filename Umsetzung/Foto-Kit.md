---
title: Foto-Kit (Framework by Groundset)
tags: [umsetzung, foto, foto-kit, start-up, gestrichen]
status: gestrichen
erstellt: 2026-10-17
aktualisiert: 2026-10-31
---

# Foto-Kit „Framework (by Groundset)“ mit der App verbinden

> [!warning] Gestrichen am 2026-10-31
> Phillip: Das Frame Kit wird es nicht geben, weil er ein anderes Start-up gründet. Alles zum Kit (Code, Kit-Posen, Kit-Zeile, Kit-Karte) ist aus der App entfernt. Es bleibt nur das einfache Fortschrittsfoto, und das System zum Fotografieren bleibt wie beschlossen (fester Fototag, Nachholen am nächsten Tag, Umriss des letzten Fotos, Auslösen von selbst in der Handy-Version, Vergleich mit Schieberegler, Zeitraffer). Siehe [[Dein zukünftiges Ich]]. Der Rest dieser Notiz ist nur noch Archiv.

Phillips Start-up-Produkt zum Fotografieren: Matte mit Fußmarken, zwei Markern (ArUco) und Graufeld, Abstandsband 1,5 m, Stativ mit LED-Licht, Handyhalter, Tasche. Verkauf laut Wartelisten-Seite als **Framework Mat (29 €)** und **Framework Kit (59 €)**, beide mit App-Code. Fester Rhythmus „Frame Sunday“. Quelle: Phillips Produktskizze vom 15.10.2026 (App-Teile als Auszug im Projektordner `foto-kit/Produktskizze-App-Teile.md`). Gehört zu [[Dein zukünftiges Ich]].

Am 2026-10-17 mit Phillip Schritt für Schritt ausgearbeitet.

## Festgelegt

| Punkt | Entscheidung | Datum |
|---|---|---|
| Was schaltet der Code im Kit frei? | **Beides:** die Kit-Funktionen dauerhaft und dazu einen Monat Groundset gratis. So bringt jedes Kit einen App-Nutzer. | 2026-10-17 |
| Wie merkt die App, dass mit Kit fotografiert wird? | **Automatisch:** Nach dem Code erkennt die Kamera die Matte (Marker) von selbst und richtet das Foto aus, ohne Knopf. Ohne Kit läuft die normale Handy-Kamera wie bisher. | 2026-10-17 |
| Posen mit Kit | **Vorausgewählt:** vorne, Seite und hinten (passend zu den Fußmarken), einzelne lassen sich abwählen. Ohne Kit bleiben die Posen frei wählbar. | 2026-10-17 |
| Welcher Umriss liegt über der Kamera? | **Letztes Foto:** der Umriss der Vorwoche, ausgelöst wird, wenn man wie letzte Woche steht. Gilt für alle, mit und ohne Kit (ersetzt „Umriss des ersten Fotos“). | 2026-10-17 |
| Vergleiche auf „Dein zukünftiges Ich“ | **Alle drei** kommen dazu: Schieberegler zwischen zwei Wochen, Zeitraffer aller Wochen, Teilen-Knopf für Social Media. Geteilt wird nur, wenn man selbst tippt. Gilt für alle. | 2026-10-17 |
| Fototermin im Tagesplan | **Fest im Plan:** Am Fototag steht morgens „Foto“ in „Dein Tag“ und wird nie verschoben ([[Tages-Planer]]). Nachholen einmal am Folgetag bleibt. | 2026-10-17 |
| Werbung fürs Kit in der App (Phillips Idee) | **Feste Zeile:** Beim Foto machen steht für Nutzer ohne Kit immer eine kleine goldene Zeile mit Link zum Shop, kein Pop-up. | 2026-10-17 |
| Text der Zeile | „Für 100 % vergleichbare Fotos: das Frame Kit ›“ | 2026-10-17 |

## Was das Kit für die App liefern muss (aus der Skizze)

- 2 bis 4 ArUco-Marker an festen Positionen und in fester Größe (Prototyp: je 8 cm).
- Neutralgraues Feld als Referenz für Farbe und Helligkeit.
- Feste Maße: Band 1,5 m, Stativhöhen, Lichtwinkel.
- Freischalt-Code in der Verpackung.

## Offen

- Wo man den Code eingibt (Vorschlag für den Entwurf: Einstellungen auf „Dein zukünftiges Ich“).
- Shop-Link (Wartelisten-Seite) für die Kit-Zeile.
- Marker-Erkennung, Ausrichten, Umriss und Auto-Auslöser laufen erst in der Handy-Version.

## Stand im Code (2026-10-17)

In der App seit 17.10.2026 (Phillip: „Okay weiter“ nach der Vorschau):
- **Dein Tag:** Am Fototag (und am Nachholtag) steht oben „früh · Foto · Woche N“, tippen öffnet die Fotoseite.
- **Foto machen:** ohne Kit die goldene Zeile „Für 100 % vergleichbare Fotos: das Frame Kit ›“ (tippen zeigt ein Info-Fenster zum Kit), mit Kit das Feld „Frame Kit aktiv“. Neben jeder Pose liegt das Foto der Vorwoche.
- **Dein zukünftiges Ich:** Vergleich mit Schieberegler und zwei wählbaren Wochen, Zeitraffer, Teilen. Unten „Frame Kit · Code aus dem Kit eingeben“; danach sind vorne, Seite und hinten als Posen gesetzt.
- **Name in der App:** „Frame Kit“ (Phillip, 17.10.2026). Im Info-Fenster stehen noch die Shop-Namen „Framework Mat/Kit“.
- **Platzhalter:** Code-Prüfung (jeder Code ab 6 Zeichen, bis der Shop echte Codes hat), Teilen, Matte erkennen, Ausrichten und Auto-Auslöser (Handy-Version), Shop-Link.
