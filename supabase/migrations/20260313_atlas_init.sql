create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  privacy_mode text not null default 'standard',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.compounds (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  local_id text not null,
  slug text not null,
  display_name text not null,
  compound_type text not null,
  is_user_defined boolean not null default true,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (owner_id, local_id)
);

create table if not exists public.protocols (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  local_id text not null,
  compound_local_id text,
  linked_vial_local_id text,
  name text not null,
  kind text not null,
  status text not null,
  timezone text not null,
  start_date text not null,
  default_time_of_day text,
  dose_amount double precision,
  dose_unit text,
  site_tracking_enabled boolean not null default false,
  site_rotation_enabled boolean not null default false,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (owner_id, local_id)
);

create table if not exists public.protocol_rules (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  local_id text not null,
  protocol_local_id text not null,
  rule_type text not null,
  interval_count integer not null,
  weekday integer,
  time_of_day text,
  anchor_date text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (owner_id, local_id)
);

create table if not exists public.vials (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  local_id text not null,
  protocol_local_id text,
  compound_local_id text,
  label text not null,
  starting_quantity double precision not null default 0,
  concentration_value double precision,
  concentration_unit text,
  volume_ml double precision,
  remaining_quantity double precision not null,
  low_stock_threshold double precision,
  quantity_unit text not null,
  opened_at text,
  expires_at text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (owner_id, local_id)
);

create table if not exists public.log_events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  local_id text not null,
  protocol_local_id text not null,
  vial_local_id text,
  site_local_id text,
  occurrence_id text,
  event_type text not null,
  effective_at timestamptz not null,
  logged_at timestamptz not null,
  quantity double precision,
  quantity_unit text,
  notes text,
  source text not null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (owner_id, local_id)
);

create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  local_id text not null,
  protocol_local_id text not null,
  occurrence_id text not null,
  offset_minutes integer not null default 0,
  channel text not null,
  is_enabled boolean not null default true,
  discreet_copy_enabled boolean not null default false,
  privacy_mode text not null default 'full_detail',
  scheduled_for timestamptz not null,
  notification_id text,
  title text not null,
  body text not null,
  status text not null default 'scheduled',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (owner_id, local_id)
);

create table if not exists public.custom_metrics (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  local_id text not null,
  protocol_local_id text,
  metric_key text not null,
  label text not null,
  value_type text not null,
  unit text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (owner_id, local_id)
);

create table if not exists public.sites (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  local_id text not null,
  name text not null,
  body_area text,
  notes text,
  archived_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (owner_id, local_id)
);

alter table public.profiles enable row level security;
alter table public.compounds enable row level security;
alter table public.protocols enable row level security;
alter table public.protocol_rules enable row level security;
alter table public.vials enable row level security;
alter table public.log_events enable row level security;
alter table public.reminders enable row level security;
alter table public.custom_metrics enable row level security;
alter table public.sites enable row level security;

create policy "profiles_owner_select" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles_owner_insert" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profiles_owner_update" on public.profiles
  for update using (auth.uid() = id);

create policy "compounds_owner_all" on public.compounds
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "protocols_owner_all" on public.protocols
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "protocol_rules_owner_all" on public.protocol_rules
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "vials_owner_all" on public.vials
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "log_events_owner_all" on public.log_events
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "reminders_owner_all" on public.reminders
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "custom_metrics_owner_all" on public.custom_metrics
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "sites_owner_all" on public.sites
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

create index if not exists idx_compounds_owner_local on public.compounds(owner_id, local_id);
create index if not exists idx_protocols_owner_local on public.protocols(owner_id, local_id);
create index if not exists idx_protocol_rules_owner_local on public.protocol_rules(owner_id, local_id);
create index if not exists idx_vials_owner_local on public.vials(owner_id, local_id);
create index if not exists idx_log_events_owner_local on public.log_events(owner_id, local_id);
create index if not exists idx_reminders_owner_local on public.reminders(owner_id, local_id);
create index if not exists idx_custom_metrics_owner_local on public.custom_metrics(owner_id, local_id);
create index if not exists idx_sites_owner_local on public.sites(owner_id, local_id);

-- v1 sync notes:
-- 1. local_id preserves stable device-generated IDs for guest upgrade and local-first sync mapping.
-- 2. immutable history lives in log_events; it should only be appended, never overwritten in place.
-- 3. generated future occurrences are not stored here as source-of-truth rows.
