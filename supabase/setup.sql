create table if not exists public.remitos (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days')
);

create or replace function public.set_remito_timestamps()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  new.expires_at := now() + interval '7 days';
  return new;
end;
$$;

drop trigger if exists set_remito_timestamps on public.remitos;
create trigger set_remito_timestamps
before insert or update on public.remitos
for each row execute function public.set_remito_timestamps();

create table if not exists public.catalogo (
  id text primary key check (id = 'main'),
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create or replace function public.set_catalogo_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists set_catalogo_updated_at on public.catalogo;
create trigger set_catalogo_updated_at
before update on public.catalogo
for each row execute function public.set_catalogo_updated_at();

alter table public.remitos enable row level security;
alter table public.catalogo enable row level security;

revoke all on table public.remitos, public.catalogo from anon, authenticated;
grant select, insert, update, delete on table public.remitos, public.catalogo to authenticated;

drop policy if exists "Anonymous visitors can access remitos" on public.remitos;
create policy "Anonymous visitors can access remitos"
on public.remitos
for all
to authenticated
using ((select auth.jwt() ->> 'is_anonymous' = 'true'))
with check ((select auth.jwt() ->> 'is_anonymous' = 'true'));

drop policy if exists "Anonymous visitors can access catalogo" on public.catalogo;
create policy "Anonymous visitors can access catalogo"
on public.catalogo
for all
to authenticated
using ((select auth.jwt() ->> 'is_anonymous' = 'true'))
with check ((select auth.jwt() ->> 'is_anonymous' = 'true'));

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'remitos'
  ) then
    execute 'alter publication supabase_realtime add table public.remitos';
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'catalogo'
  ) then
    execute 'alter publication supabase_realtime add table public.catalogo';
  end if;
end;
$$;

create extension if not exists pg_cron;

do $$
declare
  existing_job bigint;
begin
  for existing_job in
    select jobid from cron.job where jobname = 'delete-expired-remitos'
  loop
    perform cron.unschedule(existing_job);
  end loop;
  perform cron.schedule(
    'delete-expired-remitos',
    '0 * * * *',
    'delete from public.remitos where expires_at <= now()'
  );
end;
$$;
