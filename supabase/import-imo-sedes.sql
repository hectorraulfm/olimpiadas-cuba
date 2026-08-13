-- ============================================================================
--  IMO: país y ciudad de cada edición
--  Fuente: https://www.imo-official.org/editions/
--          consultada el 13 de agosto de 2026. Es la fuente oficial.
-- ----------------------------------------------------------------------------
--  Cubre las 55 ediciones de 1971 a 2026 (en 1980 no hubo IMO).
--
--  Los países van traducidos al español, porque el resto del sitio lo está.
--  De las ciudades solo se traducen las que tienen nombre español de uso
--  corriente (Moscú, Varsovia, Praga, Londres…); las demás quedan como las
--  publica la IMO. Se conservan los nombres históricos de los países que ya no
--  existen: Checoslovaquia, Yugoslavia, la RDA y la Unión Soviética.
--
--  REGLA: solo escribe donde el campo esté vacío.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

alter table public.editions disable trigger editions_audit;

with sedes(anyo, pais, ciudad) as (
  values
    (2026, 'China',                           'Shanghái'),
    (2025, 'Australia',                       'Sunshine Coast'),
    (2024, 'Reino Unido',                     'Bath'),
    (2023, 'Japón',                           'Chiba'),
    (2022, 'Noruega',                         'Oslo'),
    (2021, 'Rusia',                           '(virtual, desde San Petersburgo)'),
    (2020, 'Rusia',                           '(virtual, desde San Petersburgo)'),
    (2019, 'Reino Unido',                     'Bath'),
    (2018, 'Rumanía',                         'Cluj-Napoca'),
    (2017, 'Brasil',                          'Río de Janeiro'),
    (2016, 'Hong Kong',                       'Hong Kong'),
    (2015, 'Tailandia',                       'Chiang Mai'),
    (2014, 'Sudáfrica',                       'Ciudad del Cabo'),
    (2013, 'Colombia',                        'Santa Marta'),
    (2012, 'Argentina',                       'Mar del Plata'),
    (2011, 'Países Bajos',                    'Ámsterdam'),
    (2010, 'Kazajistán',                      'Astana'),
    (2009, 'Alemania',                        'Bremen'),
    (2008, 'España',                          'Madrid'),
    (2007, 'Vietnam',                         'Hanói'),
    (2006, 'Eslovenia',                       'Ljubljana'),
    (2005, 'México',                          'Mérida'),
    (2004, 'Grecia',                          'Atenas'),
    (2003, 'Japón',                           'Tokio'),
    (2002, 'Reino Unido',                     'Glasgow'),
    (2001, 'Estados Unidos',                  'Washington'),
    (2000, 'Corea del Sur',                   'Taejon'),
    (1999, 'Rumanía',                         'Bucarest'),
    (1998, 'Taiwán',                          'Taipéi'),
    (1997, 'Argentina',                       'Mar del Plata'),
    (1996, 'India',                           'Mumbai'),
    (1995, 'Canadá',                          'Toronto'),
    (1994, 'Hong Kong',                       'Hong Kong'),
    (1993, 'Turquía',                         'Estambul'),
    (1992, 'Rusia',                           'Moscú'),
    (1991, 'Suecia',                          'Sigtuna'),
    (1990, 'China',                           'Pekín'),
    (1989, 'Alemania',                        'Braunschweig'),
    (1988, 'Australia',                       'Canberra'),
    (1987, 'Cuba',                            'La Habana'),
    (1986, 'Polonia',                         'Varsovia'),
    (1985, 'Finlandia',                       'Joutsa'),
    (1984, 'Checoslovaquia',                  'Praga'),
    (1983, 'Francia',                         'París'),
    (1982, 'Hungría',                         'Budapest'),
    (1981, 'Estados Unidos',                  'Washington'),
    (1979, 'Reino Unido',                     'Londres'),
    (1978, 'Rumanía',                         'Bucarest'),
    (1977, 'Yugoslavia',                      'Belgrado'),
    (1976, 'Austria',                         'Lienz'),
    (1975, 'Bulgaria',                        'Burgas'),
    (1974, 'República Democrática Alemana',   'Erfurt'),
    (1973, 'Unión Soviética',                 'Moscú'),
    (1972, 'Polonia',                         'Toruń'),
    (1971, 'Checoslovaquia',                  'Žilina')
)
update public.editions e
   set host_country = s.pais
  from sedes s
 where e.competition = 'imo'
   and e.year = s.anyo
   and e.host_country = '';   -- respeta lo que ya hubiera

with sedes(anyo, ciudad) as (
  values
    (2026, 'Shanghái'), (2025, 'Sunshine Coast'), (2024, 'Bath'),
    (2023, 'Chiba'), (2022, 'Oslo'),
    (2021, '(virtual, desde San Petersburgo)'),
    (2020, '(virtual, desde San Petersburgo)'),
    (2019, 'Bath'), (2018, 'Cluj-Napoca'), (2017, 'Río de Janeiro'),
    (2016, 'Hong Kong'), (2015, 'Chiang Mai'), (2014, 'Ciudad del Cabo'),
    (2013, 'Santa Marta'), (2012, 'Mar del Plata'), (2011, 'Ámsterdam'),
    (2010, 'Astana'), (2009, 'Bremen'), (2008, 'Madrid'), (2007, 'Hanói'),
    (2006, 'Ljubljana'), (2005, 'Mérida'), (2004, 'Atenas'), (2003, 'Tokio'),
    (2002, 'Glasgow'), (2001, 'Washington'), (2000, 'Taejon'),
    (1999, 'Bucarest'), (1998, 'Taipéi'), (1997, 'Mar del Plata'),
    (1996, 'Mumbai'), (1995, 'Toronto'), (1994, 'Hong Kong'),
    (1993, 'Estambul'), (1992, 'Moscú'), (1991, 'Sigtuna'), (1990, 'Pekín'),
    (1989, 'Braunschweig'), (1988, 'Canberra'), (1987, 'La Habana'),
    (1986, 'Varsovia'), (1985, 'Joutsa'), (1984, 'Praga'), (1983, 'París'),
    (1982, 'Budapest'), (1981, 'Washington'), (1979, 'Londres'),
    (1978, 'Bucarest'), (1977, 'Belgrado'), (1976, 'Lienz'), (1975, 'Burgas'),
    (1974, 'Erfurt'), (1973, 'Moscú'), (1972, 'Toruń'), (1971, 'Žilina')
)
update public.editions e
   set host_city = s.ciudad
  from sedes s
 where e.competition = 'imo'
   and e.year = s.anyo
   and e.host_city = '';

alter table public.editions enable trigger editions_audit;

-- ----------------------------------------------------------------------------
--  Comprobación. Esperado: 55 con país y 55 con ciudad.
-- ----------------------------------------------------------------------------

select count(*)                                  as ediciones,
       count(*) filter (where host_country <> '') as con_pais,
       count(*) filter (where host_city <> '')    as con_ciudad
  from public.editions
 where competition = 'imo';
