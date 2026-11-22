-- Groundset: Konto und Sicherung (vault Umsetzung/Konto und Sicherung.md).
-- Runs once on the Supabase project (Frankfurt). Safe to run again.

-- 1. Private bucket for the two backup files per user:
--    <user id>/daten.json and <user id>/fotos.json
insert into storage.buckets (id, name, public)
values ('sicherungen', 'sicherungen', false)
on conflict (id) do nothing;

-- 2. Everyone sees and writes only their own folder.
drop policy if exists "eigene Sicherung lesen" on storage.objects;
create policy "eigene Sicherung lesen" on storage.objects
  for select to authenticated
  using (bucket_id = 'sicherungen' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "eigene Sicherung anlegen" on storage.objects;
create policy "eigene Sicherung anlegen" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'sicherungen' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "eigene Sicherung ändern" on storage.objects;
create policy "eigene Sicherung ändern" on storage.objects
  for update to authenticated
  using (bucket_id = 'sicherungen' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "eigene Sicherung löschen" on storage.objects;
create policy "eigene Sicherung löschen" on storage.objects
  for delete to authenticated
  using (bucket_id = 'sicherungen' and (storage.foldername(name))[1] = auth.uid()::text);

-- 3. "Konto und alle Daten löschen": the app first deletes the two files
--    through the storage API, then calls this to remove the account of
--    whoever calls it (Apple requires deleting in the app).
create or replace function public.konto_loeschen()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'nicht angemeldet';
  end if;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.konto_loeschen() from public, anon;
grant execute on function public.konto_loeschen() to authenticated;

-- 4. Privatcoach (vault Umsetzung/Phillip dazuholen.md, Ablauf 2026-11-21):
--    users write to Phillip like on Insta; the first message is a request he
--    accepts. Only an account in coach_rollen writes as the coach, and only
--    through the functions below (no direct writes to the tables).
create table if not exists public.coach_rollen (
  user_id uuid primary key references auth.users on delete cascade
);
alter table public.coach_rollen enable row level security;
-- Phillip's account is added by hand in the SQL editor, never in this file.

create table if not exists public.coach_einstellungen (
  id int primary key default 1 check (id = 1),
  plaetze int not null default 5
);
insert into public.coach_einstellungen (id) values (1) on conflict do nothing;
alter table public.coach_einstellungen enable row level security;

create or replace function public.ist_coach()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.coach_rollen where user_id = auth.uid()) $$;

create table if not exists public.coach_chats (
  user_id uuid primary key references auth.users on delete cascade,
  name text not null default '',
  status text not null default 'anfrage'
    check (status in ('anfrage', 'aktiv', 'beendet')),
  werte_erlaubt boolean not null default false,
  werte jsonb,
  werte_am timestamptz,
  fokus text,
  erstellt timestamptz not null default now(),
  angenommen timestamptz,
  zuletzt timestamptz not null default now()
);
alter table public.coach_chats enable row level security;
drop policy if exists "eigener Chat oder Coach" on public.coach_chats;
create policy "eigener Chat oder Coach" on public.coach_chats
  for select to authenticated
  using (user_id = auth.uid() or public.ist_coach());

create table if not exists public.coach_nachrichten (
  id bigint generated always as identity primary key,
  chat uuid not null references public.coach_chats (user_id) on delete cascade,
  von text not null check (von in ('user', 'coach')),
  text text not null default '',
  audio text,
  audio_sekunden int,
  erstellt timestamptz not null default now(),
  gelesen timestamptz,
  gemeldet timestamptz
);
create index if not exists coach_nachrichten_chat on public.coach_nachrichten (chat, id);
alter table public.coach_nachrichten enable row level security;
drop policy if exists "eigene Nachrichten oder Coach" on public.coach_nachrichten;
create policy "eigene Nachrichten oder Coach" on public.coach_nachrichten
  for select to authenticated
  using (chat = auth.uid() or public.ist_coach());

-- Whether a new user can still write (test phase: limited places).
create or replace function public.coach_frei()
returns boolean language sql stable security definer set search_path = ''
as $$
  select (select count(*) from public.coach_chats where status in ('anfrage', 'aktiv'))
    < (select plaetze from public.coach_einstellungen where id = 1)
$$;

-- A message. The user writes into their own chat (the first one opens the
-- request); the coach writes into any chat he accepted.
create or replace function public.coach_senden(
  p_chat uuid, p_text text, p_audio text default null,
  p_sekunden int default null, p_name text default null
)
returns bigint language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  wer text;
  neu bigint;
begin
  if uid is null then raise exception 'nicht angemeldet'; end if;
  if coalesce(trim(p_text), '') = '' and p_audio is null then
    raise exception 'leer';
  end if;
  if p_chat = uid then
    wer := 'user';
    if not exists (select 1 from public.coach_chats where user_id = uid) then
      if not public.coach_frei() then raise exception 'voll'; end if;
      insert into public.coach_chats (user_id, name) values (uid, coalesce(p_name, ''));
    elsif exists (select 1 from public.coach_chats where user_id = uid and status = 'beendet') then
      raise exception 'beendet';
    end if;
  elsif public.ist_coach() then
    wer := 'coach';
    if not exists (select 1 from public.coach_chats where user_id = p_chat and status = 'aktiv') then
      raise exception 'nicht angenommen';
    end if;
  else
    raise exception 'nicht erlaubt';
  end if;
  insert into public.coach_nachrichten (chat, von, text, audio, audio_sekunden)
  values (p_chat, wer, coalesce(p_text, ''), p_audio, p_sekunden)
  returning id into neu;
  update public.coach_chats set zuletzt = now(),
    name = case when wer = 'user' and p_name is not null then p_name else name end
  where user_id = p_chat;
  return neu;
end;
$$;

-- The user shares (or stops sharing) their values with Phillip.
create or replace function public.coach_werte(p_erlaubt boolean, p_werte jsonb)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  update public.coach_chats
  set werte_erlaubt = p_erlaubt,
      werte = case when p_erlaubt then p_werte else null end,
      werte_am = case when p_erlaubt then now() else null end
  where user_id = auth.uid();
end;
$$;

-- Phillip accepts a request.
create or replace function public.coach_annehmen(p_chat uuid)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not public.ist_coach() then raise exception 'nicht erlaubt'; end if;
  update public.coach_chats set status = 'aktiv', angenommen = now()
  where user_id = p_chat and status = 'anfrage';
end;
$$;

-- Phillip sets a focus for the user ("Fokus anpassen").
create or replace function public.coach_fokus(p_chat uuid, p_fokus text)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not public.ist_coach() then raise exception 'nicht erlaubt'; end if;
  update public.coach_chats set fokus = nullif(trim(p_fokus), '') where user_id = p_chat;
end;
$$;

-- Opening a chat marks what the other side wrote as read ("Gesehen").
create or replace function public.coach_gelesen(p_chat uuid)
returns void language plpgsql security definer set search_path = ''
as $$
declare
  andere text;
begin
  if p_chat = auth.uid() then andere := 'coach';
  elsif public.ist_coach() then andere := 'user';
  else raise exception 'nicht erlaubt';
  end if;
  update public.coach_nachrichten set gelesen = now()
  where chat = p_chat and von = andere and gelesen is null;
end;
$$;

revoke all on function public.coach_frei() from public, anon;
revoke all on function public.coach_senden(uuid, text, text, int, text) from public, anon;
revoke all on function public.coach_werte(boolean, jsonb) from public, anon;
revoke all on function public.coach_annehmen(uuid) from public, anon;
revoke all on function public.coach_fokus(uuid, text) from public, anon;
revoke all on function public.coach_gelesen(uuid) from public, anon;
grant execute on function public.ist_coach() to authenticated;
grant execute on function public.coach_frei() to authenticated;
grant execute on function public.coach_senden(uuid, text, text, int, text) to authenticated;
grant execute on function public.coach_werte(boolean, jsonb) to authenticated;
grant execute on function public.coach_annehmen(uuid) to authenticated;
grant execute on function public.coach_fokus(uuid, text) to authenticated;
grant execute on function public.coach_gelesen(uuid) to authenticated;
grant select on public.coach_chats, public.coach_nachrichten to authenticated;

-- Voice messages: <chat>/<file>, readable by the user and the coach.
insert into storage.buckets (id, name, public)
values ('coach-audio', 'coach-audio', false)
on conflict (id) do nothing;
drop policy if exists "Sprachnachricht lesen" on storage.objects;
create policy "Sprachnachricht lesen" on storage.objects
  for select to authenticated
  using (bucket_id = 'coach-audio' and ((storage.foldername(name))[1] = auth.uid()::text or public.ist_coach()));
drop policy if exists "Sprachnachricht hochladen" on storage.objects;
create policy "Sprachnachricht hochladen" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'coach-audio' and ((storage.foldername(name))[1] = auth.uid()::text or public.ist_coach()));

