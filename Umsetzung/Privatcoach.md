---
title: Privatcoach
tags: [umsetzung, coach, chat]
erstellt: 2026-11-21
aktualisiert: 2026-11-21
---

# Privatcoach

Echtes 1:1 Coaching mit Phillip direkt in der App. Ablauf mit Phillip abgestimmt (Entwurf https://claude.ai/artifact/TDxBV8yMDcAtWdTuBTLUAD), Bau gewählt am 2026-11-21.

## Festgelegt
- Der Nutzer schreibt direkt im Chat. Beim ersten Senden fragt die App: „Darf Phillip deine Werte sehen?“ (Erlauben oder nur die Nachricht).
- Die erste Nachricht ist eine Anfrage. Phillip nimmt sie an.
- Phillip nutzt dieselbe App. Sein Konto hat zusätzlich einen Posteingang (Alle / Ungelesen, goldene Punkte).
- Die Werte des Nutzers erscheinen im Chat als Karte. Sie öffnet eine Übersicht (Bereiche, Schlaf, Muster, Fokus, Ziel, Warum) mit „Fokus anpassen“. Der angepasste Fokus erscheint beim Nutzer als „Von Phillip angepasst“.
- Vor dem Annehmen: kleines „P“ mit „1:1“ in der Ecke über dem Plus. Danach: „P“ in der unteren Leiste mit Zahl der ungelesenen Nachrichten.
- Echtheit: goldenes Siegel, „Echter Mensch · keine KI“. Nur Phillips Konto darf als Phillip schreiben (Server prüft das).
- Benachrichtigungen auf beiden Seiten, auch für verpasste Nachrichten: Pflicht.
- Vorerst kein Foto, das goldene „P“ bleibt (Phillip 2026-11-21).

## Annahmen von Claude (nicht widersprochen)
- „Antwortet meist am selben Tag“ unter Phillips Namen.
- Testphase mit 5 Plätzen, danach „Gerade voll“.

## Stand im Code
- Server (Supabase): Tabellen `coach_rollen`, `coach_einstellungen`, `coach_chats`, `coach_nachrichten`, privater Speicher `coach-audio`; siehe `backend/supabase/schema.sql`.
- App: `code/lib/privatcoach/` (Daten, Dienst, Seiten), eingebaut in Heute.
- Noch offen: Benachrichtigungen (Web Push, Android über Firebase, E-Mail nach 15 Minuten ungelesen), Sprachnachrichten, Phillips Konto als Coach eintragen.
