-- ODÁRA Client Manager: service catalog and facial protocol library
-- Run once in Supabase SQL Editor. Existing tables and client records are not modified.
create table if not exists public.service_catalog (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  category text not null default 'Otros',
  price numeric(10,2),
  duration_minutes integer not null default 60 check (duration_minutes >= 0),
  description text not null default '',
  active boolean not null default true,
  public_bookable boolean not null default true,
  requires_medical_provider boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint medical_services_not_publicly_bookable check (not (requires_medical_provider and public_bookable))
);
create index if not exists service_catalog_user_category_idx on public.service_catalog(user_id, category);
alter table public.service_catalog enable row level security;
drop policy if exists "Users manage their own service catalog" on public.service_catalog;
create policy "Users manage their own service catalog" on public.service_catalog
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create table if not exists public.facial_protocols (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  service_name text not null,
  skin_types text[] not null default '{}',
  indications text not null default '',
  contraindications text not null default '',
  steps jsonb not null default '[]'::jsonb,
  products text not null default '',
  aftercare text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists facial_protocols_user_service_idx on public.facial_protocols(user_id, service_name);
alter table public.facial_protocols enable row level security;
drop policy if exists "Users manage their own facial protocols" on public.facial_protocols;
create policy "Users manage their own facial protocols" on public.facial_protocols
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());


-- Prevent simultaneous active bookings for the same date and time.
-- Cancelled/expired appointments do not block the slot.
create unique index if not exists appointments_unique_active_slot_idx
  on public.appointments (appointment_date, appointment_time)
  where appointment_time is not null
    and status not in ('Cancelada', 'Cancelled', 'Cancelado', 'Expirada', 'Expired');
