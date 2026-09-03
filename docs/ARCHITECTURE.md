# Architecture Overview

OhMyServer is a modular OpenCode addon for server management. This document explains how the pieces fit together.

## High-Level Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        OpenCode (Host)                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  OhMyServer Skill Set                     │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐    │   │
│  │  │ Operator │ │ Memory   │ │Dispatch- │ │  Skills  │    │   │
│  │  │  Session │ │  & Todos │ │  er      │ │ (20+)    │    │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
       ┌────────────┐ ┌────────────┐ ┌────────────┐
       │  Scripts   │ │  Dashboard │ │   Vault    │
       │  (CLI)     │ │  (Web)     │ │  (Secrets) │
       └────────────┘ └────────────┘ └────────────┘
              │               │               │
              └───────────────┼───────────────┘
                              ▼
                    ┌────────────────────┐
                    │     MariaDB        │
                    │  (optional,        │
                    │   WITH_DB=1)       │
                    └────────────────────┘
```

## Core Layers

### 1. Skills Layer (`skills/`)

20+ specialized OpenCode skills, each a self-contained agent with:
- `SKILL.md` — frontmatter (name, description, triggers) + behavior
- `references/` — domain-specific reference docs (optional)
- `commands.md` routing — `#<agent> <action>` syntax (Minecraft-inspired)

**Shared Standards** (`_STANDARD.md`): All skills MUST follow:
- Compact output (progressbar style, no AI-slop)
- `#`-command system (`#memory show`, `#operator login <name>`)
- Smart menus via `ask`/`question` tool
- Operator login/session management
- `.ssa` logging + memory updates after every task
- Security confirmation for dangerous changes
- Command safety (timeouts, exit-code verification)

**Global Commands** (available in every skill):
- `#help` — compact trigger/command list
- `#status` — skill-specific status
- `#memory` — open/summarize memory for this skill
- `#operator` — session management

### 2. Dispatcher (`skills/dispatcher/`)

Central orchestrator that routes requests to appropriate skills/subagents:
- **Routing table** in `commands.md` maps `#<agent>` → skill
- **Parallel delegation** via background tasks (6-point prompt structure)
- **Consolidation** merges multiple subagent results
- **Delegation template** in `dispatcher/references/delegations-template.md`

### 3. Scripts Layer (`scripts/`)

Standalone executable Bash scripts for server operations:
- **Status & verification**: `status.sh`, `verify-all.sh`, `integration.sh`
- **Security audits**: `security-scan.sh`, `ssh-audit.sh`, `log-scan.sh`, `user-scan.sh`
- **Database**: `db-check.sh`, `backup.sh`, `backup-rotate.sh`
- **System**: `health-check.sh`, `service-audit.sh`, `disk-report.sh`, `cleanup.sh`
- **Config & secrets**: `server-config.sh`, `vault.sh`, `memory-query.sh`, `memory-migrate.sh`
- **Automation**: `cron-scheduler.sh`, `update-scan.sh`

All scripts:
- Output `--json` for machine consumption
- Support `--dry-run` for safety
- Use `server-config.sh` for configuration (loads `server.json` + exports `OMS_*` env vars)

### 4. Server Config Layer (`scripts/server-config.sh` + `~/.ssa/server.json`)

Replaces hardcoded server values with configurable identity:

**`server.json`** (single source of truth):
```json
{
  "server_name": "<server>",
  "user": "<user>",
  "domain": "<domain>",
  "purpose": "personal",
  "admin": "<user>@<domain>",
  "install_dir": "~/.config/opencode/skills/ohmyserver",
  "ssa_dir": "~/.ssa",
  "language": "en",
  "with_db": true,
  "created_iso": "2026-01-15T10:30:00Z",
  "updated_iso": "2026-01-15T10:30:00Z"
}
```

**`server-config.sh`** loads it and exports:
- `OMS_SERVER_NAME`, `OMS_USER`, `OMS_DOMAIN`, `OMS_ADMIN`, `OMS_PURPOSE`
- `OMS_INSTALL_DIR`, `OMS_SSA_DIR`, `OMS_LANGUAGE`, `OMS_WITH_DB`

Skills and scripts source this for portable, reusable configuration.

### 5. Memory System (`skills/memory/` + MariaDB)

**On-demand recall** — not continuous indexing:
- Operator memory: `~/.ssa/operators/memory.md` (preferences, session log, open points)
- Structured memory: MariaDB `memory_entries` table (categories: episodic, semantic, procedural, preference)
- Full-text search via MariaDB FULLTEXT indexes
- Importance scoring + access counting for relevance ranking
- Dashboard API: `GET /api/memory`, `POST /api/memory`

### 6. Vault / Secrets (`skills/vault/` + `scripts/vault.sh`)

