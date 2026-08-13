// ---------------------------------------------------------------------------
//  Configuración de Supabase
//
//  Rellena estos dos valores con los de tu proyecto:
//    Supabase -> Project Settings -> API
//      - Project URL      -> SUPABASE_URL
//      - anon / public key -> SUPABASE_ANON_KEY
//
//  La clave "anon" es pública por diseño y puede subirse a GitHub sin problema:
//  lo que protege los datos son las políticas RLS de supabase/schema.sql.
//  NUNCA pongas aquí la clave "service_role".
// ---------------------------------------------------------------------------

export const SUPABASE_URL = "https://wtvibkumesmopmauntnt.supabase.co";
export const SUPABASE_ANON_KEY = "sb_publishable__cxlKRM1XiUjJ3DO5Pd03g_CQrwDo7T";

// Las dos competiciones. El orden es el de las pestañas.
// La clave ('ibero', 'centro') es la que se guarda en la base de datos.
export const COMPETICIONES = [
  {
    id: "imo",
    tab: "IMO",
    nombre: "Olimpiada Internacional de Matemática",
    subtitulo: "Cuba desde 1971 · 6 concursantes por país",
  },
  {
    id: "ibero",
    tab: "Iberoamericana",
    nombre: "Olimpiada Iberoamericana de Matemática",
    subtitulo: "Desde 1985 · 4 concursantes por país",
  },
  {
    id: "centro",
    tab: "Centroamericana",
    nombre: "Olimpiada de Matemática de Centroamérica y el Caribe",
    subtitulo: "Desde 1999 · 3 concursantes por país, 4 desde 2018",
  },
];

// Título y textos del sitio (cámbialos a tu gusto).
export const SITE = {
  title: "Cuba en las Olimpiadas de Matemática",
  short: "Cuba · Olimpiadas",
  intro:
    "Resultados históricos de la delegación cubana. La tabla se completa entre " +
    "todos, así que aún tiene huecos y puede contener errores.",

  // Si lo dejas vacío, no se muestra la invitación a escribir.
  contactEmail: "hectorraulfm@gmail.com",
  contactText: "¿Ves algo que corregir o tienes datos que faltan? Escribe a",
};
