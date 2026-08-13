-- ============================================================================
--  Unifica las variantes del nombre de Luis Davidson en la IMO
-- ----------------------------------------------------------------------------
--  La fuente oficial escribe a la misma persona de tres formas según el año:
--  "Luis Davidson" (1971, 1974, 1985), "Luis J. Davidson" (1972) y
--  "L. Davidson" (1973). Se unifican en la primera.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.editions disable trigger editions_audit;

update public.editions
   set leader = 'Luis Davidson'
 where competition = 'imo'
   and leader in ('L. Davidson', 'Luis J. Davidson');

alter table public.editions enable trigger editions_audit;

-- Comprobación: debe dar 5 ediciones con Luis Davidson y 0 con variantes.
select count(*) filter (where leader = 'Luis Davidson')                    as unificados,
       count(*) filter (where leader in ('L. Davidson', 'Luis J. Davidson')) as quedan_variantes
  from public.editions
 where competition = 'imo';
