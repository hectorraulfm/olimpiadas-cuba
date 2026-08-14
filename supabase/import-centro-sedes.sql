-- ============================================================================
--  Centroamericana: país y ciudad de las 27 ediciones, de 1999 a 2025
--  Fuente: listado aportado el 13 de agosto de 2026.
-- ----------------------------------------------------------------------------
--  Los once países que ya estaban puestos coinciden todos con este listado,
--  así que se confirman entre sí. Este script rellena los catorce que faltaban
--  y las ciudades de casi todas las ediciones.
--
--  Las ediciones virtuales se anotan como "(virtual)", con el mismo estilo que
--  usan la Iberoamericana y la IMO.
--
--  REGLA: solo escribe donde el campo esté vacío. En particular NO toca la
--  ciudad de 2023, que ya figura como "La Herradura, La Paz" según el acta
--  oficial de aquella edición.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.editions disable trigger editions_audit;

with sedes(anyo, pais, ciudad) as (
  values
    (1999, 'Costa Rica',           'San José'),
    (2000, 'El Salvador',          'San Salvador'),
    (2001, 'Colombia',             'Buga, Valle del Cauca'),
    (2002, 'México',               'Mérida, Yucatán'),
    (2003, 'Costa Rica',           'San José'),
    (2004, 'Nicaragua',            'Managua'),
    (2005, 'El Salvador',          'San Salvador'),
    (2006, 'Panamá',               'Ciudad de Panamá'),
    (2007, 'Venezuela',            'San Cristóbal'),
    (2008, 'Honduras',             'San Pedro Sula'),
    (2009, 'Colombia',             'Valledupar'),
    (2010, 'Puerto Rico',          'Mayagüez'),
    (2011, 'México',               'Colima'),
    (2012, 'El Salvador',          'San Salvador'),
    (2013, 'Nicaragua',            'Managua'),
    (2014, 'Costa Rica',           'San José'),
    (2015, 'México',               'Cuernavaca, Morelos'),
    (2016, 'Jamaica',              'Kingston'),
    (2017, 'El Salvador',          'San Salvador'),
    (2018, 'Cuba',                 'La Habana'),
    (2019, 'República Dominicana', 'Santo Domingo'),
    (2020, 'Panamá',               '(virtual)'),
    (2021, 'Colombia',             '(virtual)'),
    (2022, 'Costa Rica',           '(virtual)'),
    (2023, 'El Salvador',          'San Salvador'),
    (2024, 'Honduras',             'Tegucigalpa'),
    (2025, 'Costa Rica',           'Cartago')
)
update public.editions e
   set host_country = case when e.host_country = '' then s.pais   else e.host_country end,
       host_city    = case when e.host_city    = '' then s.ciudad else e.host_city    end
  from sedes s
 where e.competition = 'centro'
   and e.year = s.anyo;

alter table public.editions enable trigger editions_audit;

-- ----------------------------------------------------------------------------
--  Comprobación. Esperado: 28 ediciones, 28 con país y 28 con ciudad
--  (las 27 del listado más la de 2026, que ya tenías puesta).
-- ----------------------------------------------------------------------------

select count(*)                                   as ediciones,
       count(*) filter (where host_country <> '') as con_pais,
       count(*) filter (where host_city    <> '') as con_ciudad
  from public.editions
 where competition = 'centro';
