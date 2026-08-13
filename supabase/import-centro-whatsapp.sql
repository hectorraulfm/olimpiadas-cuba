-- ============================================================================
--  Centroamericana: resultados cubanos de 1999 a 2009 y 2013
--  Fuente: mensajes de WhatsApp recibidos el 12 y 13 de agosto de 2026.
-- ----------------------------------------------------------------------------
--  Trae 34 concursantes en 12 años, con su medalla, y el país sede de las 8
--  ediciones en que se mencionaba.
--
--  La fuente no da puntuación por problema, así que esas columnas quedan
--  vacías. Tampoco da líderes ni colíderes.
--
--  REGLA: solo escribe en filas que estén completamente vacías, así que nunca
--  pisa nada introducido desde la web.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Requiere haber ejecutado antes migracion-centroamericana.sql.
--  Es idempotente.
-- ============================================================================

alter table public.editions disable trigger editions_audit;
alter table public.results  disable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 1. Sedes mencionadas
-- ----------------------------------------------------------------------------

with sedes(anyo, pais) as (
  values
    (1999, 'Costa Rica'),
    (2000, 'El Salvador'),
    (2003, 'Costa Rica'),
    (2005, 'El Salvador'),
    (2006, 'Panamá'),
    (2007, 'Venezuela'),
    (2008, 'Honduras'),
    (2013, 'Nicaragua')
)
update public.editions e
   set host_country = s.pais
  from sedes s
 where e.competition = 'centro'
   and e.year = s.anyo
   and e.host_country = '';   -- respeta lo que ya hubiera

-- 2001, 2002, 2004 y 2009 no aparecen: la fuente no dice dónde se celebraron.

-- ----------------------------------------------------------------------------
-- 2. Concursantes
--    Dentro de cada año van ordenados por metal: oro, plata, bronce, mención.
-- ----------------------------------------------------------------------------

with datos(anyo, orden, nombre, premio) as (
  values
    (1999, 1, 'Jorge Erick López Velázquez',        'Oro'),
    (1999, 2, 'Reydel Pérez Pasto',                 'Bronce'),
    (1999, 3, 'Tania Moreno García',                'Bronce'),
    (2000, 1, 'Yusniel Borrego',                    'Oro'),
    (2000, 2, 'Franklin Rivero Duarte',             'Oro'),
    (2000, 3, 'Evelin Fonseca Cruz',                'Plata'),
    (2001, 1, 'Dagnier Curra Sosa',                 'Plata'),
    (2001, 2, 'José Rafael Quevedo Rego',           'Plata'),
    (2001, 3, 'Chedly Broche',                      'Mención de Honor'),
    (2002, 1, 'Orlando Osorio Gámez',               'Bronce'),
    (2002, 2, 'Carlos Alberto Iglesias Álvarez',    'Bronce'),
    (2002, 3, 'Héctor Raúl Fernández Morales',      'Mención de Honor'),
    (2003, 1, 'Gerandy Brito Montes de Oca',        'Plata'),
    (2004, 1, 'Jorge Patricio Castillo López',      'Plata'),
    (2004, 2, 'Raúl Ramos Pupo',                    'Plata'),
    (2004, 3, 'Susana Frometa Fernández',           'Bronce'),
    (2005, 1, 'Douglas Curbelo Aguilera',           'Plata'),
    (2005, 2, 'José Miguel Rodríguez García',       'Bronce'),
    (2005, 3, 'Óscar Merino Machado',               'Bronce'),
    (2006, 1, 'Manuel Alejandro Candales Rodríguez', 'Oro'),
    (2006, 2, 'Otto Alberto León Negrín',           'Oro'),
    (2006, 3, 'Ana Margarita López Valdés',         'Plata'),
    (2007, 1, 'Antonio Ismael García Rodríguez',    'Oro'),
    (2007, 2, 'Daniel Otero Baguer',                'Plata'),
    (2007, 3, 'José Gabriel Pérez Clark',           'Plata'),
    (2008, 1, 'Reynaldo Gil Pons',                  'Oro'),
    (2008, 2, 'Jorge Estrada Hernández',            'Plata'),
    (2008, 3, 'Miguel Oscar Almarales Milán',       'Mención de Honor'),
    (2009, 1, 'Rody Lorenzo Cardoza',               'Oro'),
    (2009, 2, 'Adrián Luis Batista Planas',         'Plata'),
    (2009, 3, 'Eduardo Pascual Aseff',              'Bronce'),
    (2013, 1, 'Daniel Alberto García Pérez',        'Plata'),
    (2013, 2, 'David Castillo López',               'Plata'),
    (2013, 3, 'Humberto Riveron Valdés',            'Mención de Honor')
)
update public.results r
   set contestant = d.nombre,
       award      = d.premio
  from datos d
 where r.competition = 'centro'
   and r.year = d.anyo
   and r.sort_order = d.orden
   and r.contestant = ''      -- solo filas vacías
   and r.award is null
   and r.total is null;

alter table public.editions enable trigger editions_audit;
alter table public.results  enable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 3. Comprobación
--    Esperado: 34 concursantes, 8 oro, 14 plata, 8 bronce, 4 mención,
--              8 ediciones con país.
-- ----------------------------------------------------------------------------

select count(*) filter (where contestant <> '')                  as concursantes,
       count(*) filter (where award = 'Oro')                     as oro,
       count(*) filter (where award = 'Plata')                   as plata,
       count(*) filter (where award = 'Bronce')                  as bronce,
       count(*) filter (where award = 'Mención de Honor')        as mencion,
       (select count(*) from public.editions
         where competition = 'centro' and host_country <> '')    as sedes
  from public.results
 where competition = 'centro';
