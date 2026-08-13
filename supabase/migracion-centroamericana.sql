-- ============================================================================
--  Añade la Olimpiada Centroamericana y del Caribe junto a la Iberoamericana
-- ----------------------------------------------------------------------------
--  Hasta ahora la base de datos daba por hecho que solo había una competición:
--  cada edición se identificaba por su año a secas. Ahora hay dos, así que la
--  identidad de una edición pasa a ser (competición, año).
--
--  Todo lo que ya existe se marca como 'ibero', así que la tabla actual queda
--  exactamente igual.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente: se puede ejecutar varias veces sin duplicar nada.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Nueva columna en ambas tablas
-- ----------------------------------------------------------------------------

alter table public.editions
  add column if not exists competition text not null default 'ibero';

alter table public.results
  add column if not exists competition text not null default 'ibero';

alter table public.editions drop constraint if exists editions_competition_check;
alter table public.editions add constraint editions_competition_check
  check (competition in ('ibero', 'centro'));

alter table public.results drop constraint if exists results_competition_check;
alter table public.results add constraint results_competition_check
  check (competition in ('ibero', 'centro'));

-- ----------------------------------------------------------------------------
-- 2. La clave de una edición pasa de (año) a (competición, año)
-- ----------------------------------------------------------------------------

-- Primero se suelta la clave ajena, que depende de la primaria.
alter table public.results drop constraint if exists results_year_fkey;
alter table public.results drop constraint if exists results_edition_fkey;

alter table public.editions drop constraint if exists editions_pkey;
alter table public.editions add primary key (competition, year);

alter table public.results add constraint results_edition_fkey
  foreign key (competition, year)
  references public.editions (competition, year)
  on delete cascade;

create index if not exists results_comp_year_idx
  on public.results (competition, year, sort_order);

-- ----------------------------------------------------------------------------
-- 3. El historial debe distinguir de qué competición habla
-- ----------------------------------------------------------------------------

create or replace function public.log_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  rid text;
begin
  rid := coalesce(to_jsonb(new) ->> 'id', to_jsonb(old) ->> 'id',
                  coalesce(to_jsonb(new) ->> 'competition',
                           to_jsonb(old) ->> 'competition', '?')
                    || ' '
                    || coalesce(to_jsonb(new) ->> 'year',
                                to_jsonb(old) ->> 'year', '?'));

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

-- ----------------------------------------------------------------------------
-- 4. Siembra de la Centroamericana: 1999 a 2025
--    Se celebra todos los años desde 1999.
--    Las delegaciones eran de 3 concursantes hasta 2017 incluido, y de 4
--    desde 2018.
-- ----------------------------------------------------------------------------

alter table public.editions disable trigger editions_audit;
alter table public.results  disable trigger results_audit;

insert into public.editions (competition, year)
select 'centro', y
  from generate_series(1999, 2025) as y   -- [AÑO FINAL]
on conflict (competition, year) do nothing;

insert into public.results (competition, year, sort_order)
select 'centro', e.year, s
  from public.editions e
  cross join generate_series(1, 4) as s
 where e.competition = 'centro'
   and (s <= 3 or e.year >= 2018)   -- la cuarta plaza solo desde 2018
   and not exists (
         select 1 from public.results r
          where r.competition = 'centro'
            and r.year = e.year
            and r.sort_order = s
       );

alter table public.editions enable trigger editions_audit;
alter table public.results  enable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 5. Comprobación
--    Esperado: ibero 40 ediciones y 160 filas;
--              centro 27 ediciones y 89 filas (19 años x 3 + 8 años x 4).
-- ----------------------------------------------------------------------------

select e.competition,
       count(distinct e.year)                                as ediciones,
       (select count(*) from public.results r
         where r.competition = e.competition)                as filas
  from public.editions e
 group by e.competition
 order by e.competition;
