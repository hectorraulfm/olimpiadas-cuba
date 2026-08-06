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

export const SUPABASE_URL = "PON_AQUI_TU_PROJECT_URL";
export const SUPABASE_ANON_KEY = "PON_AQUI_TU_ANON_KEY";

// Título y textos del sitio (cámbialos a tu gusto).
export const SITE = {
  title: "Cuba en la Olimpiada Iberoamericana de Matemática",
  short: "Cuba · Ibero",
  intro:
    "Resultados históricos de la delegación cubana. La tabla se completa entre " +
    "todos: si tienes datos y permiso de edición, puedes añadirlos.",
};
