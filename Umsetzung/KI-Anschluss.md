---
title: KI-Anschluss
tags: [umsetzung, ki, backend]
stand: 2026-10-14
status: Anleitung an Phillip geschickt, wartet auf Karte und Schlüssel
---

# KI-Anschluss

So funktioniert es: Die App schickt deine Check-in-Antworten an einen kleinen Vermittler im Internet. Der fragt die KI (Claude von Anthropic) und gibt die Antwort an die App zurück. Der Vermittler ist nötig, weil der geheime KI-Schlüssel nie in der App selbst stecken darf, sonst könnte ihn jeder auslesen und auf deine Kosten benutzen.

Du brauchst zwei Konten. Den Rest programmiere ich.

## Was du vorher brauchst

Eine Karte, die online bezahlen kann: eine Visa- oder Mastercard-Debitkarte von deiner Bank oder eine kostenlose virtuelle Karte von N26 oder Revolut. Die Maestro-Karte geht leider nicht.

## Schritt 1: KI-Konto bei Anthropic (kostet Guthaben)

1. Geh auf console.anthropic.com und leg ein Konto an.
2. Unter **Billing** lädst du einmal den kleinsten Betrag auf (meist 5 Dollar). Mehr musst du nicht ausgeben: Mit dem günstigen Modell Claude Haiku 5.5 kostet eine Coach-Antwort weniger als 0,1 Cent. 5 Dollar reichen damit für viele tausend Antworten, beim Testen also für Monate.
3. Unter **Limits** stellst du ein niedriges monatliches Limit ein, zum Beispiel 5 Dollar. Dann kann nie mehr abgebucht werden. Es gibt kein Abo, abgebucht wird nur, was du selbst auflädst.
4. Unter **API Keys** klickst du auf **Create Key** und nennst ihn „Groundset“. Kopier den Schlüssel (er beginnt mit `sk-ant-`). Er wird nur einmal angezeigt.

## Schritt 2: Vermittler bei Cloudflare (kostenlos, keine Karte nötig)

1. Geh auf dash.cloudflare.com und leg ein kostenloses Konto an.
2. Klick oben rechts auf dein Profil, dann **API Tokens**, dann **Create Token**.
3. Wähl die Vorlage **Edit Cloudflare Workers**, klick auf **Continue to summary** und dann **Create Token**. Kopier den Token.
4. Auf der Startseite von Cloudflare siehst du unter **Workers & Pages** rechts deine **Account ID**. Kopier sie auch.

## Schritt 3: Die drei Werte sicher eintragen (nicht in den Chat)

Schick mir die Schlüssel bitte nie hier im Chat. So trägst du sie sicher ein:

1. Öffne die Projekt-Einstellungen, Bereich **Cloud environment**.
2. Wähl im Menü **Add cloud environment**.
3. Trag diese drei Umgebungsvariablen ein, jede in eine eigene Zeile:
   - `ANTHROPIC_API_KEY` = dein Schlüssel aus Schritt 1
   - `CLOUDFLARE_API_TOKEN` = der Token aus Schritt 2
   - `CLOUDFLARE_ACCOUNT_ID` = die Account ID aus Schritt 2
4. Speichern. Die neue Umgebung gilt für Unterhaltungen, die danach starten.
5. Schreib mir dann einfach „Schlüssel sind drin“.

## Was ich danach mache

1. Ich baue den Vermittler und stelle ihn bei Cloudflare online. Den KI-Schlüssel lege ich dort als Geheimnis ab, er landet nie in der App.
2. Ich schließe nacheinander an: die Antwort zum Check-in, „So sehe ich dich gerade“ nach dem Onboarding und die Coach-Felder auf den 5 Seiten. Alles im Coach-Stil, den wir festgelegt haben.
3. Du testest in der Vorschau mit echten Antworten. Was dir nicht gefällt, ändern wir zusammen.

## Ganz ohne Geld

Komplett kostenlos geht es nur mit einem freien KI-Modell direkt bei Cloudflare (kleines Gratis-Kontingent pro Tag, keine Karte). Das schreibt aber deutlich schwächeres Deutsch und trifft den Coach-Stil schlechter. Für Tests mit echten Nutzern würde ich es nicht nehmen.

## Alternative zu Cloudflare

Statt Cloudflare ginge auch Firebase von Google. Das braucht aber zusätzlich den Bezahl-Tarif „Blaze“ mit Karte und ist umständlicher einzurichten. Für den Anfang ist Cloudflare einfacher.

Siehe auch [[Coach-Stil]] und [[Design]].
