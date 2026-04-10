create extension if not exists pgcrypto;

create table if not exists public.atlas_profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    email text,
    display_name text,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.atlas_account_snapshots (
    owner_id uuid primary key references auth.users(id) on delete cascade,
    export_bundle jsonb not null,
    manifest_generated_at timestamptz not null,
    device_id text,
    schema_version integer not null default 1,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.atlas_live_review_sessions (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users(id) on delete cascade,
    session_token_hash text not null,
    title text not null,
    scope_kind text not null,
    render_mode text not null,
    row_count integer not null default 0,
    summary text not null,
    workspace_json jsonb not null,
    bundle_json jsonb not null,
    expires_at timestamptz,
    revoked_at timestamptz,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists atlas_live_review_sessions_token_hash_idx
    on public.atlas_live_review_sessions(session_token_hash);

create index if not exists atlas_live_review_sessions_owner_created_idx
    on public.atlas_live_review_sessions(owner_id, created_at desc);

create or replace function public.handle_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.atlas_profiles(id, email)
    values (new.id, new.email)
    on conflict (id) do update
        set email = excluded.email,
            updated_at = timezone('utc', now());
    return new;
end;
$$;

drop trigger if exists atlas_on_auth_user_created on auth.users;
create trigger atlas_on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_auth_user_created();

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = timezone('utc', now());
    return new;
end;
$$;

drop trigger if exists atlas_profiles_touch_updated_at on public.atlas_profiles;
create trigger atlas_profiles_touch_updated_at
before update on public.atlas_profiles
for each row execute procedure public.touch_updated_at();

drop trigger if exists atlas_account_snapshots_touch_updated_at on public.atlas_account_snapshots;
create trigger atlas_account_snapshots_touch_updated_at
before update on public.atlas_account_snapshots
for each row execute procedure public.touch_updated_at();

drop trigger if exists atlas_live_review_sessions_touch_updated_at on public.atlas_live_review_sessions;
create trigger atlas_live_review_sessions_touch_updated_at
before update on public.atlas_live_review_sessions
for each row execute procedure public.touch_updated_at();

alter table public.atlas_profiles enable row level security;
alter table public.atlas_account_snapshots enable row level security;
alter table public.atlas_live_review_sessions enable row level security;

drop policy if exists "atlas_profiles_owner_rw" on public.atlas_profiles;
create policy "atlas_profiles_owner_rw"
on public.atlas_profiles
for all
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "atlas_account_snapshots_owner_rw" on public.atlas_account_snapshots;
create policy "atlas_account_snapshots_owner_rw"
on public.atlas_account_snapshots
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "atlas_live_review_sessions_owner_rw" on public.atlas_live_review_sessions;
create policy "atlas_live_review_sessions_owner_rw"
on public.atlas_live_review_sessions
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);
