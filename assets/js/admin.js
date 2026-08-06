import { supabase, isConfigured, getSessionAndProfile, humanError }
  from "./supabase-client.js";

const $ = (id) => document.getElementById(id);

let me = null;
let historyRows = [];

function esc(value) {
  return String(value ?? "").replace(/[&<>"']/g, (c) => (
    { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]
  ));
}

let toastTimer;
function toast(message, isError = false) {
  const el = $("toast");
  el.textContent = message;
  el.classList.toggle("error", isError);
  el.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove("show"), 3200);
}

function fecha(iso) {
  if (!iso) return "—";
  return new Date(iso).toLocaleString("es-ES", {
    day: "2-digit", month: "2-digit", year: "numeric",
    hour: "2-digit", minute: "2-digit",
  });
}

// ---------------------------------------------------------------------------
// Usuarios
// ---------------------------------------------------------------------------

async function loadUsers() {
  const { data, error } = await supabase
    .from("profiles")
    .select("id, email, full_name, role, created_at")
    .order("created_at", { ascending: true });

  const body = $("users-body");
  if (error) {
    body.innerHTML = `<tr><td colspan="5" class="empty-state">${esc(humanError(error))}</td></tr>`;
    return;
  }
  if (!data.length) {
    body.innerHTML = `<tr><td colspan="5" class="empty-state">No hay usuarios.</td></tr>`;
    return;
  }

  body.innerHTML = data.map((user) => {
    const self = user.id === me.id;
    const options = ["admin", "editor", "viewer"].map((role) =>
      `<option value="${role}"${role === user.role ? " selected" : ""}>${role}</option>`
    ).join("");
    return `
      <tr>
        <td>${esc(user.full_name || "—")}${self ? ' <span class="pill">tú</span>' : ""}</td>
        <td>${esc(user.email)}</td>
        <td>
          <select data-role-for="${esc(user.id)}"${self ? " disabled title='No puedes cambiar tu propio rol'" : ""}>
            ${options}
          </select>
        </td>
        <td class="muted">${fecha(user.created_at)}</td>
        <td class="row-actions">
          ${self ? "" : `<button class="btn btn-sm btn-danger" data-del-user="${esc(user.id)}" data-email="${esc(user.email)}">Eliminar</button>`}
        </td>
      </tr>`;
  }).join("");

  body.querySelectorAll("[data-role-for]").forEach((select) => {
    select.addEventListener("change", async () => {
      const id = select.dataset.roleFor;
      const { error } = await supabase
        .from("profiles").update({ role: select.value }).eq("id", id);
      if (error) { toast(humanError(error), true); loadUsers(); return; }
      toast("Rol actualizado");
    });
  });

  body.querySelectorAll("[data-del-user]").forEach((btn) => {
    btn.addEventListener("click", async () => {
      const email = btn.dataset.email;
      if (!confirm(
        `¿Quitar el perfil de ${email}?\n\n` +
        "Perderá todo permiso de escritura de inmediato. La cuenta de acceso " +
        "sigue existiendo en Supabase: para borrarla del todo, hazlo desde " +
        "Authentication → Users en el panel de Supabase."
      )) return;

      const { error } = await supabase.from("profiles").delete().eq("id", btn.dataset.delUser);
      if (error) { toast(humanError(error), true); return; }
      toast("Perfil eliminado");
      loadUsers();
    });
  });
}

// ---------------------------------------------------------------------------
// Invitaciones
// ---------------------------------------------------------------------------

async function loadInvites() {
  const { data, error } = await supabase
    .from("invitations")
    .select("*")
    .order("created_at", { ascending: false });

  const body = $("invites-body");
  if (error) {
    body.innerHTML = `<tr><td colspan="6" class="empty-state">${esc(humanError(error))}</td></tr>`;
    return;
  }
  if (!data.length) {
    body.innerHTML = `<tr><td colspan="6" class="empty-state">Aún no has invitado a nadie.</td></tr>`;
    return;
  }

  body.innerHTML = data.map((inv) => `
    <tr>
      <td>${esc(inv.email)}</td>
      <td><span class="role-tag">${esc(inv.role)}</span></td>
      <td class="muted">${esc(inv.note || "—")}</td>
      <td>${inv.used_at
            ? `<span class="pill used">usada ${fecha(inv.used_at)}</span>`
            : `<span class="pill">pendiente</span>`}</td>
      <td class="muted">${fecha(inv.created_at)}</td>
      <td class="row-actions">
        <button class="btn btn-sm btn-danger" data-del-invite="${esc(inv.id)}"
                data-email="${esc(inv.email)}">Revocar</button>
      </td>
    </tr>`).join("");

  body.querySelectorAll("[data-del-invite]").forEach((btn) => {
    btn.addEventListener("click", async () => {
      if (!confirm(`¿Revocar la invitación de ${btn.dataset.email}?`)) return;
      const { error } = await supabase
        .from("invitations").delete().eq("id", btn.dataset.delInvite);
      if (error) { toast(humanError(error), true); return; }
      toast("Invitación revocada");
      loadInvites();
    });
  });
}

