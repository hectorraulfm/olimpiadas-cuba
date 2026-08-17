-- ============================================================================
--  Unifica los nombres que designan a la misma persona
-- ----------------------------------------------------------------------------
--  Salen de comparar los 229 nombres distintos de la base entre sí, quedándose
--  con las parejas muy parecidas cuyas participaciones distan menos de 4 años.
--
--  Criterio general: se conserva la forma más completa, salvo cuando una
--  grafía tiene más respaldo en las fuentes o cuando hay confirmación directa.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.results disable trigger results_audit;

with correcciones(viejo, nuevo) as (
  values
    -- Nombre recortado por la fuente frente al completo
    ('Manuel A. Candales Rodríguez',  'Manuel Alejandro Candales Rodríguez'),
    ('Manuel Candales Rodríguez',     'Manuel Alejandro Candales Rodríguez'),
    ('Otto A. León Negrín',           'Otto Alberto León Negrín'),
    ('Otto León Negrín',              'Otto Alberto León Negrín'),
    ('Adrián Batista Planas',         'Adrián Luis Batista Planas'),
    ('Jorge E Moreira Broche',        'Jorge Enrique Moreira Broche'),
    ('Jorge Patricio Castillo',       'Jorge Patricio Castillo López'),
    ('Álvaro Luis González',          'Álvaro Luis González Brito'),
    ('Dagnier Curra Sosa',            'Dagnier Antonio Curra Sosa'),
    ('Dario Palmero',                 'Darío Palmero Ledón'),
    ('Sofía Albizu Campos',           'Sofía Albizu Campos Rodríguez'),
    ('Aldo Rodríguez',                'Aldo Rodríguez González'),
    ('Ángel Ribalta',                 'Ángel Ribalta Stanford'),
    ('Sergio Torres',                 'Sergio Torres Fernández'),
    ('Hugo de La Cruz Canc',          'Hugo de la Cruz Cancino'),

    -- Apellidos con el orden cambiado por la fuente
    ('Jorge Castro Odio Guido',       'Guido Jorge Castro Odio'),
    ('Moreno Santiago Luis',          'Luis Santiago Moreno'),

    -- Una letra de diferencia; gana la grafía con más respaldo
    ('Jorge Erik López Velázquez',    'Jorge Erick López Velázquez'),
    ('Hermen Ferrás Martel',          'Hermen Ferrás Martell'),
    ('René Guerra Mollet',            'René Guerra Millet'),
    ('José Moraguez Piño',            'José Moraguez Piñol'),

    -- Confirmados: son dos apellidos distintos, no una errata
    ('Ana Margarita López Valdés',    'Ana Margarita Lemus Valdés'),
    ('Andrés Sánchez García',         'Andrés Sánchez Pérez'),

    -- Los hermanos Presa Sagué, que la IMO escribió de cuatro formas
    ('Arturo Presa',                  'Arturo Presa Sagué'),
    ('Sague Arturo Presa',            'Arturo Presa Sagué'),
    ('José Presa',                    'José Presa Sagué'),
    ('J. R. Presa Sague',             'José Presa Sagué')
)
update public.results r
   set contestant = c.nuevo
  from correcciones c
 where r.contestant = c.viejo;

-- ----------------------------------------------------------------------------
--  Ibero 2006: los tres códigos sin identificar.
--  Se sabe quiénes son los tres, pero no qué código corresponde a cada uno.
--  Se actualiza la nota con los nombres completos ya unificados.
-- ----------------------------------------------------------------------------

update public.results
   set notes = 'Uno de: Álvaro Javier Fuentes Suárez, Douglas Curbelo Aguilera '
               || 'o Jorge Patricio Castillo López. Se sabe que son ellos tres, '
               || 'pero no qué código corresponde a cada uno.'
 where competition = 'ibero'
   and year = 2006
   and contestant in ('CUB 01', 'CUB 02', 'CUB 04');

alter table public.results enable trigger results_audit;

-- ----------------------------------------------------------------------------
--  Comprobación: debe dar 0 variantes y 3 notas actualizadas.
-- ----------------------------------------------------------------------------

select (select count(*) from public.results
         where contestant in (
           'Manuel A. Candales Rodríguez', 'Manuel Candales Rodríguez',
           'Otto A. León Negrín', 'Otto León Negrín', 'Adrián Batista Planas',
           'Jorge E Moreira Broche', 'Jorge Patricio Castillo',
           'Álvaro Luis González', 'Dagnier Curra Sosa', 'Dario Palmero',
           'Sofía Albizu Campos', 'Aldo Rodríguez', 'Ángel Ribalta',
           'Sergio Torres', 'Hugo de La Cruz Canc',
           'Jorge Castro Odio Guido', 'Moreno Santiago Luis',
           'Jorge Erik López Velázquez', 'Hermen Ferrás Martel',
           'René Guerra Mollet', 'José Moraguez Piño',
           'Ana Margarita López Valdés', 'Andrés Sánchez García',
           'Arturo Presa', 'Sague Arturo Presa',
           'José Presa', 'J. R. Presa Sague'))            as quedan_variantes,
       (select count(*) from public.results
         where competition = 'ibero' and year = 2006
           and notes like 'Uno de: Álvaro%')              as notas_2006;
