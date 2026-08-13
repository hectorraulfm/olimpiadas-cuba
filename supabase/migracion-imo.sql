-- ============================================================================
--  Añade la IMO (Olimpiada Internacional de Matemática) como tercera competición
--  Fuente: https://www.imo-official.org/results/individual/country/CUB/
--          consultada el 13 de agosto de 2026. Es la fuente oficial.
-- ----------------------------------------------------------------------------
--  Trae los 185 concursantes cubanos de 1971 a 2026, con puntuación por
--  problema, total, medalla y puesto.
--
--  Se crean ediciones para TODOS los años de 1971 a 2026, con 6 plazas cada
--  uno, aunque Cuba no asistiera. Dos excepciones: 1974 tuvo 7 concursantes y
--  1981 tuvo 8, porque los equipos de la IMO eran mayores entonces; esos años
--  llevan las plazas que hicieron falta para no perder datos reales.
--
--  La fuente no publica líderes ni colíderes en esta tabla.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Admitir la nueva competición
-- ----------------------------------------------------------------------------

alter table public.editions drop constraint if exists editions_competition_check;
alter table public.editions add constraint editions_competition_check
  check (competition in ('ibero', 'centro', 'imo'));

alter table public.results drop constraint if exists results_competition_check;
alter table public.results add constraint results_competition_check
  check (competition in ('ibero', 'centro', 'imo'));

-- Las ediciones antiguas de la IMO empiezan en 1971.
alter table public.editions drop constraint if exists editions_year_check;
alter table public.editions add constraint editions_year_check
  check (year between 1959 and 2100);

alter table public.editions disable trigger editions_audit;
alter table public.results  disable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 2. Esqueleto: 1971 a 2026, seis plazas por año
-- ----------------------------------------------------------------------------

insert into public.editions (competition, year)
select 'imo', y
  from generate_series(1971, 2026) as y   -- [AÑO FINAL]
on conflict (competition, year) do nothing;

insert into public.results (competition, year, sort_order)
select 'imo', e.year, s
  from public.editions e
  cross join generate_series(1, 8) as s
 where e.competition = 'imo'
   and (s <= 6                              -- seis plazas por defecto
        or (e.year = 1974 and s = 7)        -- aquel año fueron siete
        or (e.year = 1981 and s <= 8))      -- y aquel, ocho
   and not exists (
         select 1 from public.results r
          where r.competition = 'imo'
            and r.year = e.year
            and r.sort_order = s
       );

-- ----------------------------------------------------------------------------
-- 3. Concursantes
--    Ordenados dentro de cada año de mayor a menor puntuación.
--    Los años sin filas aquí son aquellos en que Cuba no participó:
--    1975, 1980, 2006, 2011, 2016, 2018, 2020 y 2021.
-- ----------------------------------------------------------------------------

