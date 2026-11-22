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
  for (const a of abos ?? []) {
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
