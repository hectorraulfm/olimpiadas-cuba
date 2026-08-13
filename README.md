# Cuba en las Olimpiadas de Matemática

Web colaborativa con los resultados históricos de la delegación cubana, al
estilo de las tablas por país de [imo-official.org](https://www.imo-official.org/results/individual/country/CUB/).

Cubre dos competiciones, en pestañas:

| Competición | Desde | Concursantes por país |
|---|---|---|
| **Iberoamericana** | 1985 (no hubo edición en 1986) | 4 |
| **Centroamericana y del Caribe** | 1999 | 3 hasta 2017, 4 desde 2018 |

Se puede enlazar directamente a una de ellas añadiendo `#ibero` o `#centro` al
final de la dirección.

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

4. *(Opcional pero recomendado)* En otra query, pega
   [`supabase/seed-ediciones.sql`](supabase/seed-ediciones.sql) y pulsa **Run**:
   crea el esqueleto completo, una edición por año de **1985 a 2025** con
   **4 filas de concursante** en cada una (41 ediciones, 164 filas), todo en
   blanco y listo para ir rellenando.

   > Da por hecho que hubo participación cubana todos los años. Si algún año no
   > la hubo, borra esa edición desde la web (solo `admin`).

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

Es pública, no hace falta cuenta. Sale entera, del año más reciente al más
antiguo, y se puede exportar a CSV.

### Rellenar datos (rol `editor` o `admin`)

- El botón **+** junto al año añade un concursante (normalmente 4 por año).
- El botón **✎** al final de cada fila edita ese concursante.

### Ediciones (solo `admin`)

Los editores no pueden tocar el año, el país organizador, la sede ni los
líderes; esos botones solo los ve un `admin`, y la base de datos rechaza el
cambio aunque alguien lo intente por su cuenta.

- **+ Nueva edición** crea un año: país organizador, sede, líder y colíder.
- El botón **✎** junto al año edita esos datos de la edición.

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
| `editor` | Añadir, modificar y borrar filas de concursantes (nombre, resultado, puntos) |
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
│       ├── app.js             Tabla, formularios, CSV
│       └── admin.js           Usuarios, invitaciones, historial
├── supabase/
│   ├── schema.sql          Tablas, roles, RLS, triggers e historial
│   ├── seed-ediciones.sql  Esqueleto ibero: 1985–2025, 4 filas por año
│   ├── import-2026-08.sql  Sedes 1987–2024 y 53 concursantes cubanos
│   ├── import-doc-nelson.sql        Líderes y 28 concursantes más
│   └── migracion-centroamericana.sql  Segunda competición y su esqueleto
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

El contador **Por rellenar** del resumen indica cuántas filas siguen sin
concursante, para ver de un vistazo cuánto queda por completar.

## Ideas para más adelante

- Rellenar el país organizador y la sede de cada año a partir de fuentes públicas.
- Columna de puesto individual: el campo `rank` ya existe en la tabla `results`,
  solo falta mostrarlo.
- Ficha por concursante con todas sus participaciones.
- Botón de deshacer en el historial, aprovechando el `old_data` guardado.

## Sobre la escala de puntuación

Hoy cada uno de los 6 problemas vale 7 puntos, con un máximo de 42. Las primeras
ediciones (al menos 1987 y 1993) puntuaban sobre 10, con un máximo de 60. Por eso
la base de datos admite hasta 10 por problema y 60 de total.

## Aviso sobre los datos

Los datos los aportan personas voluntarias y pueden contener errores o huecos.
No es una fuente oficial.

La importación de agosto de 2026 (`supabase/import-2026-08.sql`) procede de
<https://iberoofficial.vercel.app>, que tampoco es la fuente oficial y está
incompleta: documenta ediciones desde 1987 y no recoge concursantes de todos los
años en los que Cuba participó. Los huecos que quedan en la tabla no significan
que Cuba no participara, sino que faltan los datos.
