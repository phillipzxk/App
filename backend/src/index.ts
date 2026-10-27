// Groundset coach: receives the app's texts, asks Claude and returns the
// answer. The Anthropic key lives only here as a Worker secret, never in
// the app.
import Anthropic from "@anthropic-ai/sdk";
import {
  COACH_STYLE,
  checkInPrompt,
  feedPrompt,
  onboardingPrompt,
  wertePrompt,
  musterPrompt,
  type BisherMuster,
  fokusPrompt,
  stichpunktePrompt,
  durchgezogenPrompt,
  warumPrompt,
  tagesformPrompt,
  vorschlagPrompt,
  stagnationPrompt,
  balancePrompt,
  formPrompt,
  verlaufPrompt,
  zusammenhangPrompt,
  heisshungerPrompt,
  tellerPrompt,
  kuehlschrankPrompt,
  rettungPrompt,
  gewichtPrompt,
  type LetzterFokus,
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

async function ask(env: Env, prompt: string, bilder: string[] = []): Promise<string> {
  const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  const response = await client.messages.create({
    model: MODEL,
    max_tokens: 4000,
    system: COACH_STYLE,
    messages: [
      {
        role: "user",
        content: bilder.length
          ? [
              ...bilder.map((data) => ({
                type: "image" as const,
                source: { type: "base64" as const, media_type: "image/jpeg" as const, data },
              })),
              { type: "text" as const, text: prompt },
            ]
          : prompt,
      },
    ],
  });
  if (response.stop_reason === "refusal") return "";
  return response.content
    .flatMap((b) => (b.type === "text" ? [b.text] : []))
    .join("")
    .trim();
}

const AREAS = ["training", "ernaehrung", "schlaf", "mindset"] as const;

/// Keeps only well-formed scores 1-10 and short reasons from the model's JSON.
export function parseWerte(raw: string): Record<string, { wert: number; grund: string }> {
  const start = raw.indexOf("{");
  const end = raw.lastIndexOf("}");
  if (start < 0 || end <= start) return {};
  let data: Record<string, unknown>;
  try {
    data = JSON.parse(raw.slice(start, end + 1));
  } catch {
    return {};
  }
  const out: Record<string, { wert: number; grund: string }> = {};
  for (const a of AREAS) {
    const v = data[a] as { wert?: unknown; grund?: unknown } | undefined;
    const wert = Math.round(Number(v?.wert));
    if (!Number.isFinite(wert) || wert < 1 || wert > 10) continue;
    out[a] = { wert, grund: typeof v?.grund === "string" ? v.grund.trim().slice(0, 300) : "" };
  }
  return out;
}

const LABELS = ["Training", "Ernährung", "Schlaf", "Mindset"];

/// One pattern with text and step, or null when the model saw nothing clear.
export function parseMuster(
  raw: string,
): { text: string; schritt: string; von: string; nach: string } | null {
  const start = raw.indexOf("{");
  const end = raw.lastIndexOf("}");
  if (start < 0 || end <= start) return null;
  try {
    const m = (JSON.parse(raw.slice(start, end + 1)) as { muster?: unknown }).muster as
      | Record<string, unknown>
      | null
      | undefined;
    if (!m) return null;
    const text = typeof m.text === "string" ? m.text.trim().slice(0, 300) : "";
    const schritt = typeof m.schritt === "string" ? m.schritt.trim().slice(0, 300) : "";
    if (!text || !schritt) return null;
    const area = (v: unknown) => (typeof v === "string" && LABELS.includes(v.trim()) ? v.trim() : "");
    return { text, schritt, von: area(m.von), nach: area(m.nach) };
  } catch {
    return null;
  }
}

type FokusVorschlag = { text: string; warum: string; behalten: boolean };

/// Up to 3 suggestions; with an old focus exactly one keeps its text.
export function parseFokus(
  raw: string,
  letzter: string,
): { rueckblick: string | null; bremse: string | null; vorschlaege: FokusVorschlag[] } {
  const start = raw.indexOf("{");
  const end = raw.lastIndexOf("}");
  let data: Record<string, unknown> = {};
  if (start >= 0 && end > start) {
    try {
      data = JSON.parse(raw.slice(start, end + 1));
    } catch {
      data = {};
    }
  }
  const str = (v: unknown, max: number) =>
    typeof v === "string" ? v.trim().slice(0, max) : "";
  const satz = (s: string) => (s && !/[.!?]$/.test(s) ? `${s}.` : s);
  const list = Array.isArray(data.vorschlaege) ? data.vorschlaege : [];
  let out: FokusVorschlag[] = [];
  for (const v of list) {
    const o = (v ?? {}) as Record<string, unknown>;
    const text = str(o.text, 120).replace(/\.$/, "");
    if (!text) continue;
    out.push({ text, warum: satz(str(o.warum, 200)), behalten: o.behalten === true });
  }
  if (letzter) {
    const keep = out.find((v) => v.behalten) ?? out.find((v) => v.text === letzter);
    out = out
      .filter((v) => v !== keep && v.text !== letzter)
      .map((v) => ({ ...v, behalten: false }));
    // Reality Check: the one change first, then keeping the old focus.
    out = [...out.slice(0, 1), { text: letzter, warum: keep?.warum ?? "", behalten: true }, ...out.slice(1)];
  } else {
    out = out.map((v) => ({ ...v, behalten: false }));
  }
  const rueckblick = letzter ? satz(str(data.rueckblick, 300)) : "";
  const bremse = letzter ? satz(str(data.bremse, 400)) : "";
  return { rueckblick: rueckblick || null, bremse: bremse || null, vorschlaege: out.slice(0, 3) };
}

/// 2 to 4 short points, or an empty list.
export function parsePunkte(raw: string): string[] {
  const start = raw.indexOf("{");
  const end = raw.lastIndexOf("}");
  if (start < 0 || end <= start) return [];
  try {
    const list = (JSON.parse(raw.slice(start, end + 1)) as { punkte?: unknown }).punkte;
    if (!Array.isArray(list)) return [];
    return list
      .filter((p): p is string => typeof p === "string" && p.trim() !== "")
      .map((p) => p.trim().replace(/^[-•*]\s*/, "").slice(0, 160))
      .slice(0, 4);
  } catch {
    return [];
  }
}

/// The coach's sentence for "Dein Warum", or null on a normal day.
export function parseSatz(raw: string): string | null {
  const start = raw.indexOf("{");
  const end = raw.lastIndexOf("}");
  if (start < 0 || end <= start) return null;
  try {
    const s = (JSON.parse(raw.slice(start, end + 1)) as { satz?: unknown }).satz;
    return typeof s === "string" && s.trim() ? s.trim().slice(0, 220) : null;
  } catch {
    return null;
  }
}

/// One short entry, or null.
export function parseEintrag(raw: string): string | null {
  const start = raw.indexOf("{");
  const end = raw.lastIndexOf("}");
  if (start < 0 || end <= start) return null;
  try {
    const e = (JSON.parse(raw.slice(start, end + 1)) as { eintrag?: unknown }).eintrag;
    return typeof e === "string" && e.trim() ? e.trim().slice(0, 200) : null;
  } catch {
    return null;
  }
}

/// The first JSON object in the model's answer, or {}.
export function parseObjekt(raw: string): Record<string, unknown> {
  const start = raw.indexOf("{");
  const end = raw.lastIndexOf("}");
  if (start < 0 || end <= start) return {};
  try {
    const d = JSON.parse(raw.slice(start, end + 1));
    return d && typeof d === "object" ? (d as Record<string, unknown>) : {};
  } catch {
    return {};
  }
}

const text = (v: unknown, max = 400): string | null =>
  typeof v === "string" && v.trim() ? v.trim().slice(0, max) : null;
/// Cut at a word, never in the middle of one.
const kurz = (v: unknown, max: number): string | null => {
  const t = text(v, 1000);
  if (!t || t.length <= max) return t;
  const cut = t.slice(0, max);
  return cut.slice(0, cut.lastIndexOf(" ") > 0 ? cut.lastIndexOf(" ") : max).replace(/[,;:.\s]+$/, "");
};
const zahl = (v: unknown): number | null =>
  typeof v === "number" && Number.isFinite(v) && v >= 0 && v < 1000 ? v : null;

/// Training logging: one route, the part in "art" (vault Umsetzung/Training eintragen.md).
function gericht(v: unknown): Record<string, unknown> | null {
  const g = (v ?? {}) as Record<string, unknown>;
  const name = text(g.name, 80);
  if (!name) return null;
  const gruppen = ["Eiweiß", "Gemüse", "Obst", "Kühlregal", "Vorrat", "Sonstiges"];
  const zutaten = (Array.isArray(g.zutaten) ? g.zutaten : [])
    .map((z) => {
      const x = (z ?? {}) as Record<string, unknown>;
      const n = text(x.name, 60);
      if (!n) return null;
      const gr = String(x.gruppe ?? "");
      return { name: n, menge: zahl(x.menge), einheit: text(x.einheit, 12) ?? "", gruppe: gruppen.includes(gr) ? gr : "Sonstiges" };
    })
    .filter(Boolean)
    .slice(0, 10);
  const schritte = (Array.isArray(g.schritte) ? g.schritte : []).map((s) => text(s, 200)).filter(Boolean).slice(0, 6);
  const art = ["Frühstück", "Hauptmahlzeit", "Snack"].includes(String(g.art)) ? String(g.art) : "Hauptmahlzeit";
  return { name, art, dauer: zahl(g.dauer), gegen: kurz(g.gegen, 60), warum: text(g.warum, 300), zutaten, schritte };
}

export async function ernaehrung(env: Env, body: Record<string, unknown>, profile: Profile): Promise<unknown> {
  const recent = Array.isArray(body.recent) ? (body.recent as CheckIn[]) : [];
  const bild = (v: unknown) => (typeof v === "string" && v.length > 100 && v.length < 600000 ? [v] : []);
  switch (body.art) {
    case "zusammenhang":
      return {
        satz: text(
          parseObjekt(await ask(env, zusammenhangPrompt(profile, recent, String(body.heisshunger ?? ""), String(body.schlaf ?? "")))).satz,
          300,
        ),
      };
    case "heisshunger":
      return {
        schritt: text(
          parseObjekt(
            await ask(env, heisshungerPrompt(profile, String(body.grund ?? ""), String(body.uhrzeit ?? ""), String(body.kontext ?? ""))),
          ).schritt,
          400,
        ),
      };
    case "teller": {
      const b = bild(body.bild);
      if (!b.length) return null;
      const d = parseObjekt(await ask(env, tellerPrompt(profile, String(body.mahlzeit ?? "")), b));
      const stufe = (v: unknown) => Math.max(0, Math.min(3, Math.round(zahl(v) ?? 0)));
      return {
        eiweiss: stufe(d.eiweiss),
        gemuese: stufe(d.gemuese),
        groesse: stufe(d.groesse),
        eiweiss_text: text(d.eiweiss_text, 200),
        gemuese_text: text(d.gemuese_text, 200),
        groesse_text: text(d.groesse_text, 200),
        tipp: text(d.tipp, 300),
      };
    }
    case "kuehlschrank": {
      const zutaten = Array.isArray(body.zutaten) ? body.zutaten.map((z) => text(z, 60)).filter(Boolean).join(", ") : "";
      const b = zutaten ? [] : bild(body.bild);
      if (!zutaten && !b.length) return null;
      const d = parseObjekt(await ask(env, kuehlschrankPrompt(profile, String(body.kontext ?? ""), zutaten), b));
      const gesehen = zutaten
        ? (body.zutaten as unknown[]).map((z) => text(z, 60)).filter(Boolean)
        : (Array.isArray(d.zutaten) ? d.zutaten : []).map((z) => text(z, 60)).filter(Boolean).slice(0, 10);
      return { zutaten: gesehen, gericht: gericht(d.gericht) };
    }
    case "rettung": {
      const anzahl = Math.max(1, Math.min(3, zahl(body.anzahl) ?? 3));
      const d = parseObjekt(await ask(env, rettungPrompt(profile, String(body.muster ?? ""), String(body.vorhanden ?? ""), anzahl)));
      return { gerichte: (Array.isArray(d.gerichte) ? d.gerichte : []).map(gericht).filter(Boolean).slice(0, anzahl) };
    }
    case "gewicht": {
      const kcal = zahl(body.kcal) ?? 0;
      const d = parseObjekt(
        await ask(env, gewichtPrompt(profile, String(body.verlauf ?? ""), kcal, String(body.grund ?? ""), String(body.kontext ?? ""))),
      );
      const roh = typeof d.kcal_neu === "number" && Number.isFinite(d.kcal_neu) ? d.kcal_neu : null;
      // A small number is the change, not the new target.
      let neu = roh === null ? null : Math.abs(roh) <= 600 ? kcal + roh : roh;
      if (neu !== null && kcal > 0) neu = Math.round(Math.max(kcal - 300, Math.min(kcal + 300, neu)) / 50) * 50;
      return { sicht: text(d.sicht, 600), vorschlag: text(d.vorschlag, 300), kcal_neu: neu };
    }
    default:
      return null;
  }
}

export async function training(env: Env, body: Record<string, unknown>, profile: Profile): Promise<unknown> {
  const recent = Array.isArray(body.recent) ? (body.recent as CheckIn[]) : [];
  switch (body.art) {
    case "tagesform": {
      const d = parseObjekt(
        await ask(env, tagesformPrompt(profile, (body.today ?? null) as CheckIn | null, recent, String(body.einheit ?? ""))),
      );
      const a = d.anpassung as Record<string, unknown> | null | undefined;
      const anpassung =
        a && text(a.uebung, 80) && text(a.grund, 200) && (zahl(a.saetze) !== null || zahl(a.wdh) !== null)
          ? { uebung: text(a.uebung, 80), saetze: zahl(a.saetze), wdh: zahl(a.wdh), grund: text(a.grund, 200) }
          : null;
      return { satz: text(d.satz, 300), anpassung };
    }
    case "vorschlag": {
      const d = parseObjekt(
        await ask(env, vorschlagPrompt(profile, String(body.uebung ?? ""), String(body.heute ?? ""), String(body.vorschlag ?? ""))),
      );
      return { antwort: text(d.antwort, 300), ok: d.ok !== false, wert: zahl(d.wert), wdh: zahl(d.wdh) };
    }
    case "stagnation": {
      const d = parseObjekt(
        await ask(
          env,
          stagnationPrompt(
            profile,
            String(body.uebung ?? ""),
            String(body.plan ?? ""),
            String(body.verlauf ?? ""),
            String(body.grund ?? ""),
            String(body.tag ?? ""),
            recent,
          ),
        ),
      );
      const a = d.aenderung as Record<string, unknown> | null | undefined;
      return {
        sicht: text(d.sicht, 600),
        vorschlag: text(d.vorschlag, 300),
        aenderung: a
          ? { saetze: zahl(a.saetze), wdh_von: zahl(a.wdh_von), wdh_bis: zahl(a.wdh_bis), wert: zahl(a.wert), zuerst: a.zuerst === true }
          : null,
      };
    }
    case "balance":
      return { satz: text(parseObjekt(await ask(env, balancePrompt(profile, String(body.woche ?? "")))).satz, 300) };
    case "form": {
      const bilder = (Array.isArray(body.bilder) ? body.bilder : [])
        .filter((b): b is string => typeof b === "string" && b.length > 100 && b.length < 400000)
        .slice(0, 4);
      if (!bilder.length) return { gut: [], besser: [], vergleich: null };
      const d = parseObjekt(
        await ask(env, formPrompt(String(body.uebung ?? ""), String(body.satz ?? ""), text(body.frueher, 800)), bilder),
      );
      const liste = (v: unknown) => (Array.isArray(v) ? v : []);
      return {
        gut: liste(d.gut).map((g) => text(g, 200)).filter(Boolean).slice(0, 3),
        besser: liste(d.besser)
          .map((b) => {
            const x = (b ?? {}) as Record<string, unknown>;
            const bild = zahl(x.bild);
            return { text: text(x.text, 300), bild: bild && bild >= 1 && bild <= 4 ? Math.round(bild) : null };
          })
          .filter((b) => b.text)
          .slice(0, 3),
        vergleich: text(d.vergleich, 300),
      };
    }
    case "verlauf":
      return {
        satz: text(
          parseObjekt(await ask(env, verlaufPrompt(profile, String(body.uebung ?? ""), String(body.verlauf ?? ""), recent))).satz,
          300,
        ),
      };
    default:
      return null;
  }
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
      case "/werte": {
        const today = (body.today ?? {}) as CheckIn;
        const recent = Array.isArray(body.recent) ? (body.recent as CheckIn[]) : [];
        try {
          return json({ werte: parseWerte(await ask(env, wertePrompt(profile, today, recent))) });
        } catch (e) {
          console.error(e);
          return json({ error: "coach unavailable" }, 502);
        }
      }
      case "/muster": {
        const checkins = Array.isArray(body.checkins) ? (body.checkins as CheckIn[]) : [];
        const bisher = Array.isArray(body.bisher) ? (body.bisher as BisherMuster[]) : [];
        if (checkins.length < 5) return json({ muster: null });
        try {
          return json({ muster: parseMuster(await ask(env, musterPrompt(profile, checkins, bisher))) });
        } catch (e) {
          console.error(e);
          return json({ error: "coach unavailable" }, 502);
        }
      }
      case "/fokus": {
        const checkins = Array.isArray(body.checkins) ? (body.checkins as CheckIn[]) : [];
        const muster = Array.isArray(body.muster)
          ? (body.muster as unknown[]).filter((m): m is string => typeof m === "string")
          : [];
        const l = (body.letzter ?? null) as LetzterFokus | null;
        const letzter = l && typeof l.text === "string" && l.text.trim() ? l : null;
        try {
          const raw = await ask(env, fokusPrompt(profile, checkins, muster, letzter));
          const res = parseFokus(raw, letzter ? String(letzter.text).trim().slice(0, 120) : "");
          if (res.vorschlaege.length < 2) return json({ error: "coach unavailable" }, 502);
          return json(res);
        } catch (e) {
          console.error(e);
          return json({ error: "coach unavailable" }, 502);
        }
      }
      case "/stichpunkte": {
        const text = typeof body.text === "string" ? body.text.trim() : "";
        if (!text) return json({ punkte: [] });
        try {
          const punkte = parsePunkte(await ask(env, stichpunktePrompt(text)));
          if (punkte.length < 2) return json({ error: "coach unavailable" }, 502);
          return json({ punkte });
        } catch (e) {
          console.error(e);
          return json({ error: "coach unavailable" }, 502);
        }
      }
      case "/durchgezogen": {
        const today = (body.today ?? {}) as CheckIn;
        const f = (body.fokus ?? null) as { text?: string; geschafft?: boolean } | null;
        const bisher = Array.isArray(body.bisher)
          ? (body.bisher as unknown[]).filter((t): t is string => typeof t === "string")
          : [];
        try {
          return json({ eintrag: parseEintrag(await ask(env, durchgezogenPrompt(profile, today, f, bisher))) });
        } catch (e) {
          console.error(e);
          return json({ error: "coach unavailable" }, 502);
        }
      }
      case "/warum": {
        const today = (body.today ?? {}) as CheckIn;
        const recent = Array.isArray(body.recent) ? (body.recent as CheckIn[]) : [];
        if (!String(profile.motivation ?? "").trim()) return json({ satz: null });
        try {
          return json({ satz: parseSatz(await ask(env, warumPrompt(profile, today, recent))) });
        } catch (e) {
          console.error(e);
          return json({ error: "coach unavailable" }, 502);
        }
      }
      case "/ernaehrung": {
        try {
          const res = await ernaehrung(env, body, profile);
          return res === null ? json({ error: "not found" }, 404) : json(res);
        } catch (e) {
          console.error(e);
          return json({ error: "coach unavailable" }, 502);
        }
      }
      case "/training": {
        try {
          const res = await training(env, body, profile);
          return res === null ? json({ error: "not found" }, 404) : json(res);
        } catch (e) {
          console.error(e);
          return json({ error: "coach unavailable" }, 502);
        }
      }
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
