-- ============================================================================
--  Importación de resultados de Cuba
--  Fuente: https://iberoofficial.vercel.app  (consultada el 6 de agosto de 2026)
-- ----------------------------------------------------------------------------
--  Trae:
--    · Sede (país y ciudad) de las 38 ediciones que la fuente documenta,
--      de 1987 a 2024.
--    · 53 concursantes cubanos repartidos en 16 años.
--
--  NO trae líderes ni colíderes: esa fuente no los publica.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente: se puede ejecutar varias veces sin duplicar nada.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Ampliar la escala de puntuación
--    Las ediciones de 1987 y 1993 puntuaban cada problema sobre 10, no sobre 7
--    (el máximo eran 60 puntos, no 42). Sin esto, esas filas serían rechazadas.
-- ----------------------------------------------------------------------------

alter table public.results drop constraint if exists results_p1_check;
alter table public.results drop constraint if exists results_p2_check;
alter table public.results drop constraint if exists results_p3_check;
alter table public.results drop constraint if exists results_p4_check;
alter table public.results drop constraint if exists results_p5_check;
alter table public.results drop constraint if exists results_p6_check;
alter table public.results drop constraint if exists results_total_check;

alter table public.results add constraint results_p1_check check (p1 between 0 and 10);
alter table public.results add constraint results_p2_check check (p2 between 0 and 10);
alter table public.results add constraint results_p3_check check (p3 between 0 and 10);
alter table public.results add constraint results_p4_check check (p4 between 0 and 10);
alter table public.results add constraint results_p5_check check (p5 between 0 and 10);
alter table public.results add constraint results_p6_check check (p6 between 0 and 10);
alter table public.results add constraint results_total_check check (total between 0 and 60);

-- Silencia el historial durante la importación, para no llenarlo de apuntes
-- automáticos sin autor.
alter table public.editions disable trigger editions_audit;
alter table public.results  disable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 1. Sedes de cada edición
-- ----------------------------------------------------------------------------

with sedes(anyo, ciudad, pais) as (
  values
    (2024, 'Tarija',                'Bolivia'),
    (2023, 'Río de Janeiro',        'Brasil'),
    (2022, 'Bogotá',                'Colombia'),
    (2021, '(virtual)',             'Costa Rica'),
    (2020, '(virtual)',             'Perú'),
    (2019, 'Guanajuato',            'México'),
    (2018, 'La Rábida-Monte Gordo', 'España-Portugal'),
    (2017, 'Iguazú',                'Argentina'),
    (2016, 'Antofagasta',           'Chile'),
    (2015, 'Mayagüez',              'Puerto Rico'),
    (2014, 'San Pedro Sula',        'Honduras'),
    (2013, 'Ciudad de Panamá',      'Panamá'),
    (2012, 'Cochabamba',            'Bolivia'),
    (2011, 'San José',              'Costa Rica'),
    (2010, 'Asunción',              'Paraguay'),
    (2009, 'Querétaro',             'México'),
    (2006, 'Guayaquil',             'Ecuador'),
    (2005, 'Cartagena de Indias',   'Colombia'),
    (2004, 'Castellón',             'España'),
    (2003, 'Mar del Plata',         'Argentina'),
    (2002, 'San Salvador',          'El Salvador'),
    (2001, 'Minas',                 'Uruguay'),
    (2000, 'Caracas',               'Venezuela'),
    (1999, 'La Habana',             'Cuba'),
    (1998, 'Puerto Plata',          'República Dominicana'),
    (1997, 'Guadalajara',           'México'),
    (1996, 'San José',              'Costa Rica'),
    (1995, '',                      'Chile'),
    (1994, 'Fortaleza',             'Brasil'),
    (1993, 'Ciudad de México',      'México'),
    (1992, 'Caracas',               'Venezuela'),
    (1991, 'Carlos Paz',            'Argentina'),
    (1990, 'Valladolid',            'España'),
    (1989, 'La Habana',             'Cuba'),
    (1988, 'Lima',                  'Perú'),
    (1987, 'Salto y Paysandú',      'Uruguay')
)
update public.editions e
   set host_city    = s.ciudad,
       host_country = s.pais
  from sedes s
 where e.year = s.anyo;

-- 2007 y 2008 no aparecen arriba porque la fuente no documenta su sede.

