-- ============================================================================
--  Centroamericana 2023: delegación cubana
--  Fuente: acta oficial de la XXV OMCC (Resultados OMCC 2023.xlsx),
--          celebrada en La Herradura, La Paz, El Salvador,
--          del 21 al 29 de julio de 2023.
-- ----------------------------------------------------------------------------
--  Cuba llevó DOS concursantes, no cuatro. El acta reserva los códigos CUB 3 y
--  CUB 4 pero los deja sin nombre y con cero puntos, y el resumen por países
--  da 58 puntos de equipo, que es exactamente 31 + 27. Por eso las filas
--  tercera y cuarta se quedan vacías a propósito.
--
--  Los nombres se escriben con la forma que ya usa el resto de la base:
--  el acta pone "Ián" y "Dalía", pero las fuentes oficiales de la IMO y la
--  Iberoamericana los escriben "Ian" y "Dalia".
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

with datos(orden, nombre, a1, a2, a3, a4, a5, a6, puntos, premio, nota) as (
  values
    (1, 'Ian David Lorenzo García',  7,7,3,7,7,0, 31, 'Plata', 'CUB 1 en el acta'),
    (2, 'Dalia Oliver Ballesteros',  6,3,4,6,7,1, 27, 'Plata', 'CUB 2 en el acta')
)
update public.results r
   set contestant = d.nombre,
       p1 = d.a1, p2 = d.a2, p3 = d.a3,
       p4 = d.a4, p5 = d.a5, p6 = d.a6,
       total = d.puntos,
       award = d.premio,
       notes = d.nota
  from datos d
 where r.competition = 'centro'
   and r.year = 2023
   and r.sort_order = d.orden
   and r.contestant = ''
   and r.award is null
   and r.total is null;

update public.editions
   set host_country = 'El Salvador',
       host_city    = 'La Herradura, La Paz'
 where competition = 'centro'
   and year = 2023
   and host_country = '';

update public.editions
   set notes = 'Cuba llevó solo dos concursantes: el acta deja CUB 3 y CUB 4 sin nombre y con cero puntos.'
 where competition = 'centro'
   and year = 2023
   and notes = '';

alter table public.results  enable trigger results_audit;
alter table public.editions enable trigger editions_audit;

-- ----------------------------------------------------------------------------
--  Comprobación. Esperado: 2 concursantes y 58 puntos de equipo.
-- ----------------------------------------------------------------------------

select count(*) filter (where contestant <> '') as concursantes,
       sum(total)                               as puntos_equipo,
       count(*) filter (where award = 'Plata')  as plata
  from public.results
 where competition = 'centro'
   and year = 2023;
