-- ============================================================================
--  PAGMO 2024: delegación cubana completa
--  Fuente: dato aportado el 13 de agosto de 2026.
-- ----------------------------------------------------------------------------
--  La IV PAGMO se celebró en Durango, México, del 24 al 30 de noviembre de
--  2024, con 55 concursantes de 15 países.
--
--  No hay puntuaciones por problema ni totales: la fuente solo da las medallas.
--
--  REGLA: solo escribe en filas vacías.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.results disable trigger results_audit;

with datos(orden, nombre, premio) as (
  values
    (1, 'Heidy Rodríguez Fuentes',              'Bronce'),
    (2, 'Liss Marian Estevez Suárez',            'Bronce'),
    (3, 'Salet Margginna Cox Martínez',          'Mención de Honor'),
    (4, 'Isabel Liz Gonzales Cárdenas',          null)
)
update public.results r
   set contestant = d.nombre,
       award      = d.premio
  from datos d
 where r.competition = 'pagmo'
   and r.year = 2024
   and r.sort_order = d.orden
   and r.contestant = ''
   and r.award is null
   and r.total is null;

alter table public.results enable trigger results_audit;

-- ----------------------------------------------------------------------------
--  Comprobación. Esperado: 5 concursantes en la PAGMO (1 de 2023 y 4 de 2024),
--  con 1 plata, 2 bronces y 1 mención.
-- ----------------------------------------------------------------------------

select count(*) filter (where contestant <> '')           as concursantes,
       count(*) filter (where award = 'Plata')            as plata,
       count(*) filter (where award = 'Bronce')           as bronce,
       count(*) filter (where award = 'Mención de Honor') as mencion
  from public.results
 where competition = 'pagmo';
