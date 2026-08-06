-- ============================================================================
--  Cuba en la Olimpiada Iberoamericana de Matemática
--  Esquema de base de datos para Supabase (PostgreSQL)
-- ----------------------------------------------------------------------------
--  Cómo usarlo:
--    1. Entra a tu proyecto en https://supabase.com
--    2. Menú lateral -> SQL Editor -> New query
--    3. Pega TODO este fichero y pulsa "Run"
--    4. Después ejecuta el bloque final (BOOTSTRAP) con tu correo real
--
--  Se puede volver a ejecutar sin miedo: es idempotente.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. TABLAS
-- ----------------------------------------------------------------------------

-- Perfiles de usuario. Se crea automáticamente al registrarse (ver trigger).
-- El rol determina qué puede hacer cada persona:
--   admin  -> todo, incluido gestionar usuarios y borrar ediciones
--   editor -> añadir y modificar ediciones y resultados
--   viewer -> solo lectura (igual que un visitante anónimo)
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  email      text not null,
  full_name  text not null default '',
  role       text not null default 'viewer'
             check (role in ('admin', 'editor', 'viewer')),
  created_at timestamptz not null default now()
);

-- Invitaciones. Solo se puede registrar quien tenga aquí su correo.
-- Así tú controlas quién entra: tú invitas, la persona elige su contraseña.
create table if not exists public.invitations (
  id         uuid primary key default gen_random_uuid(),
  email      text not null unique,
  role       text not null default 'editor'
             check (role in ('admin', 'editor', 'viewer')),
  note       text not null default '',
  created_at timestamptz not null default now(),
  created_by uuid references auth.users (id) on delete set null,
  used_at    timestamptz
);

-- Una fila por año de olimpiada.
create table if not exists public.editions (
  year           int primary key check (year between 1985 and 2100),
  host_country   text not null default '',
  host_city      text not null default '',
  leader         text not null default '',   -- Líder / Jefe de delegación
  deputy_leader  text not null default '',   -- Colíder / Tutor
  notes          text not null default '',
  updated_at     timestamptz not null default now()
);

-- Una fila por concursante (normalmente 4 por año).
create table if not exists public.results (
  id          uuid primary key default gen_random_uuid(),
  year        int not null references public.editions (year) on delete cascade,
  contestant  text not null default '',
  p1          smallint check (p1 between 0 and 7),
  p2          smallint check (p2 between 0 and 7),
  p3          smallint check (p3 between 0 and 7),
  p4          smallint check (p4 between 0 and 7),
  p5          smallint check (p5 between 0 and 7),
  p6          smallint check (p6 between 0 and 7),
  total       smallint check (total between 0 and 42),
  award       text check (award in ('Oro', 'Plata', 'Bronce',
                                    'Mención de Honor', 'Participación')),
  rank        int,          -- puesto individual (opcional, no se muestra aún)
  notes       text not null default '',
  sort_order  smallint not null default 1,   -- orden de las filas dentro del año
  updated_at  timestamptz not null default now()
);

create index if not exists results_year_idx on public.results (year, sort_order);

-- Historial: quién cambió qué y cuándo.
create table if not exists public.audit_log (
  id               bigserial primary key,
  table_name       text not null,
  row_id           text,
  action           text not null,
  old_data         jsonb,
  new_data         jsonb,
  changed_by       uuid,
  changed_by_email text,
  changed_at       timestamptz not null default now()
);

create index if not exists audit_log_changed_at_idx
  on public.audit_log (changed_at desc);

-- ----------------------------------------------------------------------------
-- 2. FUNCIONES DE AYUDA
--    SECURITY DEFINER para que no haya recursión infinita al evaluar las
--    políticas RLS de la propia tabla profiles.
-- ----------------------------------------------------------------------------

create or replace function public.my_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select role from public.profiles where id = auth.uid()), 'anon');
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.my_role() = 'admin';
$$;

create or replace function public.is_editor()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.my_role() in ('admin', 'editor');
$$;

grant execute on function public.my_role()   to anon, authenticated;
grant execute on function public.is_admin()  to anon, authenticated;
grant execute on function public.is_editor() to anon, authenticated;

-- ----------------------------------------------------------------------------
-- 3. TRIGGERS
-- ----------------------------------------------------------------------------