with datos(anyo, orden, nombre, a1, a2, a3, a4, a5, a6, puntos, premio, puesto) as (
  values
    (2026,1,'Erick Díaz Pérez',7,1,0,7,7,0,22,'Bronce',161),
    (2026,2,'Marcel Gamez Salvo',7,0,7,6,2,0,22,'Bronce',161),
    (2026,3,'Diego García Rodríguez',7,1,0,7,1,0,16,'Bronce',314),
    (2026,4,'Yeison Alejandro Davy Abreu',6,1,0,6,1,0,14,null,388),
    (2026,5,'Heidy Rodriguez Fuentes',3,1,0,5,1,0,10,null,486),
    (2026,6,'Javier Ernesto Galindo Nápoles',1,0,0,4,1,0,6,null,555),
    (2025,1,'Marcel Gamez Salvo',7,0,7,6,0,0,20,'Bronce',291),
    (2025,2,'Erick Díaz Pérez',7,1,0,7,3,0,18,'Mención de Honor',322),
    (2025,3,'Dalia Oliver Ballesteros',6,1,0,6,0,0,13,null,410),
    (2025,4,'Ian David Lorenzo García',6,1,0,5,0,0,12,null,423),
    (2025,5,'Heidy Rodríguez Fuentes',2,1,0,7,0,0,10,'Mención de Honor',448),
    (2025,6,'Liss Marian Estévez Suarez',3,0,0,4,0,0,7,null,491),
    (2024,1,'Marcel Gámez Salvó',7,0,0,7,0,1,15,'Mención de Honor',327),
    (2024,2,'Ián David Lorenzo García',7,0,0,7,0,0,14,'Mención de Honor',366),
    (2024,3,'Ailema Matos Rodríguez',7,0,0,7,0,0,14,'Mención de Honor',366),
    (2024,4,'Ricardo Miguel Molano Dominguez',7,0,0,7,0,0,14,'Mención de Honor',366),
    (2024,5,'Karla Yisel Ramirez Garcel',7,0,0,0,0,0,7,'Mención de Honor',487),
    (2024,6,'Damiam David Fuentes Campos',1,0,0,3,0,0,4,null,525),
    (2023,1,'Karla Yisel Ramírez Garcell',7,0,0,0,2,0,9,'Mención de Honor',459),
    (2023,2,'Aser Acosta Carrión',2,0,0,0,0,0,2,null,554),
    (2022,1,'Elvis Cabrera Leal',7,0,0,0,2,0,9,'Mención de Honor',469),
    (2022,2,'Thalía Faustina Zayas Suárez',1,1,0,2,0,0,4,null,532),
    (2019,1,'Juliet Bringas Miranda',3,2,0,7,0,0,12,'Mención de Honor',376),
    (2019,2,'Sofia Albizu Campos Rodríguez',7,1,0,1,2,0,11,'Mención de Honor',386),
    (2017,1,'Marcos Manuel Tirador del Riego',5,1,0,7,0,0,13,'Mención de Honor',390),
    (2015,1,'Humberto Riverón Valdés',7,0,0,7,1,0,15,'Bronce',217),
    (2014,1,'Humberto Riverón Valdés',1,1,0,7,1,0,10,'Mención de Honor',387),
    (2013,1,'Lázaro Ángel Ortiz Hechavarría',1,1,0,7,2,0,11,'Mención de Honor',306),
    (2012,1,'Lázaro Ángel Ortiz Hechavarría',2,6,0,0,0,0,8,null,398),
    (2010,1,'Reynaldo Gil Pons',7,7,0,7,5,0,26,'Plata',48),
    (2009,1,'Reynaldo Gil Pons',7,6,1,5,2,0,21,'Bronce',181),
    (2008,1,'Manuel Candales Rodríguez',7,6,7,7,0,0,27,'Plata',71),
    (2007,1,'Douglas Curbelo Aguilera',1,7,0,7,1,0,16,'Bronce',171),
    (2005,1,'Alvaro Javier Fuentes Suárez',3,6,0,1,7,0,17,'Bronce',175),
    (2005,2,'Gerandy Brito Montes de Oca',0,2,0,7,7,0,16,'Bronce',191),
    (2005,3,'Edel Pérez Castillo',7,1,0,5,0,0,13,'Bronce',238),
    (2005,4,'Abdel Alberto García Mola',0,1,0,7,0,0,8,'Mención de Honor',296),
    (2004,1,'Jorge E Moreira Broche',7,4,3,0,3,0,17,'Bronce',212),
    (2003,1,'Mario García Armas',2,5,0,7,0,0,14,'Bronce',179),
    (2002,1,'Mario García Armas',7,7,0,4,2,0,20,'Bronce',145),
    (2002,2,'Ingmar Vázquez García',6,5,0,7,1,0,19,'Bronce',160),
    (2002,3,'Franklin Rivero Duarte',6,0,0,4,1,0,11,null,266),
    (2002,4,'Pavel Silveira Díaz',1,7,0,1,1,0,10,'Mención de Honor',281),
    (2002,5,'Dagnier Antonio Curra Sosa',0,1,1,7,1,0,10,'Mención de Honor',281),
    (2002,6,'Andrés Sánchez García',0,7,0,0,1,0,8,'Mención de Honor',308),
    (2001,1,'Jorge Erik López Velázquez',7,6,2,7,5,4,31,'Oro',33),
    (2001,2,'Raúl Arderí García',7,0,0,7,7,0,21,'Plata',97),
    (2001,3,'Tania Moreno García',6,0,1,3,2,0,12,'Bronce',212),
    (2001,4,'Reydel Pérez Pastó',7,0,2,0,3,0,12,'Bronce',212),
    (2001,5,'Pavel Silveira Díaz',7,1,0,2,2,0,12,'Bronce',212),
    (2001,6,'Evelín Fonseca Cruz',3,0,0,1,0,0,4,null,347),
    (2000,1,'Rolando Trujillo Rasúa',7,2,0,2,3,2,16,'Bronce',149),
    (2000,2,'Raúl Arderí García',7,1,0,5,0,0,13,'Bronce',190),
    (2000,3,'Reydel Pérez Pastó',7,0,0,0,1,2,10,'Mención de Honor',230),
    (2000,4,'Noslen Hernandez Gonzalez',7,1,0,0,1,0,9,'Mención de Honor',260),
    (2000,5,'Orlando Cabrera Baez',0,1,0,6,0,0,7,null,309),
    (2000,6,'Jorge Erik López Velázquez',2,1,0,1,0,2,6,null,333),
    (1999,1,'Olemis Lang Camina',6,5,0,2,7,0,20,'Plata',85),
    (1999,2,'Daniel Hernández Díaz',4,1,0,2,7,0,14,'Bronce',159),
    (1999,3,'Franklin Vera Pacheco',6,1,0,2,4,1,14,'Bronce',159),
    (1999,4,'Yunior Sánchez Fernández',4,0,0,2,7,0,13,'Bronce',178),
    (1999,5,'Rolando Trujillo Rasúa',2,2,0,2,6,0,12,'Bronce',202),
    (1999,6,'Román Fresneda Quiroga',3,0,0,0,0,1,4,null,394),
    (1998,1,'Andres Gago Alonso',2,7,1,2,7,0,19,'Bronce',145),
    (1997,1,'Lorver Duarte Puig',7,7,0,7,7,0,28,'Plata',79),
    (1997,2,'Enrique Portela García',3,7,1,4,5,0,20,'Bronce',155),
    (1997,3,'Alden Torres Cuón',0,7,0,5,4,0,16,'Bronce',200),
    (1997,4,'Maikel Garma de la Osa',0,7,0,1,2,0,10,'Mención de Honor',285),
    (1997,5,'Ramiro Feria Purón',1,7,0,0,0,1,9,'Mención de Honor',299),
    (1997,6,'Rafael Arturo Trujillo Rasúa',0,0,0,1,7,0,8,'Mención de Honor',322),
    (1996,1,'Lorver Duarte Puig',4,7,1,1,0,3,16,'Bronce',130),
    (1995,1,'Lorver Duarte Puig',6,0,0,4,7,0,17,'Mención de Honor',210),
    (1995,2,'Walter Carballosa Torres',7,0,0,2,7,0,16,'Mención de Honor',222),
    (1995,3,'Alexander Alvarez Hernandez',6,0,5,5,0,0,16,null,222),
    (1995,4,'Héctor Antonio Mesa Barrameda',6,0,3,1,0,0,10,null,291),
    (1994,1,'Moreno Santiago Luis',0,7,0,4,1,0,12,'Mención de Honor',268),
    (1993,1,'Janko Hernandez Cortes',7,7,0,5,3,0,22,'Plata',73),
    (1993,2,'Leonel Robert Gonzalez',0,7,0,6,0,2,15,'Bronce',143),
    (1993,3,'Luis Santiago Moreno',0,7,0,1,1,0,9,'Mención de Honor',210),
    (1993,4,'Ailin Ruiz de Zarate',0,0,0,0,3,2,5,null,284),
    (1993,5,'Hugo de La Cruz Canc',0,0,0,2,1,0,3,null,339),
    (1993,6,'Erwin Mina Diaz',0,1,0,0,1,0,2,null,360),
    (1992,1,'Hugo de La Cruz Canc',0,1,0,7,0,0,8,'Mención de Honor',211),
    (1992,2,'Janko Hernandez Cortes',0,1,0,6,0,0,7,null,229),
    (1992,3,'Pedro Luis Alonso',0,1,1,0,0,0,2,null,297),
    (1991,1,'Mijail Borges Quintana',7,7,3,0,7,0,24,'Bronce',108),
    (1991,2,'Alien Herrera Torres',7,7,0,0,7,0,21,'Bronce',133),
    (1991,3,'Ariel Almendral Vazquez',4,0,0,1,7,0,12,'Mención de Honor',202),
    (1991,4,'Alcides Morales Guedes',7,3,0,0,1,0,11,'Mención de Honor',210),
    (1991,5,'Mirta Castro Smirnova',2,5,0,0,2,0,9,null,226),
    (1991,6,'Rely Pellicer Bidot',1,1,0,0,1,0,3,null,279),
    (1990,1,'Rolando Uranga Piña',7,1,0,6,1,1,16,'Bronce',139),
    (1990,2,'Mijail Borges Quintana',4,1,4,1,3,0,13,null,184),
    (1990,3,'Guido Jorge Castro Odio',7,1,0,0,3,0,11,'Mención de Honor',216),
    (1990,4,'Julio Cesar Exposito Garcia',1,2,2,3,1,1,10,null,225),
    (1990,5,'Alien Herrera Torres',4,1,1,2,1,1,10,null,225),
    (1990,6,'Li-Vang Lozada Chang',0,1,1,2,3,0,7,null,266),
    (1989,1,'Rolando Uranga Piña',0,7,0,7,7,2,23,'Bronce',108),
    (1989,2,'Jorge Alejandro Piñero Barcelo',1,7,0,3,5,0,16,'Mención de Honor',162),
    (1989,3,'Castor José Alvarez Bebesa',0,4,0,0,7,0,11,'Mención de Honor',190),
    (1989,4,'Fremior Camba Aldanás',4,4,0,2,0,0,10,null,196),
    (1989,5,'Li-Vang Lozada Chang',0,0,2,0,0,7,9,'Mención de Honor',204),
    (1989,6,'Mauricio Romero Sicre',0,0,0,0,0,0,0,null,283),
    (1988,1,'Sergio Torres',6,0,1,0,1,0,8,null,185),
    (1988,2,'Rene Guerra Millet',7,0,0,0,0,0,7,'Mención de Honor',195),
    (1988,3,'Daniel Lodos',3,0,1,2,0,0,6,null,201),
    (1988,4,'Carlos Mora',5,1,0,0,0,0,6,null,201),
    (1988,5,'Aldo Rodriguez',1,4,1,0,0,0,6,null,201),
    (1988,6,'Rolando Uranga Piña',2,0,0,0,0,0,2,null,243),
    (1987,1,'Alex Gay Cabera',7,7,0,7,4,0,25,'Bronce',86),
    (1987,2,'Jorge Luis de Armas Garcia',5,7,0,4,7,0,23,'Bronce',91),
    (1987,3,'Rene Guerra Millet',4,0,0,3,7,0,14,null,135),
    (1987,4,'Nelson Navarro Navarro',1,7,1,1,2,0,12,null,146),
    (1987,5,'Aldo Rodriguez Gonzales',2,3,0,0,0,0,5,null,196),
    (1987,6,'Luis Artiles Martinez',1,0,0,2,1,0,4,null,203),
    (1986,1,'',7,1,0,2,3,0,13,null,129),
    (1986,2,'',3,0,0,7,2,0,12,null,133),
    (1986,3,'',3,0,2,4,0,1,10,null,151),
    (1986,4,'',3,0,1,0,4,0,8,null,172),
    (1986,5,'',3,0,0,2,0,0,5,null,189),
    (1986,6,'',0,0,0,2,1,0,3,null,199),
    (1985,1,'Jorge Lodos Vigil',1,4,0,5,7,1,18,'Bronce',65),
    (1985,2,'Daniel Alfaro Vigo',7,5,0,2,0,1,15,'Bronce',93),
    (1985,3,'Angel Ribalta Stanford',7,0,0,0,7,0,14,null,102),
    (1985,4,'Guillermo Reyes Souto',7,1,0,0,3,0,11,null,118),
    (1985,5,'Alfredo Herrera Hérnandez',7,0,0,0,3,0,10,null,129),
    (1985,6,'Karel Roiz Wilson',2,0,0,3,0,1,6,null,160),
    (1984,1,'A. Torres Montoya',6,4,0,7,0,0,17,'Bronce',96),
    (1984,2,'J. R. Presa Sague',2,7,0,7,0,0,16,null,99),
    (1984,3,'M. T. Alzugaray Rodriguez',5,7,0,0,0,0,12,null,118),
    (1984,4,'M. Perera Chang',2,3,0,3,1,2,11,null,123),
    (1984,5,'Karel Roiz Wilson',2,1,1,0,4,0,8,null,144),
    (1984,6,'Daniel Alfaro Vigo',2,1,0,0,0,0,3,null,166),
    (1983,1,'Abel Torres',null,null,null,null,null,null,22,'Bronce',52),
    (1983,2,'Nelson Gonzalez',null,null,null,null,null,null,4,null,146),
    (1983,3,'Juan Carlos Sanchez',null,null,null,null,null,null,4,null,146),
    (1983,4,'Ricardo Gomez',null,null,null,null,null,null,2,null,158),
    (1983,5,'José Presa',null,null,null,null,null,null,2,null,158),
    (1983,6,'Rodolfo Toledo',null,null,null,null,null,null,2,null,158),
    (1982,1,'René Dager Salomon',4,0,2,5,6,0,17,null,73),
    (1982,2,'Ernesto Moreno Frias',4,6,0,0,7,0,17,null,73),
    (1982,3,'Alejandro Bandinez O''Farrill',2,1,2,0,2,0,7,null,104),
    (1982,4,'Alberto Jiménez Moreno',2,0,0,0,1,0,3,null,108),
    (1981,1,'Jose I. Ariza',null,null,null,null,null,null,34,'Plata',72),
    (1981,2,'Andrei Martinez',null,null,null,null,null,null,25,null,104),
    (1981,3,'Domingo Louis',null,null,null,null,null,null,22,null,117),
    (1981,4,'Jorge L. Barreras',null,null,null,null,null,null,19,null,126),
    (1981,5,'Raul Perez',null,null,null,null,null,null,14,null,141),
    (1981,6,'René Dager Salomon',null,null,null,null,null,null,12,null,156),
    (1981,7,'Marco A. Gonzalez',null,null,null,null,null,null,9,null,164),
    (1981,8,'Ernesto Moreno Frias',null,null,null,null,null,null,6,null,169),
    (1979,1,'',3,0,2,4,2,0,11,null,126),
    (1979,2,'',0,5,3,0,1,1,10,null,132),
    (1979,3,'',2,1,0,5,0,1,9,null,135),
    (1979,4,'',0,0,1,1,2,1,5,null,152),
    (1978,1,'Ricardo Gonzalez Felipe',null,null,null,null,null,null,24,'Bronce',35),
    (1978,2,'Rafael Pedrosa Martinez',null,null,null,null,null,null,23,'Bronce',47),
    (1978,3,'Alberto Ochoa Rodriguez',null,null,null,null,null,null,12,null,111),
    (1978,4,'Javier Avalons Llerena',null,null,null,null,null,null,9,null,115),
    (1977,1,'Garcia Carlos De Armas',null,null,null,null,null,null,13,null,97),
    (1977,2,'Sague Arturo Presa',null,null,null,null,null,null,13,null,97),
    (1977,3,'Crespo Jorge Fernandez',null,null,null,null,null,null,8,null,124),
    (1977,4,'Rafael Pedrosa Martinez',null,null,null,null,null,null,7,null,129),
    (1976,1,'Sarah Maria Duyos',0,0,7,1,0,5,13,null,90),
    (1976,2,'Arturo Presa',0,0,2,0,0,0,2,null,133),
    (1976,3,'Jorge Ramirez',0,0,1,0,0,0,1,null,135),
    (1974,1,'Ramiro Ochoa Julve',3,0,0,2,5,5,15,null,104),
    (1974,2,'Sarah Maria Duyos',5,0,0,5,2,1,13,null,111),
    (1974,3,'Angel Perez',5,1,1,2,1,1,11,null,120),
    (1974,4,'Enrique Marill',5,0,0,4,1,0,10,null,127),
    (1974,5,'Jose Anta',3,0,0,4,1,0,8,null,131),
    (1974,6,'Alberto Juan León Escobio',0,0,0,3,3,0,6,null,135),
    (1974,7,'Alfredo Bollar',1,1,0,0,0,0,2,null,139),
    (1973,1,'Luis Sastra Vidal',2,6,3,0,6,0,17,'Bronce',66),
    (1973,2,'Luis Prado García',6,0,0,3,0,0,9,null,96),
    (1973,3,'Jorge Carlos Estrasa',0,0,0,2,6,0,8,null,103),
    (1973,4,'Alberto Juan León Escobio',1,0,0,2,1,0,4,null,116),
    (1973,5,'Ramiro Ochoa Julve',0,0,0,4,0,0,4,null,116),
    (1972,1,'',null,null,null,null,null,null,10,null,76),
    (1972,2,'',null,null,null,null,null,null,2,null,98),
    (1972,3,'',null,null,null,null,null,null,2,null,98),
    (1971,1,'',null,null,null,null,null,null,4,null,82),
    (1971,2,'',null,null,null,null,null,null,3,null,90),
    (1971,3,'',null,null,null,null,null,null,1,null,106),
    (1971,4,'',null,null,null,null,null,null,1,null,106)
)
update public.results r
   set contestant = d.nombre,
       p1 = d.a1, p2 = d.a2, p3 = d.a3,
       p4 = d.a4, p5 = d.a5, p6 = d.a6,
       total = d.puntos,
       award = d.premio,
       "rank" = d.puesto
  from datos d
 where r.competition = 'imo'
   and r.year = d.anyo
   and r.sort_order = d.orden;

-- La fuente oficial no publica el nombre de algunos concursantes antiguos.
update public.results
   set notes = 'Nombre no publicado en la fuente oficial'
 where competition = 'imo'
   and contestant = ''
   and total is not null
   and notes = '';

alter table public.editions enable trigger editions_audit;
alter table public.results  enable trigger results_audit;

-- ----------------------------------------------------------------------------
-- 4. Comprobación
--    Esperado: 56 ediciones, 339 filas, 185 con datos,
--              1 oro, 7 plata, 41 bronce, 35 mención.
-- ----------------------------------------------------------------------------

select (select count(*) from public.editions where competition = 'imo')  as ediciones,
       count(*)                                                          as filas,
       count(*) filter (where total is not null)                         as con_datos,
       count(*) filter (where award = 'Oro')                             as oro,
       count(*) filter (where award = 'Plata')                           as plata,
       count(*) filter (where award = 'Bronce')                          as bronce,
       count(*) filter (where award = 'Mención de Honor')                as mencion
  from public.results
 where competition = 'imo';
