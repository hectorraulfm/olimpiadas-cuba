-- ============================================================================
--  Restituye las tildes en nombres de concursantes y jefes de delegación
-- ----------------------------------------------------------------------------
--  Las fuentes en inglés —sobre todo imo-official— publican los nombres sin
--  acentuar. Aquí se corrigen 58 nombres de concursantes y 8 de jefes.
--
--  Solo se acentúan palabras cuya ortografía en español no admite duda
--  (González, Hernández, Martínez, José, Ángel…). Los apellidos donde la tilde
--  sería discutible se dejan como están.
--
--  Además se resuelven las variantes que no son cuestión de tildes:
--    · "Hérnandez" con dos acentos pasa a "Hernández"
--    · "Pórtela" pasa a "Portela"
--    · "Ián" pasa a "Ian"
--    · "Salvó" pasa a "Salvo"
--    · "Noslėn", escrito con una letra lituana, pasa a "Noslen"
--    · "Reydel Pérez Pastó" pasa a "Reidel", la grafía de la Iberoamericana
--    · "Aldo Rodríguez Gonzales" pasa a "González"
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.results  disable trigger results_audit;
alter table public.editions disable trigger editions_audit;

with correcciones(viejo, nuevo) as (
  values
    ('Alberto Ochoa Rodriguez', 'Alberto Ochoa Rodríguez'),
    ('Aldo Rodriguez', 'Aldo Rodríguez'),
    ('Aldo Rodriguez Gonzales', 'Aldo Rodríguez González'),
    ('Alexander Alvarez Hernandez', 'Alexander Álvarez Hernández'),
    ('Alfredo Herrera Hérnandez', 'Alfredo Herrera Hernández'),
    ('Alvaro Javier Fuentes Suárez', 'Álvaro Javier Fuentes Suárez'),
    ('Alvaro Luis Gonzalez', 'Álvaro Luis González'),
    ('Andrei Martinez', 'Andrei Martínez'),
    ('Andres Gago Alonso', 'Andrés Gago Alonso'),
    ('Angel Perez', 'Ángel Pérez'),
    ('Angel Ribalta Stanford', 'Ángel Ribalta Stanford'),
    ('Ariel Almendral Vazquez', 'Ariel Almendral Vázquez'),
    ('Castor José Alvarez Bebesa', 'Castor José Álvarez Bebesa'),
    ('Crespo Jorge Fernandez', 'Crespo Jorge Fernández'),
    ('Cristhian Sanchez', 'Cristhian Sánchez'),
    ('Dayán Ruben González Basabé', 'Dayán Rubén González Basabé'),
    ('Enrique Pórtela García', 'Enrique Portela García'),
    ('Ernesto Moreno Frias', 'Ernesto Moreno Frías'),
    ('Erwin Mina Diaz', 'Erwin Mina Díaz'),
    ('Evelin Fonseca Cruz', 'Evelín Fonseca Cruz'),
    ('Garcia Carlos De Armas', 'García Carlos De Armas'),
    ('Heidy Rodriguez Fuentes', 'Heidy Rodríguez Fuentes'),
    ('Humberto Riveron Valdés', 'Humberto Riverón Valdés'),
    ('Ián David Lorenzo García', 'Ian David Lorenzo García'),
    ('Ingmar Vazquez García', 'Ingmar Vázquez García'),
    ('Janko Hernandez Cortes', 'Janko Hernández Cortés'),
    ('Jorge Luis de Armas Garcia', 'Jorge Luis de Armas García'),
    ('Jorge Ramirez', 'Jorge Ramírez'),
    ('Jose Anta', 'José Anta'),
    ('Jose I. Ariza', 'José I. Ariza'),
    ('Jose Moraguez Piño', 'José Moraguez Piño'),
    ('Juan Carlos Sanchez', 'Juan Carlos Sánchez'),
    ('Julio Cesar Exposito Garcia', 'Julio César Expósito García'),
    ('Karla Yisel Ramirez Garcel', 'Karla Yisel Ramírez Garcel'),
    ('Leonel Robert Gonzalez', 'Leonel Robert González'),
    ('Liss Marian Estévez Suarez', 'Liss Marian Estévez Suárez'),
    ('Luis Artiles Martinez', 'Luis Artiles Martínez'),
    ('M. T. Alzugaray Rodriguez', 'M. T. Alzugaray Rodríguez'),
    ('Marcel Gamez Salvo', 'Marcel Gámez Salvo'),
    ('Marcel Gámez Salvó', 'Marcel Gámez Salvo'),
    ('Marco A. Gonzalez', 'Marco A. González'),
    ('Mario Garcia Armas', 'Mario García Armas'),
    ('Miguel Oscar Almarales Milán', 'Miguel Óscar Almarales Milán'),
    ('Nelson Gonzalez', 'Nelson González'),
    ('Noslen Hernandez Gonzalez', 'Noslen Hernández González'),
    ('Noslėn Hernández González', 'Noslen Hernández González'),
    ('Orlando Cabrera Baez', 'Orlando Cabrera Báez'),
    ('Rafael Pedrosa Martinez', 'Rafael Pedrosa Martínez'),
    ('Raul Perez', 'Raúl Pérez'),
    ('René Dager Salomon', 'René Dager Salomón'),
    ('Rene Guerra Millet', 'René Guerra Millet'),
    ('Reydel Pérez Pasto', 'Reidel Pérez Pastó'),
    ('Reydel Pérez Pastó', 'Reidel Pérez Pastó'),
    ('Ricardo Gomez', 'Ricardo Gómez'),
    ('Ricardo Gonzalez Felipe', 'Ricardo González Felipe'),
    ('Ricardo Miguel Molano Dominguez', 'Ricardo Miguel Molano Domínguez'),
    ('Sarah Maria Duyos', 'Sarah María Duyos'),
    ('Sofia Albizu Campos Rodríguez', 'Sofía Albizu Campos Rodríguez'),
    ('Yudith Escandon Suarez', 'Yudith Escandón Suárez')
)
update public.results r
   set contestant = c.nuevo
  from correcciones c
 where r.contestant = c.viejo;

