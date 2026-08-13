-- ============================================================================
--  Añade la PAGMO (Panamericana Femenina) y la Centroamericana de 2026
-- ----------------------------------------------------------------------------
--  1. Nueva competición 'pagmo': Olimpiada Panamericana Femenina de
--     Matemática, celebrada desde 2021 con delegaciones de 4 concursantes.
--     Se crean las ediciones de 2021 a 2025 con 4 plazas cada una, todas
--     vacías. La de 2026 aún no se ha celebrado (suele ser en noviembre);
--     cuando toque, se añade con el botón «+ Nueva edición».
--
--  2. Centroamericana 2026, que se está celebrando ahora, con sus 4 plazas.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Admitir la nueva competición
-- ----------------------------------------------------------------------------

alter table public.editions drop constraint if exists editions_competition_check;
alter table public.editions add constraint editions_competition_check
  check (competition in ('ibero', 'centro', 'imo', 'pagmo'));

alter table public.results drop constraint if exists results_competition_check;
alter table public.results add constraint results_competition_check
  check (competition in ('ibero', 'centro', 'imo', 'pagmo'));

alter table public.editions disable trigger editions_audit;
alter table public.results  disable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 2. PAGMO: ediciones 2021 a 2025, cuatro plazas cada una
-- ----------------------------------------------------------------------------

insert into public.editions (competition, year)
select 'pagmo', y
  from generate_series(2021, 2025) as y   -- [AÑO FINAL]
on conflict (competition, year) do nothing;

insert into public.results (competition, year, sort_order)
select 'pagmo', e.year, s
  from public.editions e
  cross join generate_series(1, 4) as s
 where e.competition = 'pagmo'
   and not exists (
         select 1 from public.results r
          where r.competition = 'pagmo'
            and r.year = e.year
            and r.sort_order = s
       );

-- Sedes conocidas. Las dos primeras ediciones fueron virtuales.
with sedes(anyo, pais, ciudad) as (
  values
    (2021, '',           '(virtual)'),
    (2022, '',           '(virtual)'),
    (2023, 'Costa Rica', ''),
    (2024, 'México',     'Durango'),
    (2025, 'Brasil',     '')
)
update public.editions e
   set host_country = case when e.host_country = '' then s.pais else e.host_country end,
       host_city    = case when e.host_city    = '' then s.ciudad else e.host_city end
  from sedes s
 where e.competition = 'pagmo'
   and e.year = s.anyo;

-- ----------------------------------------------------------------------------
-- 3. Centroamericana 2026, en curso
-- ----------------------------------------------------------------------------

insert into public.editions (competition, year)
values ('centro', 2026)
on conflict (competition, year) do nothing;

insert into public.results (competition, year, sort_order)
select 'centro', 2026, s
  from generate_series(1, 4) as s
 where not exists (
         select 1 from public.results r
          where r.competition = 'centro'
            and r.year = 2026
            and r.sort_order = s
       );

alter table public.editions enable trigger editions_audit;
alter table public.results  enable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 4. Comprobación
--    Esperado: pagmo 5 ediciones y 20 filas; centro 28 ediciones y 93 filas.
-- ----------------------------------------------------------------------------

select e.competition,
       count(distinct e.year)                                as ediciones,
       (select count(*) from public.results r
         where r.competition = e.competition)                as filas
  from public.editions e
 group by e.competition
 order by e.competition;