-- ----------------------------------------------------------------------------
-- 2. Concursantes cubanos
--    Dentro de cada año van ordenados de mayor a menor puntuación.
--    "puesto" es el ranking individual de la fuente (columna rank, aún no
--    visible en la web).
-- ----------------------------------------------------------------------------

with datos(anyo, orden, nombre, a1, a2, a3, a4, a5, a6, puntos, premio, puesto, nota) as (
  values
    (2024, 1, 'Karla Yisel Ramirez Garcel', 7,0,0,7,1,0, 15, 'Bronce', 32, ''),
    (2024, 2, 'Ian David Lorenzo García', 1,3,0,7,1,0, 12, 'Bronce', 41, ''),
    (2024, 3, 'Ricardo Miguel Molano Domínguez', 3,0,0,7,1,0, 11, 'Mención de Honor', 45, ''),
    (2024, 4, 'Ailema Matos Rodríguez', 1,0,0,7,1,0, 9, 'Mención de Honor', 50, ''),
    (2023, 1, 'Karla Yisell Ramírez Garcell', 0,7,0,7,7,0, 21, 'Bronce', 24, ''),
    (2023, 2, 'Ricardo Miguel Molano Dominguez', 7,1,0,6,2,0, 16, 'Bronce', 34, ''),
    (2022, 1, 'Guillermo Daniel González Cabrera', 7,1,0,3,1,0, 12, 'Mención de Honor', 43, ''),
    (2022, 2, 'Carlos Manuel Alfonso Basabe', 7,0,0,3,1,0, 11, 'Mención de Honor', 46, ''),
    (2021, 1, 'Jabel Reséndiz Aguirre', 7,7,0,4,1,0, 19, 'Bronce', 27, ''),
    (2021, 2, 'Hermen Ferrás Martell', 7,7,0,4,0,0, 18, 'Bronce', 31, ''),
    (2021, 3, 'Aser Acosta Carrión', 0,1,0,3,5,0, 9, 'Participación', 66, ''),
    (2021, 4, 'Guillermo Daniel González Cabrera', 0,0,0,7,0,0, 7, 'Mención de Honor', 73, ''),
    (2020, 1, 'Hermen Ferrás Martell', 7,7,0,7,7,0, 28, 'Bronce', 30, ''),
    (2020, 2, 'Darío Palmero Ledón', 7,7,0,7,4,0, 25, 'Bronce', 34, ''),
    (2020, 3, 'Álvaro Luis González Brito', 6,2,0,6,5,0, 19, 'Participación', 45, ''),
    (2020, 4, 'Francisco Ernesto Préstamo Bernárdez', 6,3,0,0,3,0, 12, 'Participación', 63, ''),
    (2019, 1, 'Alvaro Luis Gonzalez', 6,6,0,7,1,0, 20, 'Bronce', 28, ''),
    (2019, 2, 'Alex Sierra', 6,0,1,7,2,0, 16, 'Bronce', 40, ''),
    (2019, 3, 'Dario Palmero', 4,3,1,7,0,0, 15, 'Bronce', 44, ''),
    (2019, 4, 'Cristhian Sanchez', 7,1,0,7,0,0, 15, 'Bronce', 44, ''),
    (2018, 1, 'Sofía Albizu Campos Rodríguez', 6,7,0,7,7,1, 28, 'Bronce', 27, ''),
    (2018, 2, 'Marcos Manuel Tirador del Riesgo', 7,7,0,7,6,1, 28, 'Bronce', 27, ''),
    (2018, 3, 'José Julián Díaz Pérez', 7,7,0,7,6,1, 28, 'Bronce', 27, ''),
    (2018, 4, 'Juliet Bringas Miranda', 7,7,0,7,5,0, 26, 'Bronce', 44, ''),
    (2017, 1, 'Cabrera Carmen Irene', 1,3,0,7,0,0, 11, 'Mención de Honor', 55, ''),
    (2016, 1, 'Carlos David Corrales Aguilar', 7,6,0,5,0,1, 19, 'Bronce', 34, ''),
    (2016, 2, 'Joel David Gago García', 7,7,1,1,3,0, 19, 'Bronce', 34, ''),
    (2016, 3, 'Ángel Chibás Díaz', 7,7,1,1,0,0, 16, 'Mención de Honor', 47, ''),
    (2016, 4, '', 3,0,1,0,1,0, 5, 'Participación', 70, 'Nombre no recogido en la fuente'),
    (2015, 1, 'Marcos Adrián Valdivie Rodríguez', 2,7,1,7,2,0, 19, 'Mención de Honor', 47, ''),
    (2015, 2, 'Daniel Alberto García Pérez', 7,0,0,7,1,1, 16, 'Mención de Honor', 57, ''),
    (2010, 1, 'Jorge Estrada Hernández', 7,0,4,6,7,1, 25, 'Plata', 17, ''),
    (2010, 2, 'Jose Moraguez Piño', 0,0,0,7,7,1, 15, 'Bronce', 40, ''),
    (2009, 1, 'Reynaldo Gil Pons', 7,7,7,7,7,3, 38, 'Oro', 3, ''),
    (2009, 2, 'Jorge Estrada Hernández', 6,7,1,7,7,1, 29, 'Bronce', 25, ''),
    (2009, 3, 'José Moraguez Piñol', 7,7,1,7,3,0, 25, 'Bronce', 35, ''),
    (2009, 4, 'Daniel Otero Baguer', 7,7,1,7,1,1, 24, 'Bronce', 37, ''),
    (2004, 1, 'José Enrique Moreira Broche', 7,6,7,7,7,6, 40, 'Oro', 4, ''),
    (2004, 2, 'Gerandy Brito Montes de Oca', 3,6,6,7,7,6, 35, 'Plata', 9, ''),
    (2004, 3, 'Orlando William Osorio Gómez', 5,6,0,7,1,3, 22, 'Bronce', 23, ''),
    (2004, 4, 'Héctor Raúl Fernández Morales', 5,6,0,7,0,4, 22, 'Bronce', 23, ''),
    (2003, 1, 'Mario García Armas', 7,7,7,2,7,7, 37, 'Plata', 7, ''),
    (2003, 2, 'Andrés Sánchez Pérez', 7,7,7,7,7,2, 37, 'Plata', 7, ''),
    (2003, 3, 'Dagnier Curra Sosa', 5,7,1,6,7,0, 26, 'Bronce', 27, ''),
    (2003, 4, 'Juan Miguel Peña Cabrera', 5,7,0,5,7,0, 24, 'Bronce', 30, ''),
    (1993, 1, 'Lewonel Robert González', 9,10,7,10,9,10, 55, 'Oro', 1, ''),
    (1993, 2, 'Janko Hernández Cortés', 10,10,10,10,6,0, 46, 'Plata', 9, ''),
    (1993, 3, 'Hugo de la Cruz Cancino', 10,10,4,10,0,1, 35, 'Bronce', 21, ''),
    (1993, 4, 'Luis Santiago Moreno', 10,0,4,10,4,3, 31, 'Bronce', 27, ''),
    (1987, 1, 'Ángel Ribalta', 9,10,10,10,10,5, 54, 'Plata', 4, ''),
    (1987, 2, 'Isnel Merayo', 10,10,4,10,9,10, 53, 'Plata', 7, ''),
    (1987, 3, 'Alfredo Herrera', 10,10,7,10,10,2, 49, 'Plata', 9, ''),
    (1987, 4, 'Jorge Luis de Armas', 10,2,4,10,10,10, 46, 'Bronce', 11, '')
)
update public.results r
   set contestant = d.nombre,
       p1 = d.a1, p2 = d.a2, p3 = d.a3,
       p4 = d.a4, p5 = d.a5, p6 = d.a6,
       total = d.puntos,
       award = d.premio,
       "rank" = d.puesto,
       notes = d.nota
  from datos d
 where r.year = d.anyo
   and r.sort_order = d.orden;

alter table public.editions enable trigger editions_audit;
alter table public.results  enable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 3. Comprobaciones
-- ----------------------------------------------------------------------------

-- Debe dar: 53 concursantes, 3 oros, 8 platas, 29 bronces, 9 menciones.
select count(*) filter (where contestant <> '' or award is not null) as concursantes,
       count(*) filter (where award = 'Oro')              as oro,
       count(*) filter (where award = 'Plata')            as plata,
       count(*) filter (where award = 'Bronce')           as bronce,
       count(*) filter (where award = 'Mención de Honor') as mencion
  from public.results;

-- Debe dar 0: ninguna suma de problemas debe discrepar del total.
select count(*) as totales_que_no_cuadran
  from public.results
 where total is not null
   and p1 is not null
   and (p1 + p2 + p3 + p4 + p5 + p6) <> total;