**Encrypted secrets in MariaDB (AES)**:
- Master key **off-repo**: `~/.ssa/credentials/vault-master.key` (chmod 600)
- Secrets table: `operator_id`, `name`, `kind` (password/token/api_key/other), `cipher` (AES_ENCRYPT), `note`
- `#vault list` — **never shows values**, only names + categories
- `#vault get` — decrypts only for authenticated operator
- `#vault rotate` — re-encrypts all secrets with new master key (requires confirmation)
- Dashboard integration (JWT-protected endpoints)

### 7. Supervisor / Watchdog (`skills/supervisor/`)

**Consistency monitoring, not auto-healing**:
- Scans all skills for: structure, routing duplicates, trigger conflicts, broken references
- Reports inconsistencies → proposes auto-heal (requires operator approval)
- `#supervisor check` — full scan
- `#supervisor status` — compact dashboard widget
- `#supervisor heal <type>` — apply fix (only with confirmation)
- Feeds status to dashboard via `~/.ssa/dashboard/triggers/`

### 8. Dashboard (`dashboard/`)

**Session-bound web UI** (Node.js + Express + WebSocket):
- Runs **only while OpenCode/OhMyServer is active** (no daemon, no systemd)
- Binds to `127.0.0.1:8787` by default (configurable via `DASH_PORT`, `DASH_HOST`)
- **Operator auth**: MariaDB `operators` table, bcrypt passwords, JWT sessions (12h)
- **Skill trigger whitelist**: only `status`, `maintenance`, `monitor`, `vault`, `verify`, `security`, `supervisor` can be triggered from UI
- **Real-time**: WebSocket for live status updates
- **Read-only OpenCode DB**: accesses `~/.local/share/opencode/opencode.db` for sessions/todos

**Endpoints**:
| Endpoint | Auth | Description |
|----------|------|-------------|
| `/api/health` | none | Health check |
| `/api/auth/login` | none | Returns JWT |
| `/api/auth/me` | JWT | Current operator |
| `/api/sessions` | JWT | OpenCode sessions (read-only) |
| `/api/todos` | JWT | OpenCode todos (read-only) |
| `/api/status` | JWT | System status (CPU, RAM, disk, services) |
| `/api/memory` | JWT | Memory entries (CRUD) |
| `/api/skills/:trigger` | JWT | Queue skill trigger (whitelisted only) |

**Deployment**: See [DASHBOARD.md](DASHBOARD.md) for nginx + TLS reference.

### 9. Notification Agent (`skills/notification/`)

**Central alert router** — all skills send alerts here:
- Priority levels: INFO → NOTFALL
- Coordinates with other skills
- Optional push: ntfy, Telegram, email (configurable)

## Data Flow Examples

### Operator Runs `#security scan`

```
User: #security scan
  → OpenCode loads ohmyserver-security skill
  → Skill runs security-scan.sh (via script or internal logic)
  → Results logged to ~/.ssa/logs/security.log
  → Memory updated if findings
  → Notification agent alerted if issues found
  → Compact summary returned to user
```

### Dashboard Triggers `#vault list`

```
Dashboard UI: "List Secrets" button
  → POST /api/skills/vault (JWT auth)
  → Writes trigger file to ~/.ssa/dashboard/triggers/<ts>-vault.json
  → OpenCode (running) picks up trigger via file watcher
  → Runs ohmyserver-vault skill → vault.sh list
  → Results broadcast via WebSocket to dashboard
  → UI updates with secret names/categories (no values)
```

### Server Config Used in Script

```bash
#!/usr/bin/env bash
source scripts/server-config.sh   # loads server.json → exports OMS_*
echo "Backing up $OMS_SERVER_NAME to $OMS_SSA_DIR/backups/"
```

## Directory Layout Summary

| Path | Purpose |
|------|---------|
| `~/.config/opencode/skills/ohmyserver/` | Installed skills (read-only at runtime) |
| `~/.ssa/` | Runtime data (logs, credentials, operators, protocols, backups) |
| `~/.ssa/credentials/` | **chmod 600**: vault-master.key, mariadb-ohmyserver.txt, dashboard-jwt-secret.txt |
| `~/.ssa/server.json` | Server identity (name, domain, user, purpose, etc.) |
| `~/.local/share/opencode/opencode.db` | OpenCode sessions (dashboard reads read-only) |

## Design Principles

1. **No hardcoding** — all identity via `server.json` + Env-Bridge
2. **Secrets off-repo** — master keys, DB passwords, JWT secrets in `~/.ssa/credentials/` (chmod 600)
3. **Session-bound** — dashboard, skills only active during OpenCode session
4. **Explicit over implicit** — dangerous actions require confirmation
5. **Machine-readable** — `--json` output on all scripts for automation
6. **Verification gate** — `scripts/verify-all.sh` must pass (PASS/FAIL empirical)