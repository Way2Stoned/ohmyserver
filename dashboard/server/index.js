/**
 * OhMyServer Web-Dashboard — session-gebundenes Backend.
 *
 * Start:   DASH_PORT=8787 DASH_HOST=127.0.0.1 node server/index.js
 * Stop:    Ctrl+C (SIGINT) oder kill <pid> (SIGTERM) — schliesst sauber WS+HTTP+DB.
 *
 * Läuft NUR solange OpenCode/OhMyServer aktiv ist (kein Daemon, kein systemd).
 * OpenCode-DB wird ausschliesslich read-only geöffnet.
 */
import { createServer } from 'node:http';
import { execSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomBytes, createHash } from 'node:crypto';
import os from 'node:os';
import express from 'express';
import { WebSocketServer } from 'ws';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import Database from 'better-sqlite3';
import mariadb from 'mariadb';
import { config, readCredential } from './config.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const TRIGGER_DIR = join(config.ssaDir, 'dashboard', 'triggers');
const SKILL_WHITELIST = new Set(['status', 'maintenance', 'monitor', 'vault', 'verify', 'security', 'supervisor']);

// ---------------------------------------------------------------------------
// MariaDB
// ---------------------------------------------------------------------------
const cred = readCredential('mariadb-ohmyserver.txt') || {};
const dbConfig = {
  host: config.mariadb.host,
  port: config.mariadb.port,
  user: config.mariadb.user,
  password: cred.password || config.mariadb.password,
  database: config.mariadb.database,
  connectionLimit: 5,
};
const pool = mariadb.createPool(dbConfig);

async function initSchema() {
  const sql = readFileSync(join(__dirname, 'schema.sql'), 'utf8');
  const conn = await pool.getConnection();
  try {
    for (const stmt of sql.split(';').map((s) => s.trim()).filter(Boolean)) {
      await conn.query(stmt);
    }
  } finally {
    conn.release();
  }
}

// ---------------------------------------------------------------------------
// OpenCode-DB (read-only)
// ---------------------------------------------------------------------------
let ocDb = null;
function openOcDb() {
  if (ocDb) return ocDb;
  ocDb = new Database(config.opencodeDb, { readonly: true });
  return ocDb;
}

// ---------------------------------------------------------------------------
// Auth helpers
// ---------------------------------------------------------------------------
function signToken(operator) {
  return jwt.sign({ sub: operator.id, name: operator.name }, config.jwtSecret, {
    expiresIn: '12h',
  });
}

function hashToken(token) {
  return createHash('sha256').update(token).digest('hex');
}

function authMiddleware(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const payload = jwt.verify(token, config.jwtSecret);
    req.operator = { id: payload.sub, name: payload.name };
    req.tokenHash = hashToken(token);
    next();
  } catch {
    return res.status(403).json({ error: 'Forbidden' });
  }
}

// ---------------------------------------------------------------------------
// Status helpers
// ---------------------------------------------------------------------------
function serviceStatus() {
  const services = ['ssh', 'nginx', 'mariadb', 'fail2ban'];
  const out = {};
  for (const svc of services) {
    try {
      const r = execSync(`systemctl is-active ${svc} 2>/dev/null || true`).toString().trim();
      out[svc] = r === 'active' ? 'active' : 'inactive';
    } catch {
      out[svc] = 'unknown';
    }
  }
  return out;
}

