-- ============================================================================
--  Da acceso de editor a iandavidlorenzogarcia02@gmail.com
-- ----------------------------------------------------------------------------
--  Con rol 'editor' podrá añadir, modificar y borrar filas de concursantes:
--  nombre, resultado, puntos por problema y total, en las cuatro competiciones.
--
--  No podrá tocar los datos de la edición en sí —año, país, sede, líder y
--  colíder— ni borrar una edición entera. Eso sigue reservado al admin.
--
--  Cubre los dos casos posibles:
--    · Si aún no tiene cuenta, se crea la invitación. Al registrarse en la web
--      con ese correo quedará como editor.
--    · Si ya se había registrado antes, se le fija el rol de editor.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

insert into public.invitations (email, role, note)
values ('iandavidlorenzogarcia02@gmail.com', 'editor', 'Ian David Lorenzo García')
on conflict (email) do update
   set role    = 'editor',
       used_at = null,
       note    = 'Ian David Lorenzo García';

-- Por si ya tenía cuenta creada con otro rol.
update public.profiles
   set role = 'editor'
 where lower(email) = 'iandavidlorenzogarcia02@gmail.com';

-- ----------------------------------------------------------------------------
--  Comprobación.
--  invitacion = 1 siempre.
--  perfil     = 1 si ya tenía cuenta, 0 si todavía debe registrarse.
-- ----------------------------------------------------------------------------

select (select count(*) from public.invitations
         where lower(email) = 'iandavidlorenzogarcia02@gmail.com'
           and role = 'editor')                       as invitacion,
       (select count(*) from public.profiles
         where lower(email) = 'iandavidlorenzogarcia02@gmail.com'
           and role = 'editor')                       as perfil;
