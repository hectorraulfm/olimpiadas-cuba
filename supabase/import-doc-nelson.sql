-- ============================================================================
--  Importación desde el documento "ibero nelson.docx"
-- ----------------------------------------------------------------------------
--  Trae:
--    · Líderes y colíderes de 29 ediciones (el documento es la única fuente
--      que los recoge).
--    · 28 concursantes en 9 años que estaban completamente vacíos:
--      1985, 1988, 1989, 1994, 1995, 1996, 1997, 1998 y 2008.
--    · El nombre del concursante que en 2006 figuraba como "CUB 03".
--
--  REGLA: nunca pisa lo que ya está en la web.
--    · Los concursantes solo se escriben en años donde NO hay ni un solo dato.
--      Si un año ya tiene algo, se deja intacto por completo.
--    · El líder solo se escribe si el campo está vacío; ídem el colíder.
--
--  El documento no trae puntuación por problema, así que esas columnas quedan
--  como estaban.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente y se puede ejecutar varias veces sin duplicar nada.
-- ============================================================================

alter table public.editions disable trigger editions_audit;
alter table public.results  disable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 1. Líderes
-- ----------------------------------------------------------------------------

with jefes(anyo, lider, colider) as (
  values
    (1985, 'Raimundo Reguera Vilar',      'Félix Muñoz Baños, Mario Díaz González'),
    (1988, 'Raimundo Reguera Vilar',      'María Emilia Santibáñez Piñera'),
    (1989, 'María Emilia Santibáñez Piñera', 'Ángel Pérez Cuza'),
    (1993, 'Félix Muñoz Baños',           'Oscar Dalmau'),
    (1994, 'Alexis Duran Jorrín',         ''),
    (1995, 'Felix Revilla Mengana',       ''),
    (1996, 'Alexis Duran Jorrín',         ''),
    (1997, 'Felix Revilla Mengana',       ''),
    (1998, 'Felix Revilla Menganal',      'Nelson Hernández Reyes'),
    (1999, 'Felix Revilla Menganal',      'Nelson Hernández Reyes'),
    (2000, 'Enech García Martínez',       'Eduardo Pérez Almarales'),
    (2001, 'Mario Díaz González',         'Eduardo Pérez Almarales'),
    (2002, 'Mario Díaz González',         'Roberto Del Monte'),
    (2003, 'Mario Díaz González',         'Eduardo Pérez Almarales'),
    (2004, 'Mario Díaz González',         'Eduardo Pérez Almarales'),
    (2005, 'Mario Díaz González',         'Eduardo Pérez Almarales'),
    (2006, 'Mario Díaz González',         'Eduardo Pérez Almarales'),
    (2007, 'Mario Díaz González',         'Eduardo Pérez Almarales'),
    (2008, 'Mario Díaz González',         'Gustavo Carranza Carpio'),
    (2009, 'Mario Díaz González',         ''),
    (2015, 'Enech García Martínez',       ''),
    (2017, 'Enech García Martínez',       ''),
    (2018, 'Prudencio Guerrero Fernández', ''),
    (2019, 'Justo Javier',                ''),
    (2020, 'Nelson Hernández Reyes',      'Sofia Albizu-Campos Rodríguez'),
    (2021, 'Evidio Quintana Fernández',   'Ernesto Alejandro López Cadalso'),
    (2022, 'Ernesto Alejandro López Cadalso', ''),
    (2023, 'Nelson Hernández Reyes',      ''),
    (2024, 'Nelson Hernández Reyes',      'Héctor Raúl Fernández Morales')
)
update public.editions e
   set leader = j.lider
  from jefes j
 where e.year = j.anyo
   and e.leader = ''        -- respeta el que ya hubiera
   and j.lider <> '';

with jefes(anyo, colider) as (
  values
    (1985, 'Félix Muñoz Baños, Mario Díaz González'),
    (1988, 'María Emilia Santibáñez Piñera'),
    (1989, 'Ángel Pérez Cuza'),
    (1993, 'Oscar Dalmau'),
    (1998, 'Nelson Hernández Reyes'),
    (1999, 'Nelson Hernández Reyes'),
    (2000, 'Eduardo Pérez Almarales'),
    (2001, 'Eduardo Pérez Almarales'),
    (2002, 'Roberto Del Monte'),
    (2003, 'Eduardo Pérez Almarales'),
    (2004, 'Eduardo Pérez Almarales'),
    (2005, 'Eduardo Pérez Almarales'),
    (2006, 'Eduardo Pérez Almarales'),
    (2007, 'Eduardo Pérez Almarales'),
    (2008, 'Gustavo Carranza Carpio'),
    (2020, 'Sofia Albizu-Campos Rodríguez'),
    (2021, 'Ernesto Alejandro López Cadalso'),
    (2024, 'Héctor Raúl Fernández Morales')
)
update public.editions e
   set deputy_leader = j.colider
  from jefes j
 where e.year = j.anyo
   and e.deputy_leader = '';   -- respeta el que ya hubiera

