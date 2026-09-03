# Web Dashboard

The OhMyServer dashboard is a session-bound web UI for observability and safe remote actions. It runs only while an OpenCode/OhMyServer session is active.

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                      Browser (HTTPS)                           │
│                         │                                       │
│                         ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  nginx (TLS termination, reverse proxy)                  │  │
│  │  server_name: dashboard.<domain>                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                         │                                       │
│                         ▼ (localhost:8787)                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Node.js Dashboard (Express + WebSocket)                 │  │
│  │  - JWT auth (12h sessions)                               │  │
│  │  - Read-only OpenCode DB                                 │  │
│  │  - MariaDB: operators, memory, secrets, sessions         │  │
│  │  - Skill trigger whitelist                               │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

## Features

| Feature | Description |
|---------|-------------|
| **Session-bound** | Runs only during OpenCode session; no systemd, no daemon |
| **Operator auth** | MariaDB-backed, bcrypt passwords, JWT (12h) |
| **Real-time** | WebSocket for live status/trigger updates |
| **Skill triggers** | Whitelisted skills only: `status`, `maintenance`, `monitor`, `vault`, `verify`, `security`, `supervisor` |
| **OpenCode sessions** | Read-only view of sessions, messages, todos |
| **Memory browser** | CRUD for structured memory (categories, importance, search) |
| **System status** | CPU, RAM, disk, service health (ssh, nginx, mariadb, fail2ban) |
| **Vault UI** | List secrets (names only), add/get/delete (JWT-protected) |

## Quick Start

### Prerequisites

- OpenCode + OhMyServer installed
- MariaDB running (`WITH_DB=1` during install)
- Node.js 18+ (for dashboard server)

### Start Dashboard

```bash
# From OhMyServer install directory
cd ~/.config/opencode/skills/ohmyserver/dashboard
./dashboard-ctl.sh start

# Or via skill trigger (in OpenCode)
#supervisor check
#dashboard start   # if dashboard skill exists
```

### Access

- **Local**: `http://127.0.0.1:8787` (default bind)
- **Remote**: Configure nginx + TLS (see below)

### Default Credentials

On first start, dashboard creates admin operator:
```
name:     <server> (from server.json server_name)
password: <shown once in console output>
```

> Save the password! It's only shown once. Change it via `#vault` or dashboard UI after first login.

## Configuration

Environment variables (loaded by `dashboard/server/config.js`):

| Variable | Default | Description |
|----------|---------|-------------|
| `DASH_PORT` | `8787` | HTTP port |
| `DASH_HOST` | `127.0.0.1` | Bind address |
| `DASH_JWT_SECRET` | (from file) | JWT signing secret |
| `OPENCODE_DB` | `~/.local/share/opencode/opencode.db` | OpenCode SQLite path |
| `MARIADB_HOST` | `127.0.0.1` | MariaDB host |
| `MARIADB_PORT` | `3306` | MariaDB port |
| `MARIADB_USER` | `ohmyserver` | MariaDB user |
| `MARIADB_PASSWORD` | (from cred file) | MariaDB password |
| `MARIADB_DB` | `ohmyserver` | MariaDB database |
| `SSA_DIR` | `~/.ssa` | Runtime data directory |

### Credential Files (chmod 600)

| File | Used By |
|------|---------|
| `~/.ssa/credentials/mariadb-ohmyserver.txt` | DB password |
| `~/.ssa/credentials/dashboard-jwt-secret.txt` | JWT secret |

## nginx + TLS Deployment

Reference config: `dashboard/deploy/nginx-dashboard.conf` (copy to `/etc/nginx/sites-available/dashboard.<domain>`)

### Template

```nginx
# HTTP: ACME challenge + redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name dashboard.<domain>;

    location ^~ /.well-known/acme-challenge/ {
        root /var/www/certbot;
        default_type "text/plain";
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS: Reverse proxy to dashboard
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name dashboard.<domain>;

    ssl_certificate     /etc/letsencrypt/live/dashboard.<domain>/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dashboard.<domain>/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Proxy headers for Express behind proxy
    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # WebSocket support (live status)
    location /ws {
        proxy_pass http://127.0.0.1:8787;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location / {
        proxy_pass http://127.0.0.1:8787;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Enable

```bash
# 1. Copy config
sudo cp dashboard/deploy/nginx-dashboard.conf /etc/nginx/sites-available/dashboard.<domain>
sudo sed -i 's/dashboard\.talbergh\.art/dashboard.<domain>/g' /etc/nginx/sites-available/dashboard.<domain>

# 2. Enable site
sudo ln -s /etc/nginx/sites-available/dashboard.<domain> /etc/nginx/sites-enabled/

