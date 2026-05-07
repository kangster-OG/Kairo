alter table public.atlas_live_review_sessions
    add column if not exists purge_after timestamptz;

alter table public.atlas_live_review_sessions
    alter column purge_after set default timezone('utc', now()) + interval '30 days';

update public.atlas_live_review_sessions
set purge_after = case
    when revoked_at is not null then revoked_at + interval '1 hour'
    when expires_at is not null then expires_at + interval '24 hours'
    else created_at + interval '30 days'
end
where purge_after is null;

create index if not exists atlas_live_review_sessions_purge_after_idx
    on public.atlas_live_review_sessions(purge_after);
