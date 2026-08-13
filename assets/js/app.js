import { supabase, isConfigured, getSessionAndProfile, humanError }
  from "./supabase-client.js";
import { SITE, COMPETICIONES } from "./config.js";

// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------

const state = {
  editions: [],
  results: [],
  profile: null,
  session: null,
  // Competición visible. Se guarda en el hash de la URL para poder enlazarla.
  competition: COMPETICIONES[0].id,
};

const compActual = () =>
  COMPETICIONES.find((c) => c.id === state.competition) ?? COMPETICIONES[0];

/**
 * Competición de una fila. Si la base de datos todavía no tiene la columna
 * —porque la migración no se ha ejecutado— se asume la Iberoamericana, que era
 * lo único que existía antes.
 */
const compDe = (fila) => fila.competition ?? "ibero";

/** Filas de la competición visible. */
const edicionesVisibles = () =>
  state.editions.filter((e) => compDe(e) === state.competition);
const resultadosVisibles = () =>
  state.results.filter((r) => compDe(r) === state.competition);

const $ = (id) => document.getElementById(id);
const canEdit = () => ["admin", "editor"].includes(state.profile?.role);
const isAdmin = () => state.profile?.role === "admin";

// ---------------------------------------------------------------------------
// Utilidades
// ---------------------------------------------------------------------------

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

const AWARD_CLASS = {
  "Oro": "award-oro",
  "Plata": "award-plata",
  "Bronce": "award-bronce",
  "Mención de Honor": "award-mencion",
};

/** Lee un input numérico devolviendo null cuando está vacío. */
function numOrNull(el) {
  const raw = el.value.trim();
  if (raw === "") return null;
  const n = Number(raw);
  return Number.isFinite(n) ? n : null;
}

function openDialog(dialog) {
  dialog.showModal();
}

// ---------------------------------------------------------------------------
// Autenticación
// ---------------------------------------------------------------------------

let authMode = "login"; // "login" | "signup"

function renderAuthArea() {
  const area = $("auth-area");
  if (!state.session) {
    area.innerHTML = `<button class="btn" id="btn-login">Entrar</button>`;
    $("btn-login").disabled = !isConfigured;
    $("btn-login").onclick = () => {
      setAuthMode("login");
      openDialog($("dlg-auth"));
    };
    return;
  }

  const who = state.profile?.full_name?.trim() || state.session.user.email;
  const role = state.profile?.role ?? "viewer";
  area.innerHTML = `
    <div class="userchip">
      <span class="who">${esc(who)}</span>
      <span class="role-tag">${esc(role)}</span>
    </div>
    ${isAdmin() ? `<a class="btn" href="admin.html">Administración</a>` : ""}
    <button class="btn" id="btn-logout">Salir</button>`;

  $("btn-logout").onclick = async () => {
    await supabase.auth.signOut();
    toast("Sesión cerrada");
  };
}

function setAuthMode(mode) {
  authMode = mode;
  const signup = mode === "signup";
  $("auth-title").textContent = signup ? "Crear cuenta" : "Entrar";
  $("btn-auth-submit").textContent = signup ? "Crear cuenta" : "Entrar";
  $("btn-toggle-mode").textContent = signup ? "Ya tengo cuenta" : "Crear cuenta";
  $("field-name").hidden = !signup;
  $("auth-pass").autocomplete = signup ? "new-password" : "current-password";
  $("auth-hint").textContent = signup
    ? "Solo puedes registrarte si el administrador invitó previamente tu correo."
    : "¿No tienes cuenta? Solo pueden registrarse los correos invitados por el administrador.";
  $("auth-msg").textContent = "";
  $("auth-msg").className = "form-msg";
}

async function handleAuthSubmit(event) {
  event.preventDefault();
  const msg = $("auth-msg");
  const email = $("auth-email").value.trim();
  const password = $("auth-pass").value;
  const submit = $("btn-auth-submit");

  msg.textContent = "";
  msg.className = "form-msg";
  submit.disabled = true;

  try {
    if (authMode === "signup") {
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: { data: { full_name: $("auth-name").value.trim() } },
      });
      if (error) throw error;
      msg.textContent = "Cuenta creada. Ya puedes entrar.";
      msg.className = "form-msg ok";
      setTimeout(() => {
        setAuthMode("login");
        $("auth-email").value = email;
      }, 1200);
    } else {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      $("dlg-auth").close();
      $("form-auth").reset();
      toast("Sesión iniciada");
    }
  } catch (error) {
    msg.textContent = humanError(error);
    msg.className = "form-msg error";
  } finally {
    submit.disabled = false;
  }
}

