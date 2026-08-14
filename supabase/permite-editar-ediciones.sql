-- ============================================================================
--  Los editores pasan a poder modificar las ediciones
-- ----------------------------------------------------------------------------
--  Hasta ahora solo el admin podía tocar el país organizador, la sede, el
--  líder y el colíder. Ahora también los editores.
--
--  Siguen reservadas al admin las dos acciones estructurales:
--    · crear una edición nueva
--    · borrar una edición entera, con sus concursantes
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

drop policy if exists editions_update on public.editions;
create policy editions_update on public.editions
  for update using (public.is_editor()) with check (public.is_editor());

-- ----------------------------------------------------------------------------
--  Comprobación: las cuatro políticas de editions y quién puede cada cosa.
-- ----------------------------------------------------------------------------

select policyname, cmd, coalesce(qual, with_check) as condicion
  from pg_policies
 where schemaname = 'public'
   and tablename = 'editions'
 order by cmd, policyname;
