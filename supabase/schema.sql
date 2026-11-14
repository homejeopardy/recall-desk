-- Quizletish — database setup
-- Paste the whole file into the Supabase SQL editor and run it once.
-- Safe to run again: everything is guarded with "if not exists" / "drop ... if exists".
--
-- What this holds: who is signed in, each student's own progress, and decks students
-- submit for approval. The cards themselves stay in decks.json on GitHub — nothing
-- about the decks lives here.

-- ---------------------------------------------------------------- profiles
create table if not exists public.profiles (
  id         uuid primary key references auth.users on delete cascade,
  name       text,
  email      text,
  is_editor  boolean not null default false,
  created_at timestamptz not null default now()
);

-- A profile row is created automatically the first time someone signs in.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, name, email)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      split_part(coalesce(new.email, ''), '@', 1)
    ),
    new.email
  )
  on conflict (id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Is the person making this request the editor? Used by the policies below.
create or replace function public.is_editor()
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((select p.is_editor from public.profiles p where p.id = (select auth.uid())), false);
$$;

-- Nobody can make themselves the editor. Flip is_editor in the Supabase table editor.
-- The guard only applies to requests arriving as a signed-in user. In the dashboard
-- (and anywhere else running as a privileged role) auth.uid() is null, so the flag can
-- still be set there — which is the only place it is supposed to be set. Anonymous API
-- callers cannot reach this at all: the update policy below is limited to authenticated
-- users editing their own row.
create or replace function public.lock_editor_flag()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.is_editor is distinct from old.is_editor
     and (select auth.uid()) is not null
     and not public.is_editor() then
    raise exception 'is_editor can only be changed by an editor';
  end if;
  return new;
end; $$;

drop trigger if exists profiles_lock_editor on public.profiles;
create trigger profiles_lock_editor
  before update on public.profiles
  for each row execute function public.lock_editor_flag();

-- ---------------------------------------------------------------- progress
-- One row per student per deck: scores, stars, and how far up the Learn ladder.
create table if not exists public.progress (
  user_id    uuid not null references auth.users on delete cascade,
  deck_id    text not null,
  payload    jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, deck_id)
);

-- ---------------------------------------------------------------- submissions
-- A deck a student built and sent in. The editor approves it into decks.json.
create table if not exists public.submissions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users on delete cascade,
  deck_name   text not null,
  note        text,
  payload     jsonb not null,
  status      text not null default 'pending' check (status in ('pending','approved','declined')),
  created_at  timestamptz not null default now(),
  reviewed_at timestamptz
);
create index if not exists submissions_status_idx on public.submissions (status, created_at desc);

-- ---------------------------------------------------------------- row level security
-- The publishable key is public by design, so these rules are the only thing standing
-- between a student and someone else's data. Every table is locked down.
alter table public.profiles    enable row level security;
alter table public.progress    enable row level security;
alter table public.submissions enable row level security;

drop policy if exists "read own profile"       on public.profiles;
drop policy if exists "editor reads profiles"  on public.profiles;
drop policy if exists "update own profile"     on public.profiles;
drop policy if exists "own progress"           on public.progress;
drop policy if exists "insert own submission"  on public.submissions;
drop policy if exists "read own submission"    on public.submissions;
drop policy if exists "editor reads all"       on public.submissions;
drop policy if exists "editor updates"         on public.submissions;

-- profiles: you see yourself; the editor sees everyone.
create policy "read own profile"      on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy "editor reads profiles" on public.profiles for select to authenticated using (public.is_editor());
create policy "update own profile"    on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- progress: yours and nobody else's, in either direction. The editor cannot read it.
create policy "own progress" on public.progress for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- submissions: send your own, see your own; the editor sees and judges all of them.
create policy "insert own submission" on public.submissions for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "read own submission"   on public.submissions for select to authenticated using (user_id = (select auth.uid()));
create policy "editor reads all"      on public.submissions for select to authenticated using (public.is_editor());
create policy "editor updates"        on public.submissions for update to authenticated
  using (public.is_editor()) with check (public.is_editor());

grant usage on schema public to anon, authenticated;
grant select, insert, update on public.profiles    to authenticated;
grant select, insert, update, delete on public.progress    to authenticated;
grant select, insert, update on public.submissions to authenticated;

-- ---------------------------------------------------------------- publishing key
-- The GitHub token that lets the editor publish decks.json, kept against their own
-- account so it follows them to any device instead of living in one browser.
-- Readable only by the person it belongs to: there is deliberately no editor policy
-- here, so not even another editor can read someone else's key.
create table if not exists public.editor_keys (
  user_id    uuid primary key references auth.users on delete cascade,
  gh_token   text not null,
  updated_at timestamptz not null default now()
);