// ---------------------------------------------------------------------------
// Carga de datos
// ---------------------------------------------------------------------------

async function loadData() {
  if (!isConfigured) return;

  const [editions, results] = await Promise.all([
    supabase.from("editions").select("*").order("year", { ascending: false }),
    supabase.from("results").select("*").order("sort_order", { ascending: true }),
  ]);

  if (editions.error) { toast(humanError(editions.error), true); return; }
  if (results.error) { toast(humanError(results.error), true); return; }

  state.editions = editions.data ?? [];
  state.results = results.data ?? [];

  // Si la pestaña por defecto todavía no tiene datos —por ejemplo una
  // competición recién añadida cuyo SQL aún no se ha ejecutado— se abre la
  // primera que sí los tenga. Si el visitante pidió una concreta por la URL,
  // se respeta su elección.
  if (!location.hash && !edicionesVisibles().length) {
    const conDatos = COMPETICIONES.find((c) =>
      state.editions.some((e) => compDe(e) === c.id));
    if (conDatos) state.competition = conDatos.id;
  }

  render();
}

// ---------------------------------------------------------------------------
// Render de la tabla
// ---------------------------------------------------------------------------

/** Ediciones de más reciente a más antigua, cada una con sus concursantes. */
function orderedGroups() {
  const byYear = new Map();
  for (const row of resultadosVisibles()) {
    if (!byYear.has(row.year)) byYear.set(row.year, []);
    byYear.get(row.year).push(row);
  }

  return [...edicionesVisibles()]
    .sort((a, b) => b.year - a.year)
    .map((edition) => ({
      edition,
      rows: (byYear.get(edition.year) ?? [])
        .slice()
        .sort((a, b) => (a.sort_order - b.sort_order) ||
                        (a.contestant ?? "").localeCompare(b.contestant ?? "", "es")),
    }));
}

function awardCell(award) {
  if (!award) return `<span class="empty-cell">—</span>`;
  return `<span class="award ${AWARD_CLASS[award] ?? ""}">${esc(award)}</span>`;
}

function pointCell(value) {
  if (value === null || value === undefined) return `<span class="empty-cell">·</span>`;
  return `<span class="${value === 0 ? "p-zero" : ""}">${value}</span>`;
}

function textCell(value) {
  const text = String(value ?? "").trim();
  return text ? esc(text) : `<span class="empty-cell">—</span>`;
}

/** Una fila cuenta como participación si tiene nombre, medalla o puntuación. */
const tieneDato = (r) =>
  (r.contestant ?? "").trim() !== "" || Boolean(r.award) || r.total != null;

function renderStats() {
  const filas = resultadosVisibles();
  const count = (award) => filas.filter((r) => r.award === award).length;
  const named = filas.filter(tieneDato);

  $("s-editions").textContent = edicionesVisibles().length;
  $("s-contestants").textContent = named.length;
  $("s-todo").textContent = filas.length - named.length;
  $("s-gold").textContent = count("Oro");
  $("s-silver").textContent = count("Plata");
  $("s-bronze").textContent = count("Bronce");
  $("s-hm").textContent = count("Mención de Honor");
  $("stats").hidden = edicionesVisibles().length === 0;
}

/** Pinta las pestañas y marca la activa. */
function renderTabs() {
  const nav = $("comp-tabs");
  nav.innerHTML = COMPETICIONES.map((c) => {
    const n = state.results.filter(
      (r) => compDe(r) === c.id && tieneDato(r)).length;
    return `<button role="tab" data-comp="${c.id}"
              aria-selected="${c.id === state.competition}">${esc(c.tab)}${
      n ? `<span class="count">${n}</span>` : ""}</button>`;
  }).join("");

  $("site-subtitle").textContent = compActual().subtitulo;
}

function setCompetition(id, { push = true } = {}) {
  if (!COMPETICIONES.some((c) => c.id === id)) return;
  state.competition = id;
  if (push && location.hash.slice(1) !== id) location.hash = id;
  render();
}

