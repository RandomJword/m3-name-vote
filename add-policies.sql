-- Allow anon key to read and insert voters
create policy "anon_read_voters" on voters for select using (true);
create policy "anon_insert_voters" on voters for insert with check (true);
create policy "anon_update_voters" on voters for update using (true);

-- Allow anon key to read and insert votes
create policy "anon_read_votes" on votes for select using (true);
create policy "anon_insert_votes" on votes for insert with check (true);