# 3. Test + reload
sudo nginx -t && sudo systemctl reload nginx

# 4. Get TLS cert (Let's Encrypt)
sudo certbot --nginx -d dashboard.<domain>
```

### Firewall

```bash
# Allow HTTPS only (dashboard binds to localhost)
sudo ufw allow 443/tcp
sudo ufw deny 8787/tcp   # Ensure dashboard port not exposed directly
```

## Dashboard Control Script

`dashboard/dashboard-ctl.sh`:

```bash
./dashboard-ctl.sh start    # Start in background, logs to ~/.ssa/logs/dashboard.log
./dashboard-ctl.sh stop     # Graceful shutdown (SIGTERM)
./dashboard-ctl.sh restart  # Stop + start
./dashboard-ctl.sh status   # Check if running
./dashboard-ctl.sh logs     # Tail log file
```

## API Reference

All endpoints require `Authorization: Bearer <JWT>` except `/api/health`.

### Auth

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | `{name, password}` → `{token, operator}` |
| POST | `/api/auth/logout` | Revoke current token |
| GET | `/api/auth/me` | Current operator info |

### Sessions (Read-Only from OpenCode DB)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/sessions` | List recent sessions (100) |
| GET | `/api/sessions/:id` | Session detail + messages + parts |

### Todos (Read-Only)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/todos` | All active todos across sessions |

### System Status

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/status` | `{uptime, load, ram, disk, services}` |

### Memory

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/memory` | List entries (200, by importance) |
| GET | `/api/memory/:id` | Full entry (increments access_count) |
| POST | `/api/memory` | Create: `{content, category?, importance_score?}` |

### Skill Triggers (Whitelisted Only)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/skills/:trigger` | Queue trigger: `status`, `maintenance`, `monitor`, `vault`, `verify`, `security`, `supervisor` |

**Response**: `{ok: true, trigger, status: "queued", file: "~/.ssa/dashboard/triggers/<ts>-<trigger>.json"}`

OpenCode picks up trigger files via file watcher and executes the skill.

### WebSocket

- **Endpoint**: `wss://dashboard.<domain>/ws` (or `ws://127.0.0.1:8787/ws` locally)
- **Auth**: JWT via query param `?token=<JWT>` on connection
- **Messages**:
  - Server → Client: `{type: "hello"}`, `{type: "trigger", trigger, status, file}`, `{type: "status", ...}`
  - Client → Server: (none currently, reserved for future)

## Skill Trigger Whitelist

Only these triggers accepted via `/api/skills/:trigger`:

| Trigger | Skill | Use Case |
|---------|-------|----------|
| `status` | ohmyserver-status | Compact system status |
| `maintenance` | ohmyserver-maintenance | Backup, cleanup, install |
| `monitor` | ohmyserver-monitor | Health, uptime, updates |
| `vault` | ohmyserver-vault | List/add/get secrets |
| `verify` | ohmyserver-verify | Empirical verification |
| `security` | ohmyserver-security | Scan, audit |
| `supervisor` | ohmyserver-supervisor | Consistency check, heal |

**Blocked triggers** (require interactive OpenCode): `operator`, `memory`, `dispatcher`, `code-planner`, `code-writer`, `code-verifier`, `edit-agent`, `design`, `users`, `database`, `backup`, `config`, `update`, `notify`

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| "Cannot connect to MariaDB" | Check `~/.ssa/credentials/mariadb-ohmyserver.txt` exists, chmod 600, credentials correct |
| "JWT secret insecure" | Replace `~/.ssa/credentials/dashboard-jwt-secret.txt` with `openssl rand -base64 32` |
| Dashboard won't start | Check port 8787 free: `ss -ltnp | grep 8787`; check Node.js version ≥18 |
| WebSocket fails behind nginx | Ensure `proxy_set_header Upgrade/Connection` in nginx config |
| 401 on API calls | Token expired (12h); re-login via `/api/auth/login` |
| Skill trigger ignored | Verify trigger in whitelist; check `~/.ssa/dashboard/triggers/` for queue files |

## Security Notes

- Dashboard **never runs as root** — runs as operator user
- Binds to `127.0.0.1` by default — **never expose port 8787 directly**
- All secrets in `~/.ssa/credentials/` (chmod 600)
- OpenCode DB opened **read-only**
- Skill triggers **whitelisted** — no arbitrary code execution
- JWT **short-lived** (12h), hashed in DB for revocation

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) — dashboard in system context
- [SECURITY.md](SECURITY.md) — JWT, credentials, threat model
- [INSTALL.md](INSTALL.md) — MariaDB setup prerequisite