function render() {
  const editing = canEdit();
  const table = document.querySelector("table.results");
  const colCount = editing ? 14 : 13;

  renderTabs();

  // Crear y editar ediciones es cosa del admin; los editores solo rellenan
  // concursantes y puntos.
  $("th-actions").hidden = !editing;
  $("btn-new-edition").hidden = !isAdmin();

  // Reconstruye todos los <tbody> de datos.
  table.querySelectorAll("tbody").forEach((tb) => tb.remove());

  const groups = orderedGroups();

  if (!groups.length) {
    const tb = document.createElement("tbody");
    let message;
    if (!isConfigured) {
      message = "Configura Supabase para ver los datos.";
    } else if (state.editions.length && !edicionesVisibles().length) {
      message = `Todavía no hay ediciones de la ${compActual().tab}.`;
    } else if (isAdmin()) {
      message = "Todavía no hay ediciones. Empieza con «+ Nueva edición».";
    } else {
      message = "Todavía no hay ediciones registradas.";
    }
    tb.innerHTML = `<tr><td colspan="${colCount}" class="empty-state">${message}</td></tr>`;
    table.appendChild(tb);
    renderStats();
    return;
  }

  for (const { edition, rows } of groups) {
    const tb = document.createElement("tbody");
    tb.className = "edition";
    const span = Math.max(rows.length, 1);

    const groupControls = editing ? `
      <div class="group-actions">
        ${isAdmin() ? `<button class="btn-icon" data-edit-edition="${edition.year}"
                title="Editar edición ${edition.year}">✎</button>` : ""}
        <button class="btn-icon" data-add-result="${edition.year}"
                title="Añadir concursante a ${edition.year}">+</button>
      </div>` : "";

    const host = `
      <div class="host">
        <span>${textCell(edition.host_country)}</span>
        ${edition.host_city ? `<span class="city">${esc(edition.host_city)}</span>` : ""}
      </div>`;

    const displayRows = rows.length ? rows : [null];

    displayRows.forEach((row, index) => {
      const tr = document.createElement("tr");
      const cells = [];

      if (index === 0) {
        cells.push(`<td class="year group" rowspan="${span}">${edition.year}${groupControls}</td>`);
        cells.push(`<td class="group" rowspan="${span}">${host}</td>`);
      }

      if (row) {
        cells.push(`<td>${textCell(row.contestant)}</td>`);
        cells.push(`<td>${awardCell(row.award)}</td>`);
        cells.push(`<td class="num total">${row.total ?? `<span class="empty-cell">·</span>`}</td>`);
        for (const key of ["p1", "p2", "p3", "p4", "p5", "p6"]) {
          cells.push(`<td class="num">${pointCell(row[key])}</td>`);
        }
      } else {
        cells.push(`<td colspan="9" class="muted">Sin concursantes registrados</td>`);
      }

      if (index === 0) {
        cells.push(`<td class="group-left" rowspan="${span}">${textCell(edition.leader)}</td>`);
        cells.push(`<td rowspan="${span}">${textCell(edition.deputy_leader)}</td>`);
      }

      if (editing) {
        cells.push(`<td class="row-actions">${
          row ? `<button class="btn-icon" data-edit-result="${row.id}" title="Editar fila">✎</button>` : ""
        }</td>`);
      }

      tr.innerHTML = cells.join("");
      tb.appendChild(tr);
    });

    table.appendChild(tb);
  }

  renderStats();
}

// ---------------------------------------------------------------------------
// Formulario de edición (año)
// ---------------------------------------------------------------------------

let editingYear = null; // null = crear

function openEditionDialog(year) {
  editingYear = year;
  const edition = year !== null
    ? edicionesVisibles().find((e) => e.year === year)
    : null;

  $("edition-title").textContent = edition
    ? `${compActual().tab} ${edition.year}`
    : `Nueva edición · ${compActual().tab}`;
  $("ed-year").value = edition?.year ?? "";
  $("ed-year").disabled = Boolean(edition);
  $("ed-country").value = edition?.host_country ?? "";
  $("ed-city").value = edition?.host_city ?? "";
  $("ed-leader").value = edition?.leader ?? "";
  $("ed-deputy").value = edition?.deputy_leader ?? "";
  $("ed-notes").value = edition?.notes ?? "";
  $("edition-msg").textContent = "";
  $("btn-delete-edition").hidden = !edition || !isAdmin();

  openDialog($("dlg-edition"));
}

