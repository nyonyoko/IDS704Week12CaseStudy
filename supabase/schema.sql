-- Whose Values? Supabase schema
-- Run once in the Supabase SQL editor (or as a migration).
-- Requires: Auth > Sign In / Providers > "Allow anonymous sign-ins" turned ON,
-- and Email (magic link) turned ON for facilitators.

-- Helper: true when an array has no duplicate values.
create or replace function public.is_distinct_set(a smallint[])
returns boolean
language sql
immutable
as $$
  select count(distinct x) = count(*) from unnest(a) as x;
$$;

-- Helper: true when the current user signed in anonymously.
create or replace function public.is_anon_user()
returns boolean
language sql
stable
as $$
  select coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false);
$$;

-- One row per class session. Created by a facilitator (non-anonymous user).
create table if not exists public.sessions (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique check (code ~ '^[A-Z0-9]{4,10}$'),
  title       text not null default 'Whose Values?',
  owner_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  is_open     boolean not null default true,
  created_at  timestamptz not null default now()
);

-- One row per student per session. Each round upserts its own columns.
create table if not exists public.responses (
  session_id      uuid not null references public.sessions (id) on delete cascade,
  participant_id  uuid not null default auth.uid() references auth.users (id) on delete cascade,

  -- Round 1: order of the 4 core priorities, index 0..3, most important first.
  r1 smallint[] check (
    r1 is null or (cardinality(r1) = 4 and r1 @> array[0,1,2,3]::smallint[])
  ),
  -- Round 2: top 5 values, indexes 0..13, most important first.
  r2 smallint[] check (
    r2 is null or (
      cardinality(r2) = 5
      and r2 <@ array[0,1,2,3,4,5,6,7,8,9,10,11,12,13]::smallint[]
      and public.is_distinct_set(r2)
    )
  ),
  -- Round 3: scenario choice 0..3.
  r3 smallint check (r3 between 0 and 3),
  -- Warm-up 1: 1 (comfortable) to 5 (concerned).
  w1 smallint check (w1 between 1 and 5),
  -- Warm-up 2: up to two of 0..4.
  w2 smallint[] check (
    w2 is null or (
      cardinality(w2) between 1 and 2
      and w2 <@ array[0,1,2,3,4]::smallint[]
      and public.is_distinct_set(w2)
    )
  ),
  -- Warm-up 3: 0 yes, 1 no, 2 only for high-stakes tools.
  w3 smallint check (w3 between 0 and 2),

  updated_at  timestamptz not null default now(),
  primary key (session_id, participant_id)
);

create index if not exists responses_session_idx on public.responses (session_id);

-- Keep updated_at fresh.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists responses_touch on public.responses;
create trigger responses_touch
before update on public.responses
for each row execute function public.touch_updated_at();

-- Row level security
alter table public.sessions  enable row level security;
alter table public.responses enable row level security;

-- Sessions: anyone signed in (including anonymous students) can look up a session by code.
drop policy if exists sessions_select on public.sessions;
create policy sessions_select on public.sessions
  for select to authenticated
  using (true);

-- Only non-anonymous users can create sessions, and only as themselves.
drop policy if exists sessions_insert on public.sessions;
create policy sessions_insert on public.sessions
  for insert to authenticated
  with check (owner_id = auth.uid() and not public.is_anon_user());

drop policy if exists sessions_update on public.sessions;
create policy sessions_update on public.sessions
  for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

drop policy if exists sessions_delete on public.sessions;
create policy sessions_delete on public.sessions
  for delete to authenticated
  using (owner_id = auth.uid());

-- Responses: a student can read only their own row; the session owner can read all rows.
drop policy if exists responses_select on public.responses;
create policy responses_select on public.responses
  for select to authenticated
  using (
    participant_id = auth.uid()
    or exists (
      select 1 from public.sessions s
      where s.id = responses.session_id and s.owner_id = auth.uid()
    )
  );

-- A student can create and update only their own row, and only while the session is open.
drop policy if exists responses_insert on public.responses;
create policy responses_insert on public.responses
  for insert to authenticated
  with check (
    participant_id = auth.uid()
    and exists (
      select 1 from public.sessions s
      where s.id = responses.session_id and s.is_open
    )
  );

drop policy if exists responses_update on public.responses;
create policy responses_update on public.responses
  for update to authenticated
  using (participant_id = auth.uid())
  with check (
    participant_id = auth.uid()
    and exists (
      select 1 from public.sessions s
      where s.id = responses.session_id and s.is_open
    )
  );

-- The session owner can clear test data.
drop policy if exists responses_delete on public.responses;
create policy responses_delete on public.responses
  for delete to authenticated
  using (
    exists (
      select 1 from public.sessions s
      where s.id = responses.session_id and s.owner_id = auth.uid()
    )
  );

grant select, insert, update, delete on public.sessions  to authenticated;
grant select, insert, update, delete on public.responses to authenticated;

-- Live dashboard updates (Realtime respects the RLS policies above).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'responses'
  ) then
    alter publication supabase_realtime add table public.responses;
  end if;
end $$;

-- Keep helper functions callable by policies but not broadly privileged for other purposes.
-- Session owners can see rows via the policies above; students can see only their own.
