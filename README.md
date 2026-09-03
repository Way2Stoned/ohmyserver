# OhMyServer

**OhMyServer** is a modular OpenCode addon for server management. It provides a suite of specialized AI agents (skills) for security, configuration, backup, databases, monitoring, secrets management, and more — all accessible through a unified `#`-command system and an optional session-bound web dashboard.

## Features

| Feature | Description |
|---------|-------------|
| **20+ Specialized Skills** | Security, Config, Backup, DB, Design, Memory, Code Pipeline, Vault, Supervisor, Monitor, Users, Notify, Dispatcher, and more |
| **Unified `#`-Commands** | Minecraft-inspired syntax: `#security scan`, `#backup run`, `#vault list`, `#operator login <name>` |
| **On-Demand Memory** | Operator preferences + structured recall via MariaDB (FULLTEXT search, importance scoring) |
| **Encrypted Vault** | AES-encrypted secrets in MariaDB, master key **off-repo** (`~/.ssa/credentials/vault-master.key`, chmod 600) |
| **Session-Bound Dashboard** | Web UI (Node.js + Express + WS) — runs only during OpenCode session, JWT auth, skill-trigger whitelist |
| **Supervisor/Watchdog** | Consistency checks across all skills, proposes auto-heal (requires approval) |
| **Server Config Layer** | `server.json` + Env-Bridge (`server-config.sh`) replaces hardcoding — portable across servers |
| **Verification Gate** | `verify-all.sh` — empirical PASS/FAIL checks for entire system |
| **One-Liner Install** | Smart OpenCode install, interactive onboarding, optional MariaDB provisioning |

## Quickstart

### One-Liner Install

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/ohmyserver/main/install.sh | bash
```

### With Options

```bash
# Provision MariaDB (for dashboard, memory, vault)
WITH_DB=1 curl -fsSL https://raw.githubusercontent.com/<owner>/ohmyserver/main/install.sh | bash

# Install from local source (development)
SKILLS_SRC=/path/to/ohmyserver-repo ./install.sh

# Custom directories
INSTALL_DIR=/opt/ohmyserver SSA_DIR=/data/ssa ./install.sh
```

### Post-Install

1. **Restart OpenCode** to load skills
2. **First run**: Enter operator name when prompted
3. **Run `#help`** for command overview
4. **Run `#status all`** for compact system status

## Documentation

| Document | Description |
|----------|-------------|
| [docs/INSTALL.md](docs/INSTALL.md) | Installation, onboarding, options table, upgrade path |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System architecture: skills, dispatcher, scripts, dashboard, memory, vault, supervisor, server-config |
| [docs/SECURITY.md](docs/SECURITY.md) | Secrets handling, vault master-key, credential permissions, dashboard JWT, safe-change policy, uninstall |
| [docs/DASHBOARD.md](docs/DASHBOARD.md) | Web dashboard: session-bound, operator login, skill-trigger whitelist, JWT, nginx+TLS deployment |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Extending OhMyServer: skill anatomy, adding skills, routing, verification gate |

## Project Layout

```
ohmyserver/
├── install.sh              # One-liner installer (entrypoint)
├── ohmyserver.json         # Addon metadata manifest
├── README.md               # This file
├── scripts/                # Executable server/status/audit scripts
│   ├── ohmyserver-init.sh  # Interactive onboarding (planned)
│   ├── server-config.sh    # Loads server.json + exports OMS_* env vars
│   ├── uninstall.sh        # Clean removal (planned)
│   ├── verify-all.sh       # Empirical verification gate (PASS/FAIL)
│   ├── integration.sh      # Master report (all checks consolidated)
│   ├── vault.sh            # Encrypted secrets (MariaDB AES)
│   ├── status.sh           # Compact status output
│   └── ...                 # 20+ audit/maintenance scripts
├── skills/                 # OpenCode skill definitions
│   ├── _STANDARD.md        # Shared standards (ALL skills)
│   ├── commands.md         # #command-system reference + routing table
│   ├── dispatcher/         # Orchestrator & subagent routing
│   ├── operator/           # Operator & session management
│   ├── memory/             # Memory & todos (on-demand recall)
│   ├── code-planner/       # Code planning (asks 5-15 questions)
│   ├── code-writer/        # Code implementation (JS/TS/Bash/Rust/Go/C#/C++)
│   ├── code-verifier/      # Empirical verification (PASS/FAIL)
│   ├── security/           # Security checks + web research
│   ├── maintenance/        # Backup, install, cleanup (consolidated)
│   ├── monitor/            # Health, uptime, updates (consolidated)
│   ├── vault/              # Encrypted secrets (AES, master-key off-repo)
│   ├── supervisor/         # Consistency checks + auto-heal proposals
│   ├── notification/       # Central alert routing
│   ├── database/           # SQLite, MariaDB, MySQL, PostgreSQL + storage
│   ├── status/             # Smart triggers + compact status
│   ├── command-safety/     # Timeout, exit-codes, stuck detection
│   ├── users/              # User accounts & permissions
│   ├── verify/             # Verify & Quality Agent
│   ├── design/             # Optics & Design (QD Planning Server)
│   └── edit-agent/         # Skill self-modification (toggle)
├── dashboard/              # Web dashboard (Node.js + Express + WS)
│   ├── server/             # Backend: auth, sessions, memory, skills
│   ├── public/             # Frontend assets
│   ├── dashboard-ctl.sh    # Start/stop/status control
│   └── deploy/             # Nginx + TLS reference configs
└── docs/                   # Documentation (this directory)
```

## Runtime Structure

After install, OhMyServer creates `~/.ssa/`:

```
~/.ssa/
├── backups/                # Backup archives
├── credentials/            # chmod 600 ONLY
│   ├── vault-master.key    # AES master key (off-repo)
│   ├── mariadb-ohmyserver.txt  # DB credentials
│   └── dashboard-jwt-secret.txt # JWT signing key
├── design/                 # Design guidelines + renders
├── logs/                   # Skill + script logs
├── operators/              # Operator profiles + memory.md
├── protocols/              # Audit logs (server changes)
├── reports/                # Verification/integration reports
└── dashboard/triggers/     # Skill trigger queue (file-based)
```

Server identity stored in `~/.ssa/server.json` (managed by `server-config.sh`):

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

## Security Highlights

- **No secrets in repo** — all credentials in `~/.ssa/credentials/` (chmod 600)
- **Vault master key off-repo** — generated on install, never committed
- **Dashboard session-bound** — no daemon, stops with OpenCode session
- **JWT auth** — 12h expiry, bcrypt passwords in MariaDB
- **Skill trigger whitelist** — only safe skills triggerable from dashboard
- **Explicit confirmation** — dangerous actions always prompt operator
- **Verification gate** — `verify-all.sh` must pass (empirical, not linting)

## Requirements

- **OpenCode** (Terminal AI Agent) — installed/verified by installer
- **git, curl, bash** — for installation
- **MariaDB/MySQL** — optional (`WITH_DB=1`) for dashboard auth, memory, vault
- **Node.js 18+** — for dashboard (optional)

## Upgrade

```bash
cd /path/to/ohmyserver-repo
git pull
./install.sh
```

Idempotent: updates skills, preserves `~/.ssa/` runtime data.

## Uninstall

```bash
# Clean removal (being built in parallel)
./scripts/uninstall.sh
```

Preserves backups by default. Use `--purge` to remove `~/.ssa/`.

## License

MIT — see [ohmyserver.json](ohmyserver.json) for metadata.

## Author

**Way2Stoned** — OpenCode addon for server management.