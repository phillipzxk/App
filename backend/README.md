# Groundset Coach (Backend)

Kleiner Vermittler zwischen der App und der KI (Claude Haiku 5.5). Läuft als Cloudflare Worker. Der KI-Schlüssel liegt nur hier als Geheimnis, nie in der App. Anleitung für Phillip: [[KI-Anschluss]].

Die App ruft drei Adressen auf, jeweils `POST` mit JSON und dem Kopf `x-app-token`:

| Adresse | Wofür | Inhalt |
|---|---|---|
| `/onboarding` | „So sehe ich dich gerade“ | `profile` |
| `/checkin` | Antwort zum Tag | `profile`, `today`, `recent` |
| `/feed` | Coach-Felder auf den 5 Seiten | `profile`, `bereich`, `text`, `context` |

Antwort immer `{"text": "..."}`. Wie der Coach schreibt, steht in `src/prompts.ts` und kommt aus [[Coach-Stil]].

## Online stellen

Braucht die Umgebungsvariablen `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` und `ANTHROPIC_API_KEY`.

```bash
npm install
npx tsc --noEmit
npx wrangler deploy
printf %s "$ANTHROPIC_API_KEY" | npx wrangler secret put ANTHROPIC_API_KEY
APP_TOKEN=$(openssl rand -hex 16)
printf %s "$APP_TOKEN" | npx wrangler secret put APP_TOKEN
```

Danach die App mit Adresse und Token bauen:

```bash
flutter build web --dart-define=COACH_URL=https://groundset-coach.<konto>.workers.dev --dart-define=COACH_TOKEN=$APP_TOKEN
```

Der App-Token ist kein echtes Geheimnis (er steckt in der App), er hält nur zufällige Aufrufer fern. Den eigentlichen Schutz gibt das Ausgabenlimit bei Anthropic.

## Lokal testen

`.dev.vars` mit `ANTHROPIC_API_KEY=...` und `APP_TOKEN=...` anlegen, dann `npx wrangler dev`.
