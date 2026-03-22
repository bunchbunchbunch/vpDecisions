-- app_feedback table for user-submitted feedback from the rating prompt
create table app_feedback (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) on delete set null,
    feedback text not null,
    app_version text not null,
    created_at timestamptz not null default now()
);

alter table app_feedback enable row level security;

-- Allow anonymous and authenticated users to INSERT (feedback is best-effort, no auth required)
create policy "Allow public inserts" on app_feedback
    for insert
    to anon, authenticated
    with check (true);

-- Only service role can read (no SELECT policy for anon/authenticated)
