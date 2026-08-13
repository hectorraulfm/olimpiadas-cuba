-- ============================================================================
--  Unifica el nombre de Karla Yisel Ramírez Garcell
-- ----------------------------------------------------------------------------
--  Aparece en cinco filas de tres competiciones, escrita de tres formas:
--    · "Karla Yisel Ramírez Garcell"  — acta OMCC 2022 y la IMO de 2023
--    · "Karla Yisell Ramírez Garcell" — Iberoamericana de 2023
--    · "Karla Yisel Ramírez Garcel"   — IMO e Iberoamericana de 2024
--
--  Forma acordada: Yisel con una ele, Garcell con dos.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.results disable trigger results_audit;

update public.results
   set contestant = 'Karla Yisel Ramírez Garcell'
 where contestant in ('Karla Yisell Ramírez Garcell',
                      'Karla Yisel Ramírez Garcel');

alter table public.results enable trigger results_audit;

-- ----------------------------------------------------------------------------
--  Comprobación. Esperado: 5 filas con la forma buena y 0 con las otras.
-- ----------------------------------------------------------------------------

select count(*) filter (where contestant = 'Karla Yisel Ramírez Garcell') as unificadas,
       count(*) filter (where contestant like 'Karla%'
                          and contestant <> 'Karla Yisel Ramírez Garcell') as quedan_variantes
  from public.results;
