-- ============================================================================
--  PAGMO 2023 y el líder de la Iberoamericana 2025
-- ----------------------------------------------------------------------------
--  Fuentes:
--    · Cubainformación, 12 de agosto de 2023, sobre la plata de Dalia Oliver
--      en la III PAGMO celebrada en Costa Rica.
--    · Agencia Cubana de Noticias, sobre la Iberoamericana de 2025 en Chile,
--      que nombra a Heriberto Donet Carrillo como jefe de la delegación.
--
--  Es lo único que la prensa publica con nombre y apellido. La web oficial de
--  la PAGMO no llegó a publicar tablas de resultados de ninguna edición.
--
--  REGLA: solo escribe donde no haya nada.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
-- ============================================================================

alter table public.editions disable trigger editions_audit;
alter table public.results  disable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 1. PAGMO 2023: plata de Dalia Oliver, 38 puntos de 42
-- ----------------------------------------------------------------------------

update public.results
   set contestant = 'Dalia Oliver Ballesteros',
       award      = 'Plata',
       total      = 38,
       notes      = 'La prensa la nombra como "Dalia Oliver". El apellido '
                    || 'completo se toma de sus fichas oficiales de IMO e '
                    || 'Iberoamericana de 2025.'
 where competition = 'pagmo'
   and year = 2023
   and sort_order = 1
   and contestant = ''
   and award is null
   and total is null;

update public.editions
   set leader = 'Amalia García'
 where competition = 'pagmo'
   and year = 2023
   and leader = '';

-- ----------------------------------------------------------------------------
-- 2. Iberoamericana 2025: jefe de delegación
-- ----------------------------------------------------------------------------

update public.editions
   set leader = 'Heriberto Donet Carrillo'
 where competition = 'ibero'
   and year = 2025
   and leader = '';

alter table public.editions enable trigger editions_audit;
alter table public.results  enable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 3. Comprobación. Esperado: 1 fila en pagmo con datos, y las dos ediciones
--    con su líder.
-- ----------------------------------------------------------------------------

select (select count(*) from public.results
         where competition = 'pagmo' and contestant <> '')            as pagmo_con_datos,
       (select leader from public.editions
         where competition = 'pagmo' and year = 2023)                 as lider_pagmo_2023,
       (select leader from public.editions
         where competition = 'ibero' and year = 2025)                 as lider_ibero_2025;
