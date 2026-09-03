import { readFileSync } from 'node:fs';

function env(key, def = '') {
  return process.env[key] ?? def;
}

export const config = {
  port: Number(env('DASH_PORT', '8787')),
  host: env('DASH_HOST', '127.0.0.1'),
  jwtSecret: env('DASH_JWT_SECRET') || readJwtSecret(),
  opencodeDb: env(
    'OPENCODE_DB',
    `${process.env.HOME || '/root'}/.local/share/opencode/opencode.db`
  ),
  mariadb: {
    host: env('MARIADB_HOST', '127.0.0.1'),
    port: Number(env('MARIADB_PORT', '3306')),
    user: env('MARIADB_USER', 'ohmyserver'),
    password: env('MARIADB_PASSWORD', ''),
    database: env('MARIADB_DB', 'ohmyserver'),
  },
  ssaDir: env('SSA_DIR', `${process.env.HOME || '/root'}/.ssa`),
};

export function loadConfig() {
  return config;
}

export function readCredential(name) {
  try {
    const raw = readFileSync(`${config.ssaDir}/credentials/${name}`, 'utf8');
    const out = {};
    for (const line of raw.split('\n')) {
      const m = line.match(/^([^:]+):\s*(.*)$/);
      if (m) out[m[1].trim()] = m[2].trim();
    }
    return out;
  } catch {
    return null;
  }
}

export function readJwtSecret() {
  const fromFile = readCredential('dashboard-jwt-secret.txt');
  if (fromFile && fromFile.password) return fromFile.password.trim();
  if (process.env.DASH_JWT_SECRET) return process.env.DASH_JWT_SECRET;
  return 'insecure-dev-secret-change-me';
}
