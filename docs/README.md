# OhMyServer Documentation

Welcome to the OhMyServer documentation. This is the central index linking all documentation files.

## Documentation Index

| Document | Description |
|----------|-------------|
| [INSTALL.md](INSTALL.md) | Installation, onboarding, options table, and upgrade path |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture: skills, dispatcher, scripts, dashboard, memory, vault, supervisor, server-config layer |
| [SECURITY.md](SECURITY.md) | Secrets handling, vault master-key, credential permissions, dashboard JWT, safe-change policy, uninstall |
| [DASHBOARD.md](DASHBOARD.md) | Web dashboard: session-bound, operator login, skill-trigger whitelist, JWT, nginx+TLS deployment |
| [DEVELOPMENT.md](DEVELOPMENT.md) | Extending OhMyServer: skill anatomy, adding new skills, routing, verification gate |

## Quick Links

- **Main README**: [../README.md](../README.md) — project overview, one-liner install, quickstart
- **Install Script**: [../install.sh](../install.sh) — reference implementation of `ohmyserver-init.sh`
- **Server Config**: [../scripts/server-config.sh](../scripts/server-config.sh) — loads `server.json` + exports env vars
- **Uninstall Script**: [../scripts/uninstall.sh](../scripts/uninstall.sh) — clean removal (being built in parallel)

## Project Structure Overview

```
ohmyserver/
├── install.sh              # One-liner installer (entrypoint)
├── ohmyserver.json         # Addon metadata manifest
├── README.md               # Top-level overview (this repo)
├── scripts/                # Executable server/status/audit scripts
│   ├── ohmyserver-init.sh  # Interactive onboarding (planned)
│   ├── server-config.sh    # Loads server.json + exports OMS_* env
│   ├── uninstall.sh        # Clean removal (planned)
│   ├── status.sh           # Compact status output
│   ├── verify-all.sh       # Empirical verification gate
│   ├── integration.sh      # Master report (all checks)
│   ├── vault.sh            # Encrypted secrets (MariaDB AES)
│   ├── memory-query.sh     # Memory system queries
│   └── ...                 # 20+ audit/maintenance scripts
├── skills/                 # OpenCode skill definitions
│   ├── _STANDARD.md        # Shared standards (ALL skills)
│   ├── commands.md         # #command-system reference
│   ├── dispatcher/         # Orchestrator & subagent routing
│   ├── operator/           # Operator & session management
│   ├── memory/             # Memory & todos
│   ├── code-planner/       # Code planning (asks 5-15 questions)
│   ├── code-writer/        # Code implementation
│   ├── code-verifier/      # Empirical verification (PASS/FAIL)
│   ├── security/           # Security checks + web research
│   ├── maintenance/        # Backup, install, cleanup
│   ├── monitor/            # Health, uptime, updates
│   ├── vault/              # Encrypted secrets (AES, master-key off-repo)
│   ├── supervisor/         # Consistency checks + auto-heal proposals
│   ├── notification/       # Central alert routing
│   ├── database/           # SQLite, MariaDB, MySQL, PostgreSQL
│   ├── status/             # Smart triggers + compact status
│   ├── command-safety/     # Timeout, exit-codes, stuck detection
│   ├── users/              # User accounts & permissions
│   ├── verify/             # Verify & Quality Agent
│   ├── design/             # Optics & Design (QD Planning Server)
│   └── edit-agent/         # Skill self-modification (toggle)
├── dashboard/              # Web dashboard (Node.js + Express + WS)
│   ├── server/             # Backend: auth, sessions, memory, skills
│   │   ├── index.js        # HTTP + WebSocket server
│   │   ├── config.js       # Env + credential loading
│   │   └── schema.sql      # MariaDB tables (operators, sessions, memory, secrets)
│   ├── public/             # Frontend assets
│   ├── dashboard-ctl.sh    # Start/stop/status control
│   └── deploy/             # Nginx + TLS reference configs
└── docs/                   # This documentation
```

## Conventions

- **Language**: All documentation is in English (project default)
- **Placeholders**: Use `<server>`, `<domain>`, `<user>`, `<owner>` instead of hardcoded values
- **Scripts referenced**: `ohmyserver-init.sh`, `server-config.sh` (server.json), `uninstall.sh` are referenced as if they exist (being built in parallel)
- **Paths**: Default install `~/.config/opencode/skills/ohmyserver/`, runtime `~/.ssa/`

## Getting Help

- Run `#help` in OpenCode after installation for command overview
- Run `#status all` for compact system status
- Check `scripts/verify-all.sh` for empirical verification of entire system