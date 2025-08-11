-- create table profiles
create table public.profiles (
  id uuid not null references auth.users on delete cascade,
  name text, 
  role text,
  avatar_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,

  primary key (id)
);

alter table public.profiles enable row level security;

-- insert a row into public.profiles when user is created
drop function if exists public.handle_new_user cascade;

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id, name, role, avatar_url, created_at, updated_at)
  values (
    new.id,
    coalesce(new.raw_user_metadata ->> 'name', ''),
    coalesce(new.raw_user_metadata ->> 'role', 'user'),
    coalesce(new.raw_user_metadata ->> 'avatar_url', ''),
    now(),
    now()
  );
  return new;
end;
$$;

-- trigger the function every time a user is created
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- delete a row from public.profiles
create function public.handle_delete_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.profiles where id = old.id;
  return old;
end;
$$;

-- trigger the function every time a user is deleted
create trigger on_auth_user_deleted
after delete on auth.users
for each row execute procedure public.handle_delete_user();