-- Coach role on sign-up: emails are added to coach_vormerkung by hand
-- (never in this file); the trigger gives that account the coach role.
create table if not exists public.coach_vormerkung (email text primary key);
alter table public.coach_vormerkung enable row level security;
create or replace function public.coach_vorgemerkt() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.coach_vormerkung v where lower(v.email) = lower(new.email)) then
    insert into public.coach_rollen(user_id) values (new.id) on conflict do nothing;
  end if;
  return new;
end $$;
drop trigger if exists coach_vorgemerkt on auth.users;
create trigger coach_vorgemerkt after insert on auth.users
  for each row execute function public.coach_vorgemerkt();

-- 5. Notifications for the Privatcoach chat --------------------------------
create extension if not exists pg_net;
create extension if not exists pg_cron;

-- Web Push subscriptions, one per browser/phone. Written only via RPC.
create table if not exists public.coach_push (
  endpoint text primary key,
  user_id uuid not null references auth.users on delete cascade,
  p256dh text not null,
  auth text not null,
  erstellt timestamptz not null default now()
);
alter table public.coach_push enable row level security;

alter table public.coach_nachrichten add column if not exists erinnert timestamptz;

-- Private settings for the database itself (no policies: nobody reads it
-- through the API). Holds the hook secret, set by hand, never in this file.
create table if not exists public.coach_intern (schluessel text primary key, wert text not null);
alter table public.coach_intern enable row level security;

