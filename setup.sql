-- ============================================================
-- Brand Name Vote — Supabase Setup
-- Run this in your Supabase SQL Editor
-- ============================================================

-- Voters: each invited person gets a row with a unique token
create table if not exists voters (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  token text unique not null,
  comment text,
  voted_at timestamptz,
  created_at timestamptz default now()
);

-- Votes: one row per brand per voter (3 rows per voter)
create table if not exists votes (
  id uuid primary key default gen_random_uuid(),
  voter_id uuid references voters(id) on delete cascade not null,
  brand text not null,
  rating int not null check (rating between 1 and 5),
  preferred_domain text not null,
  created_at timestamptz default now(),
  unique(voter_id, brand)
);

-- Lock down direct table access — everything goes through RPC
alter table voters enable row level security;
alter table votes enable row level security;

-- Voter lookup by token (security definer bypasses RLS)
create or replace function get_voter(voter_token text)
returns json
language sql
security definer
set search_path = public
as $$
  select json_build_object(
    'id', id,
    'name', name,
    'voted_at', voted_at
  )
  from voters
  where token = voter_token
  limit 1;
$$;

-- Submit a complete vote (3 brand ratings + domains + optional comment)
create or replace function submit_vote(
  voter_token text,
  vote_data jsonb,
  voter_comment text default null
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_name text;
begin
  select id, name into v_id, v_name
  from voters
  where token = voter_token and voted_at is null;

  if v_id is null then
    return json_build_object('success', false, 'error', 'Invalid token or already voted');
  end if;

  insert into votes (voter_id, brand, rating, preferred_domain)
  select v_id, v->>'brand', (v->>'rating')::int, v->>'preferred_domain'
  from jsonb_array_elements(vote_data) as v;

  update voters set voted_at = now(), comment = voter_comment where id = v_id;

  return json_build_object('success', true, 'name', v_name);
end;
$$;
