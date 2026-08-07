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

// Título y textos del sitio (cámbialos a tu gusto).
export const SITE = {
  title: "Cuba en la Olimpiada Iberoamericana de Matemática",
  short: "Cuba · Ibero",
  intro:
    "Resultados históricos de la delegación cubana. La tabla se completa entre " +
    "todos, así que aún tiene huecos y puede contener errores.",

  // Si lo dejas vacío, no se muestra la invitación a escribir.
  contactEmail: "hectorraulfm@gmail.com",
  contactText: "¿Ves algo que corregir o tienes datos que faltan? Escribe a",
};
