---
tags: [umsetzung, marketing]
stand: 2026-11-04
---
# Warteliste

Öffentliche Seite, auf der sich Leute vor dem Start eintragen. Phillip hat Entwurf 3 am 2026-11-04 freigegeben („jo“) und gesagt, dass sie online gehen soll.

- **Adresse:** https://groundset-warteliste.pzschernack4.workers.dev (Cloudflare Worker `groundset-warteliste`, kostenlos)
- **Entwurf:** https://claude.ai/artifact/96QXezbvXWbcxfrQeDb7qN
- **Code:** Ordner `warteliste/` im Repository (`worker.js`, `public/index.html`, `schema.sql`)

## Inhalt
1. Überschrift „Du weißt, was zu tun ist. Und stagnierst trotzdem.“ plus zwei Sätze, darunter das E-Mail-Feld.
2. **Was drin ist:** „Training, Ernährung, Schlaf, Fokus, Mindset, Business und Persönlichkeit in einer App. Ein KI-Coach sieht alles zusammen, zeigt dir jeden Tag, woran es wirklich hängt, und macht dich Schritt für Schritt selbstständig.“ (siehe [[Kern der App]])
3. **Kennst du das?** 5 Alltagssituationen zum Antippen. Unter jeder steht in Gold, was Groundset dabei sieht. Danach kommt der Zähler „X von 5 passen zu dir“.
4. **So läuft es:** Check-in, Coach, Selbstständig.
5. Das E-Mail-Feld noch einmal, mit „Die erste Woche ist gratis, danach 9,99 € im Monat“ (siehe [[Abo]]).

## Technik
- Die E-Mails landen in Supabase (Frankfurt), Tabelle `warteliste`. Ansehen kann man sie im Supabase-Dashboard unter Table Editor → warteliste.
- Die Seite darf nur eintragen, nicht lesen. Doppelte E-Mails werden ignoriert. Ein verstecktes Feld hält einfache Bots ab.

## Offen
- Impressum und Datenschutz fehlen noch. Sie werden verlinkt, sobald Phillips Angaben da sind. Bis dahin sollte die Seite nicht groß öffentlich geteilt werden.
- Bevor jemand eine Werbe-Mail bekommt, braucht es eine Bestätigungs-Mail (Double-Opt-in).