create or replace function public.coach_push_an(p_endpoint text, p_p256dh text, p_auth text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'anmelden'; end if;
  insert into coach_push(endpoint, user_id, p256dh, auth)
  values (p_endpoint, auth.uid(), p_p256dh, p_auth)
  on conflict (endpoint) do update
    set user_id = auth.uid(), p256dh = excluded.p256dh, auth = excluded.auth, erstellt = now();
end $$;

create or replace function public.coach_push_aus(p_endpoint text)
returns void language sql security definer set search_path = public as $$
  delete from coach_push where endpoint = p_endpoint and user_id = auth.uid();
$$;

grant execute on function public.coach_push_an(text, text, text) to authenticated;
grant execute on function public.coach_push_aus(text) to authenticated;

create or replace function public.coach_hook(p_body jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare g text;
begin
  select wert into g from coach_intern where schluessel = 'hook_geheim';
  if g is null then return; end if;
  perform net.http_post(
    url := 'https://iuivlfkfjffltxfvtoqk.supabase.co/functions/v1/coach-benachrichtigen',
    body := p_body,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-geheim', g)
  );
end $$;
revoke execute on function public.coach_hook(jsonb) from public, anon, authenticated;

create or replace function public.coach_neu_melden() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform coach_hook(jsonb_build_object('art', 'neu', 'id', new.id));
  return new;
end $$;
drop trigger if exists coach_neu_melden on public.coach_nachrichten;
create trigger coach_neu_melden after insert on public.coach_nachrichten
  for each row execute function public.coach_neu_melden();

-- Every 5 minutes: e-mail for messages unread for 15 minutes.
select cron.unschedule(jobid) from cron.job where jobname = 'coach-verpasst';
select cron.schedule('coach-verpasst', '*/5 * * * *',
  $$select public.coach_hook('{"art":"verpasst"}'::jsonb)$$);
