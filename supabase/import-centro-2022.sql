-- ============================================================================
--  Centroamericana 2022: delegación cubana completa
--  Fuente: acta oficial de resultados de la OMCC 2022 (Resultados 2022.xlsx),
--          hojas «Medallas» y «Resultados por países».
-- ----------------------------------------------------------------------------
--  Los cuatro concursantes con su desglose por problema, total y medalla.
--  Las cuatro puntuaciones suman 61, que es el total por equipo que da la
--  propia acta, así que los datos cuadran consigo mismos.
--
--  La edición fue virtual, organizada desde Costa Rica.
--
--  REGLA: solo escribe en filas vacías.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.results  disable trigger results_audit;
alter table public.editions disable trigger editions_audit;

with datos(orden, nombre, a1, a2, a3, a4, a5, a6, puntos, premio) as (
  values
    (1, 'Damiam David Fuentes Campos',     7,3,1,0,7,0, 18, 'Plata'),
    (2, 'Karla Yisel Ramírez Garcell',     7,3,0,0,4,1, 15, 'Plata'),
    (3, 'Ricardo Miguel Molano Domínguez', 7,7,0,0,1,0, 15, 'Plata'),
    (4, 'Alejandro Pedraza Guevara',       7,3,1,0,1,1, 13, 'Bronce')
)
update public.results r
   set contestant = d.nombre,
       p1 = d.a1, p2 = d.a2, p3 = d.a3,
       p4 = d.a4, p5 = d.a5, p6 = d.a6,
       total = d.puntos,
       award = d.premio
  from datos d
 where r.competition = 'centro'
   and r.year = 2022
   and r.sort_order = d.orden
   and r.contestant = ''
   and r.award is null
   and r.total is null;

update public.editions
   set host_country = 'Costa Rica',
       host_city    = '(virtual)'
 where competition = 'centro'
   and year = 2022
   and host_country = '';

-- La misma acta documenta que Cuba no participó en la OMCC de 2021.
update public.editions
   set notes = 'Cuba no participó: la Copa El Salvador de 2022 le asigna 0 puntos y 0 concursantes en 2021.'
 where competition = 'centro'
   and year = 2021
   and notes = '';

alter table public.results  enable trigger results_audit;
alter table public.editions enable trigger editions_audit;

-- ----------------------------------------------------------------------------
--  Comprobación. Esperado: 4 concursantes en 2022 y 61 puntos de equipo.
-- ----------------------------------------------------------------------------

select count(*) filter (where contestant <> '') as concursantes,
       sum(total)                               as puntos_equipo,
       count(*) filter (where award = 'Plata')  as plata,
       count(*) filter (where award = 'Bronce') as bronce
  from public.results
 where competition = 'centro'
   and year = 2022;
