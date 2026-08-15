-- ============================================================================
--  Invita como editores a los colaboradores de la tabla
-- ----------------------------------------------------------------------------
--  Con rol 'editor' pueden, en las cuatro competiciones:
--    · añadir, modificar y borrar filas de concursantes
--    · modificar la edición: país organizador, sede, líder y colíder
--
--  No pueden crear una edición nueva ni borrar una entera, ni gestionar
--  usuarios. Eso sigue siendo del admin.
--
--  Cubre los dos casos: si aún no tienen cuenta se crea la invitación, y si ya
--  se habían registrado se les fija el rol.
--
--  Cómo usarlo:
--    Supabase → SQL Editor → New query → pega todo → Run
--
--  Es idempotente.
-- ============================================================================

with gente(correo, nombre) as (
  values
    ('iandavidlorenzogarcia02@gmail.com', 'Ian David Lorenzo García'),
    ('damiamfuentes11@gmail.com',         'Damiam David Fuentes Campos'),
    ('dariopalmeroledon@gmail.com',       'Darío Palmero Ledón')
)
insert into public.invitations (email, role, note)
select correo, 'editor', nombre from gente
on conflict (email) do update
   set role    = 'editor',
       used_at = null,
       note    = excluded.note;

-- Por si alguno ya tenía cuenta creada con otro rol.
update public.profiles
   set role = 'editor'
 where lower(email) in ('iandavidlorenzogarcia02@gmail.com',
                        'damiamfuentes11@gmail.com',
                        'dariopalmeroledon@gmail.com');

-- ----------------------------------------------------------------------------
--  Comprobación.
--  invitaciones = 3 siempre.
--  perfiles     = cuántos de los tres se han registrado ya.
-- ----------------------------------------------------------------------------

select (select count(*) from public.invitations
         where role = 'editor'
           and lower(email) in ('iandavidlorenzogarcia02@gmail.com',
                                'damiamfuentes11@gmail.com',
                                'dariopalmeroledon@gmail.com'))  as invitaciones,
       (select count(*) from public.profiles
         where role = 'editor'
           and lower(email) in ('iandavidlorenzogarcia02@gmail.com',
                                'damiamfuentes11@gmail.com',
                                'dariopalmeroledon@gmail.com'))  as perfiles;
