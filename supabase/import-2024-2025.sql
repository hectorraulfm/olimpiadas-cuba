-- ============================================================================
--  PAGMO 2025 (Brasil) y Centroamericana 2024
--  Fuente: datos aportados el 13 de agosto de 2026.
-- ----------------------------------------------------------------------------
--  La PAGMO 2024 no aparece aquí: ya estaba cargada y coincide exactamente con
--  lo aportado.
--
--  Los nombres siguen la norma acordada: tilde donde el apellido la lleva.
--
--  REGLA: solo escribe en filas vacías.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.results disable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 1. PAGMO 2025, celebrada en Brasil
--    Una plata y dos bronces. La cuarta integrante no consta con medalla.
-- ----------------------------------------------------------------------------

with datos(orden, nombre, premio) as (
  values
    (1, 'Gabriela Arcia Martínez',           'Plata'),
    (2, 'Lía Claro Cabezas',                 'Bronce'),
    (3, 'Grethel de la Caridad Tubella',     'Bronce'),
    (4, 'Isabel Cárdenas González',          null)
)
update public.results r
   set contestant = d.nombre,
       award      = d.premio
  from datos d
 where r.competition = 'pagmo'
   and r.year = 2025
   and r.sort_order = d.orden
   and r.contestant = ''
   and r.award is null
   and r.total is null;

-- ----------------------------------------------------------------------------
-- 2. Centroamericana 2024
-- ----------------------------------------------------------------------------

with datos(orden, nombre, premio, puntos) as (
  values
    (1, 'Heidy Rodríguez Fuentes',    'Oro',    null),
    (2, 'Erick Díaz Pérez',           'Plata',  null),
    (3, 'Marcel Gámez Salvo',         'Plata',  null),
    (4, 'Liss Marian Estévez Suárez', 'Bronce', 15)
)
update public.results r
   set contestant = d.nombre,
       award      = d.premio,
       total      = d.puntos
  from datos d
 where r.competition = 'centro'
   and r.year = 2024
   and r.sort_order = d.orden
   and r.contestant = ''
   and r.award is null
   and r.total is null;

alter table public.results enable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 3. Comprobación
--    Esperado: pagmo 9 concursantes (1+4+4); centro 38 (34 previos + 4).
-- ----------------------------------------------------------------------------

select (select count(*) from public.results
         where competition = 'pagmo' and contestant <> '')   as pagmo,
       (select count(*) from public.results
         where competition = 'centro' and contestant <> '')  as centro,
       (select count(*) from public.results
         where competition = 'centro' and award = 'Oro')     as centro_oro;
