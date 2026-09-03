const API = '/api';
let token = localStorage.getItem('dash_token') || null;

const $ = (id) => document.getElementById(id);

function show(view) {
  $('login-view').classList.toggle('hidden', view !== 'login');
  $('dashboard-view').classList.toggle('hidden', view !== 'dashboard');
}

async function api(path, opts = {}) {
  const headers = { 'Content-Type': 'application/json', ...(opts.headers || {}) };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(API + path, { ...opts, headers });
  if (res.status === 401 || res.status === 403) {
    logout();
    throw new Error('Unauthorized');
  }
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error || res.statusText);
  }
  return res.json();
}

function fmtBytes(n) {
  if (n == null) return '–';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  let i = 0;
  while (n >= 1024 && i < units.length - 1) { n /= 1024; i++; }
  return `${n.toFixed(1)} ${units[i]}`;
}

function fmtUptime(s) {
  const d = Math.floor(s / 86400);
  const h = Math.floor((s % 86400) / 3600);
  const m = Math.floor((s % 3600) / 60);
  return `${d}d ${h}h ${m}m`;
}

function fmtDate(ts) {
  if (!ts) return '–';
  const d = new Date(ts);
  return d.toLocaleString('de-DE', { dateStyle: 'short', timeStyle: 'short' });
}

// --- Login ---
$('login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  $('login-error').classList.add('hidden');
  try {
    const data = await api('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ name: $('login-name').value, password: $('login-password').value }),
    });
    token = data.token;
    localStorage.setItem('dash_token', token);
    $('operator-name').textContent = data.operator.name;
    show('dashboard');
    loadAll();
  } catch (err) {
    $('login-error').textContent = err.message;
    $('login-error').classList.remove('hidden');
  }
});

$('logout-btn').addEventListener('click', logout);

function logout() {
  if (token) api('/auth/logout', { method: 'POST' }).catch(() => {});
  token = null;
  localStorage.removeItem('dash_token');
  show('login');
}

// --- Data loading ---
async function loadAll() {
  loadStatus();
  loadSessions();
  loadTodos();
  loadMemory();
}

async function loadStatus() {
  try {
    const s = await api('/status');
    $('stat-uptime').textContent = fmtUptime(s.uptime);
    $('stat-load').textContent = s.load.map((l) => l.toFixed(2)).join(' / ');
    $('stat-ram').textContent = `${fmtBytes(s.ram.used)} / ${fmtBytes(s.ram.total)}`;
    $('stat-disk').textContent = s.disk ? `${s.disk.usePercent} used` : '–';
    const svc = $('services');
    svc.innerHTML = '';
    for (const [name, state] of Object.entries(s.services)) {
      const chip = document.createElement('span');
      chip.className = `chip ${state === 'active' ? 'active' : 'inactive'}`;
      chip.textContent = `${name}: ${state}`;
      svc.appendChild(chip);
    }
  } catch (err) {
    console.error(err);
  }
}

async function loadSessions() {
  try {
    const rows = await api('/sessions');
    const el = $('sessions');
    el.innerHTML = '';
    for (const s of rows.slice(0, 30)) {
      const item = document.createElement('div');
      item.className = 'item';
      item.innerHTML = `
        <div class="title">${escapeHtml(s.title || 'Untitled')}</div>
        <div class="meta">
          <span class="tag">${escapeHtml(s.agent || '')}</span>
          <span class="tag">${escapeHtml(s.model || '')}</span>
          ${fmtDate(s.time_updated)}
        </div>`;
      el.appendChild(item);
    }
  } catch (err) {
    console.error(err);
  }
}

async function loadTodos() {
  try {
    const data = await api('/todos');
    const el = $('todos');
    el.innerHTML = '';
    const todos = (data.opencode || []).filter((t) => t.status !== 'completed').slice(0, 30);
    if (todos.length === 0) {
      el.innerHTML = '<div class="muted">Keine offenen Todos</div>';
      return;
    }
    for (const t of todos) {
      const item = document.createElement('div');
      item.className = 'item';
      item.innerHTML = `
        <div class="title">${escapeHtml(t.content)}</div>
        <div class="meta"><span class="tag">${escapeHtml(t.status)}</span><span class="tag">${escapeHtml(t.priority)}</span></div>`;
      el.appendChild(item);
    }
  } catch (err) {
    console.error(err);
  }
}

async function loadMemory() {
  try {
    const rows = await api('/memory');
    const el = $('memory');
    el.innerHTML = '';
    if (rows.length === 0) {
      el.innerHTML = '<div class="muted">Keine Memory-Einträge</div>';
      return;
    }
    for (const m of rows) {
      const item = document.createElement('div');
      item.className = 'item';
      item.innerHTML = `
        <div class="title">${escapeHtml(m.content_preview)}</div>
        <div class="meta"><span class="tag">${escapeHtml(m.category)}</span>Importance: ${m.importance_score}</div>`;
      el.appendChild(item);
    }
  } catch (err) {
    console.error(err);
  }
}

// --- Skill triggers ---
const SKILLS = ['status', 'maintenance', 'monitor', 'vault', 'verify', 'security', 'supervisor'];
const btnWrap = $('skill-buttons');
for (const skill of SKILLS) {
  const btn = document.createElement('button');
  btn.className = 'btn skill';
  btn.textContent = skill;
  btn.addEventListener('click', () => triggerSkill(skill));
  btnWrap.appendChild(btn);
}

async function triggerSkill(skill) {
  $('trigger-result').textContent = `Trigger '${skill}' wird ausgelöst...`;
  try {
    const r = await api(`/skills/${skill}`, { method: 'POST' });
    $('trigger-result').textContent = `Trigger '${skill}' in Queue (${r.status}).`;
  } catch (err) {
    $('trigger-result').textContent = `Fehler: ${err.message}`;
  }
}

function escapeHtml(str) {
  return String(str).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}

// --- Init ---
if (token) {
  api('/auth/me')
    .then((me) => {
      $('operator-name').textContent = me.name;
      show('dashboard');
      loadAll();
    })
    .catch(() => logout());
} else {
  show('login');
}