async function saveEdition(event) {
  event.preventDefault();
  const msg = $("edition-msg");
  msg.textContent = "";
  msg.className = "form-msg";

  const payload = {
    host_country: $("ed-country").value.trim(),
    host_city: $("ed-city").value.trim(),
    leader: $("ed-leader").value.trim(),
    deputy_leader: $("ed-deputy").value.trim(),
    notes: $("ed-notes").value.trim(),
  };

  let error;
  if (editingYear === null) {
    payload.year = Number($("ed-year").value);
    payload.competition = state.competition;
    ({ error } = await supabase.from("editions").insert(payload));
  } else {
    ({ error } = await supabase.from("editions").update(payload)
      .eq("year", editingYear)
      .eq("competition", state.competition));
  }

  if (error) {
    msg.textContent = humanError(error);
    msg.className = "form-msg error";
    return;
  }

  $("dlg-edition").close();
  toast("Edición guardada");
  await loadData();
}

async function deleteEdition() {
  if (editingYear === null) return;
  const rows = resultadosVisibles().filter((r) => r.year === editingYear).length;
  const warning = rows
    ? `\n\nSe borrarán también sus ${rows} fila(s) de concursantes.`
    : "";
  if (!confirm(`¿Eliminar la edición ${editingYear} de la ${compActual().tab}?${warning}\n\nEsta acción queda registrada en el historial.`)) return;

  const { error } = await supabase.from("editions").delete()
    .eq("year", editingYear)
    .eq("competition", state.competition);
  if (error) {
    $("edition-msg").textContent = humanError(error);
    $("edition-msg").className = "form-msg error";
    return;
  }
  $("dlg-edition").close();
  toast("Edición eliminada");
  await loadData();
}

// ---------------------------------------------------------------------------
// Formulario de concursante
// ---------------------------------------------------------------------------

let editingResult = null; // {id} o {year} para crear
let totalTouched = false;

const P_IDS = ["rs-p1", "rs-p2", "rs-p3", "rs-p4", "rs-p5", "rs-p6"];

function recomputeTotal() {
  if (totalTouched) return;
  const values = P_IDS.map((id) => numOrNull($(id))).filter((v) => v !== null);
  $("rs-total").value = values.length
    ? values.reduce((a, b) => a + b, 0)
    : "";
}

function openResultDialog({ id = null, year = null }) {
  const row = id ? state.results.find((r) => r.id === id) : null;
  editingResult = row ? { id: row.id, year: row.year } : { id: null, year };
  totalTouched = false;

  const targetYear = row?.year ?? year;
  $("result-title").textContent = row
    ? `Concursante · ${targetYear}`
    : `Nuevo concursante · ${targetYear}`;
  $("rs-name").value = row?.contestant ?? "";
  $("rs-award").value = row?.award ?? "";
  P_IDS.forEach((elId, i) => { $(elId).value = row?.[`p${i + 1}`] ?? ""; });
  $("rs-total").value = row?.total ?? "";
  $("rs-notes").value = row?.notes ?? "";
  $("result-msg").textContent = "";
  $("btn-delete-result").hidden = !row;

  openDialog($("dlg-result"));
}

async function saveResult(event) {
  event.preventDefault();
  const msg = $("result-msg");
  msg.textContent = "";
  msg.className = "form-msg";

  const payload = {
    contestant: $("rs-name").value.trim(),
    award: $("rs-award").value || null,
    total: numOrNull($("rs-total")),
    notes: $("rs-notes").value.trim(),
  };
  P_IDS.forEach((elId, i) => { payload[`p${i + 1}`] = numOrNull($(elId)); });

  let error;
  if (editingResult.id) {
    ({ error } = await supabase.from("results").update(payload).eq("id", editingResult.id));
  } else {
    const hermanas = resultadosVisibles()
      .filter((r) => r.year === editingResult.year);
    payload.year = editingResult.year;
    payload.competition = state.competition;
    payload.sort_order =
      hermanas.reduce((max, r) => Math.max(max, r.sort_order ?? 0), 0) + 1;
    ({ error } = await supabase.from("results").insert(payload));
  }

  if (error) {
    msg.textContent = humanError(error);
    msg.className = "form-msg error";
    return;
  }

  $("dlg-result").close();
  toast("Datos guardados");
  await loadData();
}

async function deleteResult() {
  if (!editingResult?.id) return;
  if (!confirm("¿Eliminar esta fila de concursante?")) return;

  const { error } = await supabase.from("results").delete().eq("id", editingResult.id);
  if (error) {
    $("result-msg").textContent = humanError(error);
    $("result-msg").className = "form-msg error";
    return;
  }
  $("dlg-result").close();
  toast("Fila eliminada");
  await loadData();
}

