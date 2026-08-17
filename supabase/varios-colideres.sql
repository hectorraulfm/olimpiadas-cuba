-- ============================================================================
--  Varios colíderes en una misma edición
-- ----------------------------------------------------------------------------
--  El campo pasa a admitir más de un nombre, uno por línea. La web muestra
--  cada uno en su renglón y el formulario ofrece un cuadro de varias líneas.
--
--  Solo hay un caso previo con dos personas: la Iberoamericana de 1985, donde
--  estaban separadas por coma. Se convierte al formato nuevo.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.editions disable trigger editions_audit;

update public.editions
   set deputy_leader = replace(deputy_leader, ', ', chr(10))
 where deputy_leader like '%, %';

alter table public.editions enable trigger editions_audit;

-- ----------------------------------------------------------------------------
--  Comprobación. Esperado: 1 edición con dos colíderes y ninguna con coma.
-- ----------------------------------------------------------------------------

select count(*) filter (where deputy_leader like '%' || chr(10) || '%') as con_varios,
       count(*) filter (where deputy_leader like '%, %')                as quedan_con_coma
  from public.editions;
