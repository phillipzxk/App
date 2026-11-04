create table if not exists public.warteliste (
  id bigint generated always as identity primary key,
  email text not null,
  quelle text,
  erstellt timestamptz not null default now(),
  constraint warteliste_email_form check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' and length(email) <= 200)
);
create unique index if not exists warteliste_email_klein on public.warteliste (lower(email));
alter table public.warteliste enable row level security;
drop policy if exists "warteliste eintragen" on public.warteliste;
create policy "warteliste eintragen" on public.warteliste for insert to anon with check (true);
revoke all on public.warteliste from anon, authenticated;
grant insert (email, quelle) on public.warteliste to anon;
