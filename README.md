# Cuba en la Olimpiada Iberoamericana de Matemática

Web colaborativa con los resultados históricos de la delegación cubana, al
estilo de las tablas por país de [imo-official.org](https://www.imo-official.org/results/individual/country/CUB/).

**Columnas:** año · país organizador · concursante (varias filas por año) ·
resultado · puntos · P1–P6 · líder · colíder.

Cualquiera puede consultar la tabla. Solo las personas a las que tú invites
pueden modificarla, y cada cambio queda registrado con autor y fecha.

- HTML, CSS y JavaScript puros: **sin compilación, sin `npm`, sin servidor**.
- Base de datos, login y permisos con [Supabase](https://supabase.com) (plan gratuito).
- Se publica gratis en GitHub Pages.

---

## Puesta en marcha (unos 10 minutos)

### 1. Crear el proyecto en Supabase

1. Entra en [supabase.com](https://supabase.com) y crea una cuenta.
2. **New project**. Elige un nombre, una contraseña de base de datos (guárdala)
   y la región más cercana. Espera a que termine de crearse.
3. Menú lateral → **SQL Editor** → **New query**. Pega el contenido completo de
   [`supabase/schema.sql`](supabase/schema.sql) y pulsa **Run**.
   Debe terminar con «Success. No rows returned».

### 2. Darte de alta como administrador

En el mismo **SQL Editor**, ejecuta esto cambiando el correo por el tuyo:

```sql
insert into public.invitations (email, role, note)
values ('tucorreo@ejemplo.com', 'admin', 'Administrador inicial')
on conflict (email) do update set role = 'admin', used_at = null;
```

### 3. Desactivar la confirmación por correo

Supabase, por defecto, solo envía correos de confirmación a los miembros del
proyecto, así que conviene desactivarla:

**Authentication → Sign In / Providers → Email** → desactiva **Confirm email** →
**Save**.

> Si prefieres mantenerla activada, configura antes un SMTP propio en
> *Project Settings → Authentication → SMTP Settings*.

### 4. Conectar la web con tu proyecto

En Supabase: **Project Settings → API**. Copia dos valores y ponlos en
[`assets/js/config.js`](assets/js/config.js):

| Supabase | Variable en `config.js` |
|---|---|
| Project URL | `SUPABASE_URL` |
| `anon` `public` key | `SUPABASE_ANON_KEY` |

```js
export const SUPABASE_URL = "https://abcdefgh.supabase.co";
export const SUPABASE_ANON_KEY = "eyJhbGciOi...";
```

La clave `anon` **es pública por diseño** y puede subirse a GitHub sin riesgo:
lo que protege los datos son las políticas RLS del esquema. La clave
`service_role`, en cambio, **nunca** debe aparecer en este repositorio.

### 5. Publicar en GitHub Pages

En GitHub: **Settings → Pages → Source: Deploy from a branch → `main` / `(root)`**.
En un minuto la web estará en:

```
https://hectorraulfm.github.io/ibero-cuba/
```

### 6. Crear tu cuenta

Abre la web, **Entrar → Crear cuenta**, usa el correo del paso 2 y elige tu
contraseña. Entrarás como `admin` y verás el botón **Administración**.

---

## Uso diario

### Ver la tabla

Es pública, no hace falta cuenta. Se puede buscar por concursante, país o líder,
filtrar por medalla, ordenar por año y exportar todo a CSV.

### Rellenar datos (rol `editor` o `admin`)

- **+ Nueva edición** crea un año: país organizador, sede, líder y colíder.
- El botón **✎** junto al año edita esos datos de la edición.
- El botón **+** junto al año añade un concursante (normalmente 4 por año).
- El botón **✎** al final de cada fila edita ese concursante.

Todo campo puede quedarse vacío: la idea es ir completando poco a poco.
Los puntos totales se calculan solos al escribir P1–P6, pero puedes
sobrescribirlos si solo conoces el total.

### Dar acceso a otras personas (rol `admin`)

En **Administración → Invitaciones**: escribe el correo, elige el rol y pulsa
**Invitar**. Esa persona entra en la web, pulsa **Entrar → Crear cuenta** con ese
mismo correo y elige su propia contraseña.

Nadie que no esté invitado puede registrarse: el registro se bloquea en la
propia base de datos.

> **¿Por qué no puedo asignarle yo la contraseña?** Hacerlo desde una web
> estática exigiría publicar la clave `service_role` de Supabase, que da control
> total sobre la base de datos a cualquiera que vea el código fuente. Con las
> invitaciones tú decides igualmente quién entra y con qué permisos, pero la
> contraseña solo la conoce su dueño. Si aun así necesitas fijar una contraseña
> concreta, puedes hacerlo desde el panel de Supabase en
> *Authentication → Users*.

| Rol | Puede |
|---|---|
| `admin` | Todo: datos, usuarios, invitaciones, historial y borrar ediciones |
| `editor` | Crear y modificar ediciones y concursantes; borrar filas de concursantes |
| `viewer` | Solo lectura (igual que una visita anónima) |

### Historial

**Administración → Historial** muestra cada alta, cambio y borrado, con el
correo de quien lo hizo, la fecha y qué campos cambiaron. Nadie puede borrar ni
alterar ese registro desde la web.

---

## Estructura

```
ibero-cuba/
├── index.html              Tabla pública + edición
├── admin.html              Panel de administración
├── assets/
│   ├── css/styles.css
│   └── js/
│       ├── config.js          <- tus claves de Supabase
│       ├── supabase-client.js
│       ├── app.js             Tabla, filtros, formularios, CSV
│       └── admin.js           Usuarios, invitaciones, historial
├── supabase/schema.sql     Tablas, roles, RLS, triggers e historial
└── dev-server.ps1          Servidor local para pruebas (Windows)
```

## Desarrollo local

Los módulos ES no funcionan abriendo el fichero con doble clic (`file://`), hace
falta un servidor estático. En Windows, sin instalar nada:

```bash
powershell -ExecutionPolicy Bypass -File dev-server.ps1
```

Y abre <http://localhost:8765>. Si tienes Python en el PATH, vale igual:

```bash
python -m http.server 8000
```

## Ideas para más adelante

- Precargar la lista de ediciones (año, país y sede) de todas las Iberoamericanas.
- Columna de puesto individual: el campo `rank` ya existe en la tabla `results`,
  solo falta mostrarlo.
- Ficha por concursante con todas sus participaciones.
- Botón de deshacer en el historial, aprovechando el `old_data` guardado.

## Aviso sobre los datos

Los datos los aportan personas voluntarias y pueden contener errores o huecos.
No es una fuente oficial.