-- ----------------------------------------------------------------------------
-- 2. Concursantes, solo en años íntegramente vacíos
-- ----------------------------------------------------------------------------

with datos(anyo, orden, nombre, premio) as (
  values
    (1985, 1, 'Ángel Ribalta Standford',          'Oro'),
    (1985, 2, 'Daniel Alfaro Vigo',               'Plata'),
    (1985, 3, 'Alfredo Herrera Hernández',        'Bronce'),
    (1985, 4, 'Jorge Lodos Vigil',                'Bronce'),
    (1988, 1, 'René Guerra Mollet',               'Oro'),
    (1988, 2, 'Sergio Torres Fernández',          'Oro'),
    (1988, 3, 'Jorge Luis de Armas García',       'Plata'),
    (1988, 4, 'Aldo Rodríguez González',          'Plata'),
    (1989, 1, 'Rolando Uranga Peña',              'Oro'),
    (1989, 2, 'Mauricio Romero Sicre',            'Bronce'),
    (1989, 3, 'Rodmar Rodríguez Martin',          'Bronce'),
    (1989, 4, 'Alnardo Pérez Vázquez',            'Bronce'),
    (1994, 1, 'Humberto Martínez',                'Plata'),
    (1994, 2, 'Alexander Álvarez Hernández',      'Bronce'),
    (1995, 1, 'Lorver Duarte Puig',               'Plata'),
    (1996, 1, 'Enrique Pórtela García',           'Bronce'),
    (1997, 1, 'Lorver Duarte Puig',               'Oro'),
    (1997, 2, 'Enrique Pórtela García',           'Bronce'),
    (1997, 3, 'Alden Torres',                     'Bronce'),
    (1997, 4, 'Yudith Escandon Suarez',           'Bronce'),
    (1998, 1, 'Andres Gago Alonso',               null),
    (1998, 2, 'Maikel Arcias Carranza',           null),
    (1998, 3, 'Abel Meneses Abad',                null),
    (1998, 4, 'Franklin Vera Pacheco',            null),
    (2008, 1, 'Manuel A. Candales Rodríguez',     'Oro'),
    (2008, 2, 'Alí Guzmán Adán',                  'Plata'),
    (2008, 3, 'Antonio Ismael García Rodríguez',  'Bronce'),
    (2008, 4, 'Otto A. León Negrín',              'Bronce')
)
update public.results r
   set contestant = d.nombre,
       award      = d.premio
  from datos d
 where r.year = d.anyo
   and r.sort_order = d.orden
   -- la fila concreta está vacía...
   and r.contestant = ''
   and r.award is null
   and r.total is null
   -- ...y el año entero también, para no mezclar dos fuentes en un mismo año
   and not exists (
         select 1 from public.results x
          where x.year = d.anyo
            and (x.contestant <> '' or x.award is not null or x.total is not null)
       );

-- ----------------------------------------------------------------------------
-- 3. Caso 2006: nombres en clave
--    La web tenía CUB 01..CUB 04 en vez de nombres. El documento da los cuatro
--    nombres, pero no qué código corresponde a quién.
--    Las medallas coinciden en las dos fuentes (tres Plata y un Bronce), así
--    que el Bronce se puede identificar sin ambigüedad. Los tres de Plata no.
-- ----------------------------------------------------------------------------

-- El único Bronce de 2006: CUB 03.
update public.results
   set contestant = 'Jorge Luis Toro Pozo'
 where year = 2006
   and contestant = 'CUB 03'
   and award = 'Bronce';

-- Los tres de Plata conservan el código, pero se anota quiénes pueden ser.
update public.results
   set notes = 'Uno de: Douglas Curbelo Aguilera, Jorge Patricio Castillo, '
               || 'Alvaro Suárez Fuentes (el documento no dice qué código es cada uno)'
 where year = 2006
   and contestant in ('CUB 01', 'CUB 02', 'CUB 04')
   and notes = '';

alter table public.editions enable trigger editions_audit;
alter table public.results  enable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 4. Comprobación
-- ----------------------------------------------------------------------------

select (select count(*) from public.editions where leader <> '')         as con_lider,
       (select count(*) from public.editions where deputy_leader <> '')  as con_colider,
       (select count(*) from public.results
         where contestant <> '' or award is not null or total is not null) as filas_con_dato;