-- 3.1 Alta de usuario: solo si está invitado. Le asigna el rol de la invitación.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  inv public.invitations%rowtype;
begin
  select * into inv
    from public.invitations
   where lower(email) = lower(new.email)
     and used_at is null
   limit 1;

  if inv.id is null then
    raise exception 'Este correo no tiene invitación. Pide acceso al administrador.'
      using errcode = 'P0001';
  end if;

  insert into public.profiles (id, email, full_name, role)
  values (new.id,
          new.email,
          coalesce(new.raw_user_meta_data ->> 'full_name', ''),
          inv.role)
  on conflict (id) do nothing;

  update public.invitations set used_at = now() where id = inv.id;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3.2 Marca de tiempo de última modificación.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists editions_touch on public.editions;
create trigger editions_touch before update on public.editions
  for each row execute function public.touch_updated_at();

drop trigger if exists results_touch on public.results;
create trigger results_touch before update on public.results
  for each row execute function public.touch_updated_at();

-- 3.3 Historial de cambios.
create or replace function public.log_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  rid text;
begin
  rid := coalesce(to_jsonb(new) ->> 'id',   to_jsonb(old) ->> 'id',
                  to_jsonb(new) ->> 'year', to_jsonb(old) ->> 'year');

  insert into public.audit_log (table_name, row_id, action,
                                old_data, new_data,
                                changed_by, changed_by_email)
  values (tg_table_name,
          rid,
          tg_op,
          case when tg_op = 'INSERT' then null else to_jsonb(old) end,
          case when tg_op = 'DELETE' then null else to_jsonb(new) end,
          auth.uid(),
          (select email from public.profiles where id = auth.uid()));

  return coalesce(new, old);
end;
$$;

drop trigger if exists editions_audit on public.editions;
create trigger editions_audit
  after insert or update or delete on public.editions
  for each row execute function public.log_change();

drop trigger if exists results_audit on public.results;
create trigger results_audit
  after insert or update or delete on public.results
  for each row execute function public.log_change();

-- ----------------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY
--    La clave "anon" que va en el sitio web es pública por diseño; lo que
--    protege los datos son estas políticas.
-- ----------------------------------------------------------------------------

alter table public.profiles    enable row level security;
alter table public.invitations enable row level security;
alter table public.editions    enable row level security;
alter table public.results     enable row level security;
alter table public.audit_log   enable row level security;

-- profiles: cada quien ve el suyo; el admin ve y edita todos.
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select using (id = auth.uid() or public.is_admin());

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists profiles_delete on public.profiles;
create policy profiles_delete on public.profiles
  for delete using (public.is_admin());

-- invitations: solo el admin.
drop policy if exists invitations_all on public.invitations;
create policy invitations_all on public.invitations
  for all using (public.is_admin()) with check (public.is_admin());

-- editions: lectura pública; crear, modificar y borrar, solo el admin.
-- Los editores no tocan el año, el país, la sede ni los líderes: se limitan a
-- rellenar concursantes y puntos en la tabla results.
drop policy if exists editions_select on public.editions;
create policy editions_select on public.editions
  for select using (true);

drop policy if exists editions_insert on public.editions;
create policy editions_insert on public.editions
  for insert with check (public.is_admin());

drop policy if exists editions_update on public.editions;
create policy editions_update on public.editions
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists editions_delete on public.editions;
create policy editions_delete on public.editions
  for delete using (public.is_admin());

-- results: lectura pública; los editores pueden crear, editar y borrar filas.
drop policy if exists results_select on public.results;
create policy results_select on public.results
  for select using (true);

drop policy if exists results_insert on public.results;
create policy results_insert on public.results
  for insert with check (public.is_editor());

drop policy if exists results_update on public.results;
create policy results_update on public.results
  for update using (public.is_editor()) with check (public.is_editor());

drop policy if exists results_delete on public.results;
create policy results_delete on public.results
  for delete using (public.is_editor());

-- audit_log: visible para editores y admin. Nadie escribe a mano (lo hace el
-- trigger, que es SECURITY DEFINER y por tanto salta RLS).
drop policy if exists audit_select on public.audit_log;
create policy audit_select on public.audit_log
  for select using (public.is_editor());

-- ============================================================================
--  BOOTSTRAP  ->  ejecuta esto aparte, cambiando el correo por el tuyo.
-- ============================================================================
--
--  insert into public.invitations (email, role, note)
--  values ('tucorreo@ejemplo.com', 'admin', 'Administrador inicial')
--  on conflict (email) do update set role = 'admin', used_at = null;
--
--  Luego abre la web, pulsa "Entrar" -> "Crear cuenta", usa ese mismo correo
--  y la contraseña que quieras. Quedarás registrado como admin.
--
--  Si ya te registraste antes y quieres forzar el rol admin:
--  update public.profiles set role = 'admin' where email = 'tucorreo@ejemplo.com';
-- ============================================================================