async function createInvite(event) {
  event.preventDefault();
  const msg = $("invite-msg");
  msg.textContent = "";
  msg.className = "form-msg";

  const email = $("inv-email").value.trim().toLowerCase();
  const { error } = await supabase.from("invitations").insert({
    email,
    role: $("inv-role").value,
    note: $("inv-note").value.trim(),
    created_by: me.id,
  });

  if (error) {
    msg.textContent = humanError(error);
    msg.className = "form-msg error";
    return;
  }

  msg.className = "form-msg ok";
  msg.textContent =
    `Invitado ${email}. Dile que entre en la web, pulse «Entrar» → ` +
    `«Crear cuenta» con ese mismo correo y elija su contraseña.`;
  $("form-invite").reset();
  loadInvites();
}

// ---------------------------------------------------------------------------
// Historial
// ---------------------------------------------------------------------------

const ACCION = { INSERT: "alta", UPDATE: "cambio", DELETE: "borrado" };

/** Resume un cambio mostrando solo los campos que se movieron. */
function describeChange(entry) {
  const ignore = new Set(["updated_at", "id"]);
  const before = entry.old_data ?? {};
  const after = entry.new_data ?? {};

  if (entry.action === "INSERT") {
    const label = after.contestant || after.host_country || "";
    return `<span class="add">creado</span> ${esc(label)}`.trim();
  }
  if (entry.action === "DELETE") {
    const label = before.contestant || before.host_country || "";
    return `<span class="del">eliminado</span> ${esc(label)}`.trim();
  }

  const keys = [...new Set([...Object.keys(before), ...Object.keys(after)])]
    .filter((k) => !ignore.has(k))
    .filter((k) => JSON.stringify(before[k]) !== JSON.stringify(after[k]));

  if (!keys.length) return `<span class="muted">sin cambios visibles</span>`;

  return keys.map((k) =>
    `${esc(k)}: <span class="del">${esc(before[k] ?? "∅")}</span> → ` +
    `<span class="add">${esc(after[k] ?? "∅")}</span>`
  ).join("<br>");
}

async function loadHistory() {
  const limit = Number($("history-limit").value);
  const { data, error } = await supabase
    .from("audit_log")
    .select("*")
    .order("changed_at", { ascending: false })
    .limit(limit);

  if (error) {
    $("history-body").innerHTML =
      `<tr><td colspan="5" class="empty-state">${esc(humanError(error))}</td></tr>`;
    return;
  }
  historyRows = data ?? [];
  renderHistory();
}

function renderHistory() {
  const q = $("history-search").value.trim().toLowerCase();
  const rows = q
    ? historyRows.filter((r) =>
        JSON.stringify(r).toLowerCase().includes(q))
    : historyRows;

  const body = $("history-body");
  if (!rows.length) {
    body.innerHTML = `<tr><td colspan="5" class="empty-state">Sin movimientos registrados.</td></tr>`;
    return;
  }

  body.innerHTML = rows.map((entry) => `
    <tr>
      <td class="muted" style="white-space:nowrap">${fecha(entry.changed_at)}</td>
      <td>${esc(entry.changed_by_email || "—")}</td>
      <td><span class="pill">${ACCION[entry.action] ?? esc(entry.action)}</span></td>
      <td class="muted">${entry.table_name === "results" ? "concursante" : "edición"}
          ${esc(entry.row_id ?? "")}</td>
      <td class="diff">${describeChange(entry)}</td>
    </tr>`).join("");
}

// ---------------------------------------------------------------------------
// Pestañas y arranque
// ---------------------------------------------------------------------------

function wireTabs() {
  document.querySelectorAll('[role="tab"]').forEach((tab) => {
    tab.addEventListener("click", () => {
      document.querySelectorAll('[role="tab"]').forEach((t) =>
        t.setAttribute("aria-selected", String(t === tab)));
      for (const name of ["users", "invites", "history"]) {
        $(`tab-${name}`).hidden = name !== tab.dataset.tab;
      }
      if (tab.dataset.tab === "history" && !historyRows.length) loadHistory();
    });
  });
}

async function init() {
  if (!isConfigured) {
    $("denied").hidden = false;
    $("denied").innerHTML =
      "<strong>Falta configurar Supabase.</strong> Revisa <code>assets/js/config.js</code>.";
    return;
  }

  const { session, profile } = await getSessionAndProfile();
  if (!session || profile?.role !== "admin") {
    $("denied").hidden = false;
    return;
  }

  me = { id: session.user.id, email: session.user.email, ...profile };
  $("admin-user").innerHTML =
    `<div class="userchip"><span class="who">${esc(me.email)}</span>
     <span class="role-tag">admin</span></div>`;
  $("panel").hidden = false;

  wireTabs();
  $("form-invite").addEventListener("submit", createInvite);
  $("btn-reload-history").addEventListener("click", loadHistory);
  $("history-limit").addEventListener("change", loadHistory);
  $("history-search").addEventListener("input", renderHistory);

  await Promise.all([loadUsers(), loadInvites()]);
}

init();
