// Notifications for the Privatcoach chat (vault Umsetzung/Privatcoach).
// Called by the database: "neu" right after a message is saved (Web Push
// to the other side), "verpasst" every 5 minutes (e-mail when a message
// stayed unread for 15 minutes). Only the database knows HOOK_GEHEIM.
import webpush from "npm:web-push@3.6.7";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
webpush.setVapidDetails(
  "https://groundset-vorschau.pzschernack4.workers.dev",
  Deno.env.get("VAPID_PUBLIC")!,
  Deno.env.get("VAPID_PRIVATE")!,
);
const APP = "https://groundset-vorschau.pzschernack4.workers.dev";

type Nachricht = {
  id: number;
  chat: string;
  von: "user" | "coach";
  text: string | null;
  audio: string | null;
  erstellt: string;
};

const kurz = (n: Nachricht) =>
  n.audio && !n.text
    ? "Sprachnachricht"
    : (n.text ?? "").length > 140
    ? (n.text ?? "").slice(0, 137) + "..."
    : (n.text ?? "");

async function coaches(): Promise<string[]> {
  const { data } = await db.from("coach_rollen").select("user_id");
  return (data ?? []).map((r) => r.user_id as string);
}

async function chatName(chat: string): Promise<string> {
  const { data } = await db.from("coach_chats").select("name").eq(
    "user_id",
    chat,
  ).maybeSingle();
  return (data?.name as string | undefined)?.trim() || "Neue Nachricht";
}

/// Who gets told about [n]: the user for Phillip's messages, Phillip for
/// the user's.
async function empfaenger(n: Nachricht): Promise<string[]> {
  return n.von === "coach" ? [n.chat] : await coaches();
}


// MARK: Android (Firebase Cloud Messaging, HTTP v1)

const b64url = (b: Uint8Array | string) =>
  btoa(typeof b === "string" ? b : String.fromCharCode(...b))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

let fcmZugang: { token: string; bis: number } | null = null;

async function fcmKonto() {
  const roh = Deno.env.get("FCM_SERVICE_ACCOUNT");
  return roh ? JSON.parse(roh) as {
    client_email: string;
    private_key: string;
    project_id: string;
  } : null;
}

async function fcmToken(sa: { client_email: string; private_key: string }) {
  if (fcmZugang && fcmZugang.bis > Date.now() + 60_000) return fcmZugang.token;
  const jetzt = Math.floor(Date.now() / 1000);
  const kopf = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const inhalt = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: jetzt,
    exp: jetzt + 3600,
  }));
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const schluessel = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      schluessel,
      new TextEncoder().encode(`${kopf}.${inhalt}`),
    ),
  );
  const r = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${kopf}.${inhalt}.${b64url(sig)}`,
    }),
  });
  const j = await r.json();
  fcmZugang = { token: j.access_token, bis: Date.now() + j.expires_in * 1000 };
  return fcmZugang.token;
}

/// True when sent; false when the token is gone (row gets deleted).
async function fcmSenden(
  token: string,
  titel: string,
  text: string,
  chat: string,
): Promise<boolean | null> {
  const sa = await fcmKonto();
  if (!sa) return null;
  const r = await fetch(
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${await fcmToken(sa)}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: titel, body: text },
          data: { chat },
          android: {
            priority: "high",
            notification: { tag: "groundset-chat", color: "#E2C48A" },
          },
        },
      }),
    },
  );
  if (r.ok) return true;
  return r.status === 404 || r.status === 400 ? false : null;
}

async function pushen(n: Nachricht) {
  const an = await empfaenger(n);
  if (an.length === 0) return 0;
  const { data: abos } = await db.from("coach_push").select(
    "endpoint, p256dh, auth",
  ).in("user_id", an);
  const titel = n.von === "coach" ? "Phillip" : await chatName(n.chat);
  const inhalt = JSON.stringify({
    titel,
    text: kurz(n),
    url: `${APP}/?chat=${n.von === "coach" ? "1" : n.chat}`,
  });
  let ok = 0;
  const chat = n.von === "coach" ? "1" : n.chat;
  for (const a of abos ?? []) {
    if (a.endpoint.startsWith("fcm:")) {
      const r = await fcmSenden(a.endpoint.slice(4), titel, kurz(n), chat);
      if (r === true) ok++;
      if (r === false) {
        await db.from("coach_push").delete().eq("endpoint", a.endpoint);
      }
      continue;
    }
    try {
      await webpush.sendNotification(
        { endpoint: a.endpoint, keys: { p256dh: a.p256dh, auth: a.auth } },
        inhalt,
        { TTL: 86400, urgency: "high" },
      );
      ok++;
    } catch (e) {
      const code = (e as { statusCode?: number }).statusCode;
      if (code === 404 || code === 410) {
        await db.from("coach_push").delete().eq("endpoint", a.endpoint);
      }
    }
  }
  return ok;
}

async function mail(an: string, betreff: string, text: string) {
  const r = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${Deno.env.get("RESEND_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: Deno.env.get("MAIL_VON") ?? "Groundset <onboarding@resend.dev>",
      to: [an],
      subject: betreff,
      text,
    }),
  });
  return r.ok;
}

/// Messages unread for 15 minutes (not older than a day): one e-mail per
/// person, then marked so it is sent only once.
async function verpasst() {
  const jetzt = Date.now();
  const { data } = await db.from("coach_nachrichten")
    .select("id, chat, von, text, audio, erstellt")
    .is("gelesen", null).is("erinnert", null)
    .lt("erstellt", new Date(jetzt - 15 * 60_000).toISOString())
    .gt("erstellt", new Date(jetzt - 24 * 3600_000).toISOString())
    .order("erstellt");
  const liste = (data ?? []) as Nachricht[];
  if (liste.length === 0) return 0;
  const proPerson = new Map<string, Nachricht[]>();
  for (const n of liste) {
    for (const p of await empfaenger(n)) {
      proPerson.set(p, [...(proPerson.get(p) ?? []), n]);
    }
  }
  let gesendet = 0;
  for (const [person, ns] of proPerson) {
    const { data: u } = await db.auth.admin.getUserById(person);
    const email = u?.user?.email;
    if (!email) continue;
    const vonPhillip = ns[0].von === "coach";
    const wer = vonPhillip ? "Phillip" : await chatName(ns[0].chat);
    const betreff = vonPhillip
      ? "Phillip hat dir geschrieben"
      : `${wer} hat dir geschrieben`;
    const zeilen = ns.map((n) => `„${kurz(n)}“`).join("\n");
    const ok = await mail(
      email,
      betreff,
      `${zeilen}\n\nAntworten in Groundset: ${APP}/?chat=${
        vonPhillip ? "1" : ns[0].chat
      }\n`,
    );
    if (ok) gesendet++;
  }
  await db.from("coach_nachrichten").update({
    erinnert: new Date().toISOString(),
  }).in("id", liste.map((n) => n.id));
  return gesendet;
}

Deno.serve(async (req) => {
  if (req.headers.get("x-geheim") !== Deno.env.get("HOOK_GEHEIM")) {
    return new Response("nein", { status: 401 });
  }
  const b = await req.json().catch(() => ({}));
  if (b.art === "neu" && b.id) {
    const { data } = await db.from("coach_nachrichten")
      .select("id, chat, von, text, audio, erstellt").eq("id", b.id)
      .maybeSingle();
    if (!data) return Response.json({ ok: 0 });
    return Response.json({ ok: await pushen(data as Nachricht) });
  }
  if (b.art === "verpasst") return Response.json({ ok: await verpasst() });
  return new Response("?", { status: 400 });
});
