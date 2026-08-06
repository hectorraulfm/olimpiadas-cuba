import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./config.js";

export const isConfigured =
  !SUPABASE_URL.startsWith("PON_AQUI") && !SUPABASE_ANON_KEY.startsWith("PON_AQUI");

export const supabase = createClient(
  isConfigured ? SUPABASE_URL : "https://placeholder.supabase.co",
  isConfigured ? SUPABASE_ANON_KEY : "placeholder",
  { auth: { persistSession: true, autoRefreshToken: true } }
);

/** Sesión actual + perfil (rol) del usuario, o null si no ha entrado. */
export async function getSessionAndProfile() {
  if (!isConfigured) return { session: null, profile: null };

  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return { session: null, profile: null };

  const { data: profile, error } = await supabase
    .from("profiles")
    .select("id, email, full_name, role")
    .eq("id", session.user.id)
    .maybeSingle();

  if (error) console.warn("No se pudo leer el perfil:", error.message);
  return { session, profile: profile ?? null };
}

/** Traduce los errores de Supabase a algo legible en español. */
export function humanError(error) {
  if (!error) return "";
  const msg = error.message || String(error);
  const map = {
    "Invalid login credentials": "Correo o contraseña incorrectos.",
    "Email not confirmed":
      "El correo aún no está confirmado. Revisa tu bandeja de entrada.",
    "User already registered":
      "Ese correo ya tiene cuenta. Usa «Entrar» en lugar de «Crear cuenta».",
    "Password should be at least 6 characters":
      "La contraseña debe tener al menos 6 caracteres.",
  };
  if (map[msg]) return map[msg];
  if (msg.includes("no tiene invitación")) {
    return "Este correo no tiene invitación. Pide acceso al administrador.";
  }
  if (msg.includes("row-level security") || msg.includes("violates row-level")) {
    return "No tienes permiso para hacer ese cambio.";
  }
  if (msg.includes("duplicate key") && msg.includes("editions_pkey")) {
    return "Ya existe una edición para ese año.";
  }
  if (msg.includes("duplicate key") && msg.includes("invitations")) {
    return "Ese correo ya está invitado.";
  }
  return msg;
}
