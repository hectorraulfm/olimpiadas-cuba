-- ============================================================================
--  Centroamericana 2025: delegación cubana completa
--  Fuentes:
--    · Tabla oficial de puntajes de la OMCC 2025 (Puntajes OMCC 2025.pdf),
--      que da el desglose por problema, el total y la medalla de cada código.
--    · Correspondencia entre código y nombre de pila, aportada el 13 de
--      agosto de 2026.
--    · Los apellidos de Diego, Yeison y Javier se completan con la plantilla
--      cubana de la IMO 2026, donde los tres figuran con nombre completo.
-- ----------------------------------------------------------------------------
--  Las cuatro puntuaciones suman 80 puntos de equipo.
--
--  REGLA: solo escribe en filas vacías.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.results disable trigger results_audit;

with datos(orden, nombre, a1, a2, a3, a4, a5, a6, puntos, premio, nota) as (
  values
    (1, 'Diego García Rodríguez',         7,7,0,7,7,1, 29, 'Oro',    'CUB3 en el acta'),
    (2, 'Yeison Alejandro Davy Abreu',    7,4,4,7,1,1, 24, 'Plata',  'CUB4 en el acta'),
    (3, 'Javier Ernesto Galindo Nápoles', 7,0,0,7,1,7, 22, 'Bronce', 'CUB2 en el acta'),
    (4, 'Mauricio Chinchilla',            1,0,0,4,0,0,  5, null,     'CUB1 en el acta')
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
   and r.year = 2025
   and r.sort_order = d.orden
   and r.contestant = ''
   and r.award is null
   and r.total is null;

alter table public.results enable trigger results_audit;

-- ----------------------------------------------------------------------------
--  Comprobación. Esperado: 4 concursantes, 80 puntos de equipo,
--  y 10 oros en toda la historia centroamericana.
-- ----------------------------------------------------------------------------

select (select count(*) from public.results
         where competition = 'centro' and year = 2025 and contestant <> '') as concursantes,
       (select sum(total) from public.results
         where competition = 'centro' and year = 2025)                      as puntos_equipo,
       (select count(*) from public.results
         where competition = 'centro' and award = 'Oro')                    as oros_totales;