function diskStatus() {
  try {
    const r = execSync('df -P / 2>/dev/null | tail -1').toString().trim().split(/\s+/);
    return { total: r[1], used: r[2], available: r[3], usePercent: r[4] };
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Express app
// ---------------------------------------------------------------------------
const app = express();
app.use(express.json());
app.use(express.static(join(ROOT, 'public')));

app.get('/api/health', (req, res) => res.json({ ok: true }));

app.post('/api/auth/login', async (req, res) => {
  try {
    const { name, password } = req.body || {};
    if (!name || !password) return res.status(400).json({ error: 'name and password required' });
    const rows = await pool.query('SELECT * FROM operators WHERE name = ?', [name]);
    if (rows.length === 0) return res.status(401).json({ error: 'Invalid credentials' });
    const op = rows[0];
    const ok = await bcrypt.compare(password, op.pass_hash);
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });
    const token = signToken(op);
    await pool.query('UPDATE operators SET last_login = NOW() WHERE id = ?', [op.id]);
    await pool.query(
      'INSERT INTO operator_sessions (id, operator_id, token_hash, expires_at) VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 12 HOUR))',
      [randomBytes(16).toString('hex'), op.id, hashToken(token)]
    );
    res.json({ token, operator: { id: op.id, name: op.name } });
  } catch (err) {
    console.error('login error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

app.post('/api/auth/logout', authMiddleware, async (req, res) => {
  try {
    await pool.query('DELETE FROM operator_sessions WHERE token_hash = ?', [req.tokenHash]);
    res.json({ ok: true });
  } catch (err) {
    console.error('logout error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

app.get('/api/auth/me', authMiddleware, async (req, res) => {
  try {
    const rows = await pool.query('SELECT id, name, created_at, last_login FROM operators WHERE id = ?', [req.operator.id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Operator not found' });
    res.json(rows[0]);
  } catch (err) {
    console.error('me error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

app.get('/api/sessions', authMiddleware, (req, res) => {
  try {
    const db = openOcDb();
    const rows = db
      .prepare(
        `SELECT id, title, agent, model, cost,
                (tokens_input + tokens_output + tokens_reasoning) AS tokens,
                time_updated
         FROM session
         WHERE time_archived IS NULL
         ORDER BY time_updated DESC
         LIMIT 100`
      )
      .all();
    res.json(rows);
  } catch (err) {
    console.error('sessions error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

app.get('/api/sessions/:id', authMiddleware, (req, res) => {
  try {
    const db = openOcDb();
    const session = db.prepare('SELECT * FROM session WHERE id = ?').get(req.params.id);
    if (!session) return res.status(404).json({ error: 'Session not found' });
    const messages = db
      .prepare('SELECT id, time_created, data FROM message WHERE session_id = ? ORDER BY time_created ASC')
      .all(req.params.id);
    const parts = db
      .prepare('SELECT id, message_id, time_created, data FROM part WHERE session_id = ? ORDER BY time_created ASC')
      .all(req.params.id);
    res.json({ session, messages, parts });
  } catch (err) {
    console.error('session detail error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

app.get('/api/todos', authMiddleware, (req, res) => {
  try {
    const db = openOcDb();
    const ocTodos = db
      .prepare(
        `SELECT t.session_id, t.content, t.status, t.priority, t.position, t.time_created
         FROM todo t
         JOIN session s ON s.id = t.session_id
         WHERE s.time_archived IS NULL
         ORDER BY t.time_created DESC
         LIMIT 200`
      )
      .all();
    res.json({ opencode: ocTodos });
  } catch (err) {
    console.error('todos error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

app.get('/api/status', authMiddleware, (req, res) => {
  try {
    const uptime = os.uptime();
    const load = os.loadavg();
    const ram = {
      total: os.totalmem(),
      free: os.freemem(),
      used: os.totalmem() - os.freemem(),
    };
    res.json({
      uptime,
      load,
      ram,
      disk: diskStatus(),
      services: serviceStatus(),
    });
  } catch (err) {
    console.error('status error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

app.get('/api/memory', authMiddleware, async (req, res) => {
  try {
    const rows = await pool.query(
      `SELECT id, category, content_preview, importance_score, access_count, created_at, updated_at
       FROM memory_entries
       WHERE operator_id = ?
       ORDER BY importance_score DESC, updated_at DESC
       LIMIT 200`,
      [req.operator.id]
    );
    res.json(rows);
  } catch (err) {
    console.error('memory list error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

app.get('/api/memory/:id', authMiddleware, async (req, res) => {
  try {
    const rows = await pool.query(
      'SELECT * FROM memory_entries WHERE id = ? AND operator_id = ?',
      [req.params.id, req.operator.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Memory entry not found' });
    await pool.query('UPDATE memory_entries SET access_count = access_count + 1 WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (err) {
    console.error('memory detail error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

app.post('/api/memory', authMiddleware, async (req, res) => {
  try {
    const { content, category = 'episodic', importance_score = 0.5 } = req.body || {};
    if (!content || typeof content !== 'string') return res.status(400).json({ error: 'content required' });
    const preview = content.slice(0, 150);
    const result = await pool.query(
      `INSERT INTO memory_entries (operator_id, category, content_preview, content_full, importance_score)
       VALUES (?, ?, ?, ?, ?)`,
      [req.operator.id, category, preview, content, Number(importance_score) || 0.5]
    );
    res.status(201).json({ id: Number(result.insertId) });
  } catch (err) {
    console.error('memory create error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

app.post('/api/skills/:trigger', authMiddleware, (req, res) => {
  const trigger = req.params.trigger;
  if (!SKILL_WHITELIST.has(trigger)) {
    return res.status(400).json({ error: `Unknown skill trigger '${trigger}'` });
  }
  try {
    mkdirSync(TRIGGER_DIR, { recursive: true });
    const ts = Date.now();
    const job = {
      trigger,
      operator: req.operator.name,
      created_at: new Date().toISOString(),
      status: 'queued',
    };
    const file = join(TRIGGER_DIR, `${ts}-${trigger}.json`);
    writeFileSync(file, JSON.stringify(job, null, 2));
    broadcast({ type: 'trigger', trigger, status: 'queued', file });
    res.status(202).json({ ok: true, trigger, status: 'queued', file });
  } catch (err) {
    console.error('skill trigger error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

// ---------------------------------------------------------------------------
// HTTP + WebSocket server
// ---------------------------------------------------------------------------
const server = createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

function broadcast(msg) {
  const data = JSON.stringify(msg);
  for (const client of wss.clients) {
    if (client.readyState === 1) client.send(data);
  }
}

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'hello' }));
});

// ---------------------------------------------------------------------------
// Startup
// ---------------------------------------------------------------------------
async function ensureAdmin() {
  const rows = await pool.query('SELECT COUNT(*) AS c FROM operators');
  if (Number(rows[0].c) > 0) return;
  const password = process.env.DASH_ADMIN_PASSWORD || randomBytes(12).toString('base64url');
  const hash = await bcrypt.hash(password, 10);
  const adminName = process.env.OMS_ADMIN || process.env.DASH_ADMIN || 'admin';
  await pool.query('INSERT INTO operators (name, pass_hash) VALUES (?, ?)', [adminName, hash]);
  console.log('==============================================');
  console.log('Initial admin operator created:');
  console.log(`  name:     ${adminName}`);
  console.log(`  password: ${password}`);
  console.log('  (password shown only here, not stored in chat)');
  console.log('==============================================');
}

async function start() {
  try {
    await initSchema();
    await ensureAdmin();
    openOcDb();
    server.listen(config.port, config.host, () => {
      console.log(`OhMyServer Dashboard listening on http://${config.host}:${config.port}`);
    });
  } catch (err) {
    console.error('Startup failed:', err);
    process.exit(1);
  }
}

function shutdown(signal) {
  console.log(`\nReceived ${signal}, shutting down...`);
  try {
    for (const client of wss.clients) client.close();
    wss.close();
    server.close();
    if (ocDb) ocDb.close();
    pool.end();
  } catch (err) {
    console.error('Shutdown error:', err);
  }
  process.exit(0);
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

start();
