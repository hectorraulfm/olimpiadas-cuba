-- ============================================================================
--  Da acceso de administrador a iandavidlorenzogarcia02@gmail.com
-- ----------------------------------------------------------------------------
--  Cubre los dos casos posibles:
--    · Si aún no tiene cuenta, se crea la invitación con rol admin. Al
--      registrarse en la web con ese correo quedará como administrador.
--    · Si ya se había registrado antes, se le sube el rol a admin.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

insert into public.invitations (email, role, note)
values ('iandavidlorenzogarcia02@gmail.com', 'admin', 'Ian David Lorenzo García')
on conflict (email) do update
   set role    = 'admin',
       used_at = null,
       note    = 'Ian David Lorenzo García';

-- Por si ya tenía cuenta creada con otro rol.
update public.profiles
   set role = 'admin'
 where lower(email) = 'iandavidlorenzogarcia02@gmail.com';

-- ----------------------------------------------------------------------------
--  Comprobación.
--  invitacion = 1 siempre.
--  perfil     = 1 si ya tenía cuenta, 0 si todavía debe registrarse.
-- ----------------------------------------------------------------------------

select (select count(*) from public.invitations
         where lower(email) = 'iandavidlorenzogarcia02@gmail.com'
           and role = 'admin')                        as invitacion,
       (select count(*) from public.profiles
         where lower(email) = 'iandavidlorenzogarcia02@gmail.com'
           and role = 'admin')                        as perfil;