// ---------------------------------------------------------------------------
// Exportar CSV
// ---------------------------------------------------------------------------

function exportCsv() {
  const head = ["Año", "País organizador", "Sede", "Concursante", "Resultado",
                "Puntos", "P1", "P2", "P3", "P4", "P5", "P6", "Líder", "Colíder"];
  const lines = [head];

  for (const { edition, rows } of orderedGroups()) {
    const base = [edition.year, edition.host_country, edition.host_city];
    const tail = [edition.leader, edition.deputy_leader];
    if (!rows.length) {
      lines.push([...base, "", "", "", "", "", "", "", "", "", ...tail]);
      continue;
    }
    for (const row of rows) {
      lines.push([
        ...base, row.contestant, row.award ?? "", row.total ?? "",
        row.p1 ?? "", row.p2 ?? "", row.p3 ?? "",
        row.p4 ?? "", row.p5 ?? "", row.p6 ?? "",
        ...tail,
      ]);
    }
  }

  const csv = lines
    .map((cols) => cols.map((c) => `"${String(c ?? "").replace(/"/g, '""')}"`).join(","))
    .join("\r\n");

  const blob = new Blob(["﻿" + csv], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `cuba-${state.competition === "centro" ? "centroamericana" : "iberoamericana"}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

// ---------------------------------------------------------------------------
// Arranque
// ---------------------------------------------------------------------------

async function refreshSession() {
  const { session, profile } = await getSessionAndProfile();
  state.session = session;
  state.profile = profile;
  renderAuthArea();
  render();
}

function wireEvents() {
  // Cierre genérico de modales.
  document.querySelectorAll("dialog").forEach((dialog) => {
    dialog.querySelectorAll("[data-close]").forEach((btn) => {
      btn.onclick = () => dialog.close();
    });
  });

  $("form-auth").addEventListener("submit", handleAuthSubmit);
  $("btn-toggle-mode").onclick = () =>
    setAuthMode(authMode === "login" ? "signup" : "login");

  $("form-edition").addEventListener("submit", saveEdition);
  $("btn-delete-edition").onclick = deleteEdition;

  $("form-result").addEventListener("submit", saveResult);
  $("btn-delete-result").onclick = deleteResult;
  P_IDS.forEach((id) => $(id).addEventListener("input", recomputeTotal));
  $("rs-total").addEventListener("input", () => { totalTouched = true; });

  $("btn-new-edition").onclick = () => openEditionDialog(null);
  $("btn-export").onclick = exportCsv;

  $("comp-tabs").addEventListener("click", (event) => {
    const tab = event.target.closest("[data-comp]");
    if (tab) setCompetition(tab.dataset.comp);
  });

  // Atrás y adelante del navegador cambian de pestaña.
  window.addEventListener("hashchange", () => {
    const id = location.hash.slice(1);
    if (id && id !== state.competition) setCompetition(id, { push: false });
  });

  // Delegación de clics dentro de la tabla.
  document.querySelector("table.results").addEventListener("click", (event) => {
    const target = event.target.closest("[data-edit-edition], [data-add-result], [data-edit-result]");
    if (!target) return;
    if (target.dataset.editEdition) {
      openEditionDialog(Number(target.dataset.editEdition));
    } else if (target.dataset.addResult) {
      openResultDialog({ year: Number(target.dataset.addResult) });
    } else if (target.dataset.editResult) {
      openResultDialog({ id: target.dataset.editResult });
    }
  });

  supabase.auth.onAuthStateChange(() => { refreshSession(); });
}

async function init() {
  document.title = SITE.title;
  $("site-title").textContent = SITE.title;

  // Permite enlazar directamente una competición: .../#centro
  const desdeUrl = location.hash.slice(1);
  if (COMPETICIONES.some((c) => c.id === desdeUrl)) state.competition = desdeUrl;

  // Se construye con nodos, no con HTML, para que el correo sea un enlace
  // sin abrir la puerta a inyección desde la configuración.
  $("site-intro").textContent = SITE.intro;
  if (SITE.contactEmail) {
    const link = document.createElement("a");
    link.href = `mailto:${SITE.contactEmail}`;
    link.textContent = SITE.contactEmail;
    $("site-intro").append(` ${SITE.contactText} `, link, ".");
  }

  if (!isConfigured) $("setup-banner").hidden = false;

  wireEvents();
  await refreshSession();
  await loadData();
}

init();
