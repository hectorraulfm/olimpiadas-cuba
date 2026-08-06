-- ============================================================================
--  Siembra del esqueleto de la tabla
--  Crea una edición por año (1985 → 2025) y 4 filas de concursante en cada una.
-- ----------------------------------------------------------------------------
--  Requisito: haber ejecutado antes supabase/schema.sql
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo esto → Run
--
--  Todos los campos quedan vacíos a propósito: la idea es ir rellenándolos
--  desde la web. Se puede volver a ejecutar sin duplicar nada.
--
--  Cuando se celebre la edición de 2026, cambia el 2025 de la línea marcada
--  con [AÑO FINAL] por 2026 y vuelve a ejecutar; o simplemente usa el botón
--  «+ Nueva edición» de la web.
--
--  OJO: esto da por hecho que hubo participación cubana todos los años desde
--  1985. Si algún año no la hubo, borra esa edición desde la web (solo admin)
--  o con:  delete from public.editions where year = 1987;
-- ============================================================================

-- Silencia el historial mientras se siembra, para no llenarlo de 205 apuntes
-- automáticos sin autor.
alter table public.editions disable trigger editions_audit;
alter table public.results  disable trigger results_audit;

-- 1. Una edición por año.
insert into public.editions (year)
select y
  from generate_series(1985, 2025) as y   -- [AÑO FINAL]
on conflict (year) do nothing;

-- 2. Cuatro filas de concursante por edición.
--    El "not exists" evita duplicar si ya hay filas para ese año y posición.
insert into public.results (year, sort_order)
select e.year, s
  from public.editions e
  cross join generate_series(1, 4) as s
 where not exists (
         select 1
           from public.results r
          where r.year = e.year
            and r.sort_order = s
       );

alter table public.editions enable trigger editions_audit;
alter table public.results  enable trigger results_audit;

-- 3. Comprobación: debe dar 41 ediciones y 164 filas.
select (select count(*) from public.editions) as ediciones,
       (select count(*) from public.results)  as filas;
