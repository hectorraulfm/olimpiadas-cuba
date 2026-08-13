-- ============================================================================
--  Unifica las variantes de nombre de los jefes de delegación de la IMO
-- ----------------------------------------------------------------------------
--  La fuente oficial escribe a la misma persona de varias formas según el año.
--  Se elige una sola por persona, la más completa y correcta de las que la
--  propia IMO usa. No se inventa ninguna forma nueva.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.editions disable trigger editions_audit;

-- Luis Davidson: "Luis J. Davidson" (1972) y "L. Davidson" (1973).
update public.editions
   set leader = 'Luis Davidson'
 where competition = 'imo'
   and leader in ('L. Davidson', 'Luis J. Davidson');

-- Raúl Ochoa Rojas: "Rojas Ochoa" (1998) y "Raoul Ochoa Rojas" (2004).
update public.editions
   set leader = 'Raúl Ochoa Rojas'
 where competition = 'imo'
   and leader in ('Rojas Ochoa', 'Raoul Ochoa Rojas');

-- Eduardo Pérez Almarales: "Eduardo Miguel Pérez Almarales" (2015).
update public.editions
   set leader = 'Eduardo Pérez Almarales'
 where competition = 'imo'
   and leader = 'Eduardo Miguel Pérez Almarales';

-- Enech García Martínez: "Enech Juan García Martínez" (2014).
update public.editions
   set leader = 'Enech García Martínez'
 where competition = 'imo'
   and leader = 'Enech Juan García Martínez';

-- Felix Recio, como colíder: "F. Recio" (1973).
update public.editions
   set deputy_leader = 'Felix Recio'
 where competition = 'imo'
   and deputy_leader = 'F. Recio';

-- ----------------------------------------------------------------------------
--  Tildes. La IMO publica varios nombres sin acentuar. Se restituyen solo
--  cuando la misma persona ya figura acentuada en otra parte de esta base de
--  datos, para no inventar ortografía.
-- ----------------------------------------------------------------------------

update public.editions
   set leader = 'Ernesto Alejandro López Cadalso'
 where competition = 'imo'
   and leader = 'Ernesto Alejandro Lopez Cadalso';   -- ya acentuado en 2024

update public.editions
   set deputy_leader = 'Héctor Raúl Fernández Morales'
 where deputy_leader = 'Hector Raul Fernandez Morales';   -- ídem en ibero y centro

update public.editions
   set deputy_leader = 'Román Fresneda Quiroga'
 where competition = 'imo'
   and deputy_leader = 'Roman Fresneda Quiroga';   -- concursante en la IMO 1999

update public.editions
   set deputy_leader = 'María E. Santibáñez Piñera'
 where competition = 'imo'
   and deputy_leader = 'Maria E. Santibanez Pinera';   -- María Emilia, ibero 1988-89

-- Alexis Durán Jorrín aparece sin tildes en la IMO y a medias en la
-- Iberoamericana. Se unifica con la ortografía completa en ambas.
update public.editions
   set leader = 'Alexis Durán Jorrín'
 where leader in ('Alexis Duran Jorrin', 'Alexis Duran Jorrín');

alter table public.editions enable trigger editions_audit;

-- ----------------------------------------------------------------------------
--  Comprobación. Esperado: 5 · 3 · 6 · 2 · 3, y 0 variantes sueltas.
--  (Los nombres sin tilde deben haber desaparecido también.)
-- ----------------------------------------------------------------------------

select count(*) filter (where leader = 'Luis Davidson')           as davidson,
       count(*) filter (where leader = 'Raúl Ochoa Rojas')        as ochoa,
       count(*) filter (where leader = 'Eduardo Pérez Almarales') as almarales,
       count(*) filter (where leader = 'Enech García Martínez')   as enech,
       count(*) filter (where deputy_leader = 'Felix Recio')      as recio,
       count(*) filter (where leader in ('L. Davidson', 'Luis J. Davidson',
                                         'Rojas Ochoa', 'Raoul Ochoa Rojas',
                                         'Eduardo Miguel Pérez Almarales',
                                         'Enech Juan García Martínez',
                                         'Ernesto Alejandro Lopez Cadalso',
                                         'Alexis Duran Jorrin')
                          or deputy_leader in ('F. Recio',
                                               'Hector Raul Fernandez Morales',
                                               'Roman Fresneda Quiroga',
                                               'Maria E. Santibanez Pinera'))
                                                                  as quedan_variantes
  from public.editions
 where competition = 'imo';