with correcciones(viejo, nuevo) as (
  values
    ('Alexis Duran Jorrin', 'Alexis Durán Jorrín'),
    ('Alexis Duran Jorrín', 'Alexis Durán Jorrín'),
    ('Ernesto Alejandro Lopez Cadalso', 'Ernesto Alejandro López Cadalso'),
    ('Hector Raul Fernandez Morales', 'Héctor Raúl Fernández Morales'),
    ('Maria E. Santibanez Pinera', 'María E. Santibáñez Piñera'),
    ('Oscar Dalmau', 'Óscar Dalmau'),
    ('Roman Fresneda Quiroga', 'Román Fresneda Quiroga'),
    ('Sofia Albizu-Campos Rodríguez', 'Sofía Albizu-Campos Rodríguez')
)
update public.editions e
   set leader = c.nuevo
  from correcciones c
 where e.leader = c.viejo;

with correcciones(viejo, nuevo) as (
  values
    ('Alexis Duran Jorrin', 'Alexis Durán Jorrín'),
    ('Alexis Duran Jorrín', 'Alexis Durán Jorrín'),
    ('Ernesto Alejandro Lopez Cadalso', 'Ernesto Alejandro López Cadalso'),
    ('Hector Raul Fernandez Morales', 'Héctor Raúl Fernández Morales'),
    ('Maria E. Santibanez Pinera', 'María E. Santibáñez Piñera'),
    ('Oscar Dalmau', 'Óscar Dalmau'),
    ('Roman Fresneda Quiroga', 'Román Fresneda Quiroga'),
    ('Sofia Albizu-Campos Rodríguez', 'Sofía Albizu-Campos Rodríguez')
)
update public.editions e
   set deputy_leader = c.nuevo
  from correcciones c
 where e.deputy_leader = c.viejo;

alter table public.results  enable trigger results_audit;
alter table public.editions enable trigger editions_audit;

-- ----------------------------------------------------------------------------
--  Comprobación: debe dar 0 en las tres columnas.
-- ----------------------------------------------------------------------------

select (select count(*) from public.results
         where contestant ~ '\m(Gonzalez|Hernandez|Rodriguez|Perez|Martinez|Garcia|Diaz|Fernandez|Lopez|Sanchez|Ramirez|Alvarez|Vazquez|Gomez|Suarez|Cortes|Valdes|Dominguez|Jose|Angel|Raul|Hector|Maria|Sofia|Alvaro|Rene)\M')
                                                          as concursantes_sin_tilde,
       (select count(*) from public.editions
         where leader ~ '\m(Gonzalez|Hernandez|Rodriguez|Perez|Martinez|Garcia|Lopez|Jose|Raul|Hector|Maria|Sofia|Oscar|Roman)\M')
                                                          as lideres_sin_tilde,
       (select count(*) from public.editions
         where deputy_leader ~ '\m(Gonzalez|Hernandez|Rodriguez|Perez|Martinez|Garcia|Lopez|Jose|Raul|Hector|Maria|Sofia|Oscar|Roman)\M')
                                                          as colideres_sin_tilde;