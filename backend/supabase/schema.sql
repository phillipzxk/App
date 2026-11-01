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