alter table public.editor_keys enable row level security;

drop policy if exists "read own key"   on public.editor_keys;
drop policy if exists "save own key"   on public.editor_keys;
drop policy if exists "update own key" on public.editor_keys;
drop policy if exists "delete own key" on public.editor_keys;

create policy "read own key"   on public.editor_keys for select to authenticated
  using (user_id = (select auth.uid()));
create policy "save own key"   on public.editor_keys for insert to authenticated
  with check (user_id = (select auth.uid()) and public.is_editor());
create policy "update own key" on public.editor_keys for update to authenticated
  using (user_id = (select auth.uid()) and public.is_editor())
  with check (user_id = (select auth.uid()));
create policy "delete own key" on public.editor_keys for delete to authenticated
  using (user_id = (select auth.uid()));

grant select, insert, update, delete on public.editor_keys to authenticated;

-- ---------------------------------------------------------------- profile pictures
-- Google hands over a picture with the sign-in. Storing it lets the editor see who sent
-- a deck in, not just the account id.
alter table public.profiles add column if not exists avatar text;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, name, email, avatar)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      split_part(coalesce(new.email, ''), '@', 1)
    ),
    new.email,
    coalesce(new.raw_user_meta_data ->> 'avatar_url', new.raw_user_meta_data ->> 'picture')
  )
  on conflict (id) do nothing;
  return new;
end; $$;

-- ================================================================ roles & invites
-- Three levels. student: study, send decks in. editor: that plus edit and publish the
-- decks, and judge submissions. owner: that plus decide who is what.
alter table public.profiles add column if not exists role text not null default 'student';
do $$ begin
  alter table public.profiles add constraint profiles_role_check check (role in ('student','editor','owner'));
exception when duplicate_object then null; end $$;

-- anyone already flagged under the old boolean keeps their access
update public.profiles set role = 'editor' where is_editor and role = 'student';

-- is_editor stays in step with role, so everything written against it still works
create or replace function public.sync_editor_flag()
returns trigger language plpgsql as $$
begin
  new.is_editor := (new.role <> 'student');
  return new;
end; $$;
drop trigger if exists profiles_sync_editor on public.profiles;
create trigger profiles_sync_editor before insert or update on public.profiles
  for each row execute function public.sync_editor_flag();

create or replace function public.is_editor()
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((select p.role in ('editor','owner') from public.profiles p where p.id = (select auth.uid())), false);
$$;
create or replace function public.is_owner()
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((select p.role = 'owner' from public.profiles p where p.id = (select auth.uid())), false);
$$;

-- Only an owner may change anyone's level, and only from a signed-in session or the
-- dashboard. An editor cannot promote themselves, and nor can a student.
create or replace function public.lock_editor_flag()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if (new.role is distinct from old.role or new.is_editor is distinct from old.is_editor)
     and (select auth.uid()) is not null
     and not public.is_owner() then
    raise exception 'only an owner can change access levels';
  end if;
  return new;
end; $$;

drop policy if exists "owner updates profiles" on public.profiles;
create policy "owner updates profiles" on public.profiles for update to authenticated
  using (public.is_owner()) with check (public.is_owner());

-- Access can be granted before someone has ever signed in: it waits here under their
-- email address and is applied the moment they first arrive.
create table if not exists public.invites (
  email      text primary key,
  role       text not null default 'editor' check (role in ('editor','owner')),
  invited_by uuid references auth.users on delete set null,
  created_at timestamptz not null default now()
);
alter table public.invites enable row level security;

drop policy if exists "owner reads invites"   on public.invites;
drop policy if exists "owner makes invites"   on public.invites;
drop policy if exists "owner drops invites"   on public.invites;
create policy "owner reads invites" on public.invites for select to authenticated using (public.is_owner());
create policy "owner makes invites" on public.invites for insert to authenticated with check (public.is_owner());
create policy "owner drops invites" on public.invites for delete to authenticated using (public.is_owner());
grant select, insert, delete on public.invites to authenticated;

-- A new account picks up whatever was left waiting for its email address.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare waiting text;
begin
  select i.role into waiting from public.invites i where lower(i.email) = lower(coalesce(new.email, ''));
  insert into public.profiles (id, name, email, avatar, role)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      split_part(coalesce(new.email, ''), '@', 1)
    ),
    new.email,
    coalesce(new.raw_user_meta_data ->> 'avatar_url', new.raw_user_meta_data ->> 'picture'),
    coalesce(waiting, 'student')
  )
  on conflict (id) do nothing;
  delete from public.invites i where lower(i.email) = lower(coalesce(new.email, ''));
  return new;
end; $$;
