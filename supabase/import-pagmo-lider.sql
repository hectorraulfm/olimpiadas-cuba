-- ============================================================================
--  PAGMO: Amalia García Suáres, líder en todas las ediciones
--  Fuente: dato aportado el 13 de agosto de 2026.
-- ----------------------------------------------------------------------------
--  Se aplica a las cinco ediciones, de 2021 a 2025.
--
--  A diferencia de otras importaciones, esta SÍ sobrescribe: la edición de
--  2023 tenía "Amalia García" a secas, tomado de una nota de prensa, y pasa al
--  nombre completo.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.editions disable trigger editions_audit;

update public.editions
   set leader = 'Amalia García Suáres'
 where competition = 'pagmo';

alter table public.editions enable trigger editions_audit;

-- ----------------------------------------------------------------------------
--  Comprobación. Esperado: 5 ediciones, las 5 con Amalia.
-- ----------------------------------------------------------------------------

select count(*)                                                as ediciones,
       count(*) filter (where leader = 'Amalia García Suáres') as con_amalia
  from public.editions
 where competition = 'pagmo';
