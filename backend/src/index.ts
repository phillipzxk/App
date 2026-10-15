// Groundset coach: receives the app's texts, asks Claude and returns the
// answer. The Anthropic key lives only here as a Worker secret, never in
// the app.
import Anthropic from "@anthropic-ai/sdk";
import {
  COACH_STYLE,
  checkInPrompt,
  feedPrompt,
  onboardingPrompt,
  type CheckIn,
  type Profile,
} from "./prompts";

export interface Env {
  ANTHROPIC_API_KEY: string;
  /// Shared with the app; keeps random callers from spending the credit.
  APP_TOKEN: string;
}

// Chosen with Phillip on 2026-10-14: cheapest model for the test phase.
const MODEL = "claude-haiku-5-5";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "content-type, x-app-token",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", ...CORS },
  });

async function ask(env: Env, prompt: string): Promise<string> {
  const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  const response = await client.messages.create({
    model: MODEL,
    max_tokens: 4000,
    system: COACH_STYLE,
    messages: [{ role: "user", content: prompt }],
  });
  if (response.stop_reason === "refusal") return "";
  return response.content
    .flatMap((b) => (b.type === "text" ? [b.text] : []))
    .join("")
    .trim();
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") return new Response(null, { headers: CORS });
    if (request.method !== "POST") return json({ error: "method" }, 405);
    if (!env.APP_TOKEN || request.headers.get("x-app-token") !== env.APP_TOKEN) {
      return json({ error: "unauthorized" }, 401);
    }

    let body: Record<string, unknown>;
    try {
      body = (await request.json()) as Record<string, unknown>;
    } catch {
      return json({ error: "bad json" }, 400);
    }
    const profile = (body.profile ?? {}) as Profile;

    let prompt: string;
    switch (new URL(request.url).pathname) {
      case "/onboarding":
        prompt = onboardingPrompt(profile);
        break;
      case "/checkin":
        prompt = checkInPrompt(
          profile,
          (body.today ?? {}) as CheckIn,
          Array.isArray(body.recent) ? (body.recent as CheckIn[]) : [],
        );
        break;
      case "/feed":
        prompt = feedPrompt(
          profile,
          String(body.bereich ?? ""),
          String(body.text ?? ""),
          String(body.context ?? ""),
        );
        break;
      default:
        return json({ error: "not found" }, 404);
    }

    try {
      return json({ text: await ask(env, prompt) });
    } catch (e) {
      console.error(e);
      return json({ error: "coach unavailable" }, 502);
    }
  },
};
