-- ============================================================================
--  IMO: líderes y colíderes de la delegación cubana
--  Fuente: https://www.imo-official.org/results/team/country/CUB/
--          consultada el 13 de agosto de 2026. Es la fuente oficial.
-- ----------------------------------------------------------------------------
--  Trae los jefes de delegación de las 26 ediciones en que la fuente los
--  publica. Las otras 22 los deja en blanco, así que aquí no aparecen.
--
--  Los nombres van tal como los publica la IMO, sin unificar. La misma persona
--  aparece escrita de varias formas según el año (por ejemplo "Luis Davidson",
--  "L. Davidson" y "Luis J. Davidson"), y se respeta el original.
--
--  REGLA: solo escribe donde el campo esté vacío.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.editions disable trigger editions_audit;

with jefes(anyo, lider, colider) as (
  values
    (2026, 'Ernesto Alejandro Lopez Cadalso', 'Hector Raul Fernandez Morales'),
    (2025, 'Prudencio Guerrero Fernández',    ''),
    (2024, 'Ernesto Alejandro López Cadalso', 'Roman Fresneda Quiroga'),
    (2023, '',                                'Evidio Quintana Fernández'),
    (2022, 'Prudencio Guerrero Fernández',    ''),
    (2019, 'Evidio Quintana Fernández',       'Roman Fresneda Quiroga'),
    (2017, 'Nelson Tomás Hernández Reyes',    ''),
    (2015, 'Eduardo Miguel Pérez Almarales',  ''),
    (2014, 'Enech Juan García Martínez',      ''),
    (2013, 'Eduardo Pérez Almarales',         ''),
    (2012, 'Enech García Martínez',           ''),
    (2010, 'Eduardo Pérez Almarales',         ''),
    (2009, 'Eduardo Pérez Almarales',         ''),
    (2008, 'Eduardo Pérez Almarales',         ''),
    (2007, 'Raúl Ochoa Rojas',                ''),
    (2004, 'Raoul Ochoa Rojas',               ''),
    (1998, 'Rojas Ochoa',                     ''),
    (1991, 'Alexis Duran Jorrin',             'Maria E. Santibanez Pinera'),
    (1985, 'Luis Davidson',                   'Raimundo Reguera'),
    (1979, 'Felix Recio',                     ''),
    (1977, 'Felix Recio',                     ''),
    (1976, 'N. del Prado',                    ''),
    (1974, 'Luis Davidson',                   'Felix Recio'),
    (1973, 'L. Davidson',                     'F. Recio'),
    (1972, 'Luis J. Davidson',                'Felix Recio'),
    (1971, 'Luis Davidson',                   '')
)
update public.editions e
   set leader = j.lider
  from jefes j
 where e.competition = 'imo'
   and e.year = j.anyo
   and e.leader = ''      -- respeta el que ya hubiera
   and j.lider <> '';

with jefes(anyo, colider) as (
  values
    (2026, 'Hector Raul Fernandez Morales'),
    (2024, 'Roman Fresneda Quiroga'),
    (2023, 'Evidio Quintana Fernández'),
    (2019, 'Roman Fresneda Quiroga'),
    (1991, 'Maria E. Santibanez Pinera'),
    (1985, 'Raimundo Reguera'),
    (1974, 'Felix Recio'),
    (1973, 'F. Recio'),
    (1972, 'Felix Recio')
)
update public.editions e
   set deputy_leader = j.colider
  from jefes j
 where e.competition = 'imo'
   and e.year = j.anyo
   and e.deputy_leader = '';

alter table public.editions enable trigger editions_audit;

-- ----------------------------------------------------------------------------
--  Comprobación. Esperado: 25 con líder y 9 con colíder.
--  (25 y no 26 porque en 2023 la fuente solo publica el colíder.)
-- ----------------------------------------------------------------------------

select count(*) filter (where leader <> '')        as con_lider,
       count(*) filter (where deputy_leader <> '') as con_colider
  from public.editions
 where competition = 'imo';
