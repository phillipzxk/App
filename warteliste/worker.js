export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    if (url.pathname !== '/eintragen') return env.ASSETS.fetch(req);
    if (req.method !== 'POST') return new Response('Nur POST', { status: 405 });
    let body;
    try { body = await req.json(); } catch { return new Response('Ungültig', { status: 400 }); }
    if (body.website) return new Response(null, { status: 204 }); // Bot
    const email = String(body.email || '').trim().slice(0, 200);
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return new Response('E-Mail ungültig', { status: 400 });
    const quelle = String(body.quelle || '').slice(0, 40);
    const r = await fetch(env.SUPABASE_URL + '/rest/v1/warteliste', {
      method: 'POST',
      headers: { apikey: env.SUPABASE_ANON_KEY, Authorization: 'Bearer ' + env.SUPABASE_ANON_KEY,
        'content-type': 'application/json', Prefer: 'return=minimal' },
      body: JSON.stringify({ email, quelle }),
    });
    if (r.ok || r.status === 409) return new Response(null, { status: 204 });
    return new Response('Fehler', { status: 502 });
  },
};
