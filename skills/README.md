# OhMyServer - Skillset für talbergh.art

Übersicht aller Skills für den Server **talbergh.art** (User: talbergh).

> **Gemeinsame Standards** für alle Skills: siehe [`_STANDARD.md`](_STANDARD.md)
> (kompakter Output, ask-Menüs, Operator-Login, .ssa-Pflicht, Command-Safety).

## Skills

### 0. Operator & Session (OP)
**Pfad**: `operator/SKILL.md`
**Trigger**: #operator login, #operator logout, #operator status, #help, session
**Features**:
- Operator-Login/Logout mit Trigger-Wörtern
- Speichert Operator in `/root/.ssa/operators/<name>.md` + `active-operator.md`
- `#operator logout` Pflicht am Sitzungsende
- Bei erster Nachricht: nach Operator-Name fragen

### 0b. Memory & Todos (MEM)
**Pfad**: `memory/SKILL.md`
**Trigger**: `#memory`, `#todo`, memory, merke dir, todo, was ist offen
**Features**:
- Zentrale Memory-Verwaltung (`/root/.ssa/operators/memory.md`)
- Todo-Liste (`/root/.omo/todos.md`) mit Prioritäten
- Smart-Menüs via ask/question-Tool (wenig tippen)

### 0c. Optics & Design (QD)
**Pfad**: `design/SKILL.md`
**Trigger**: `#design`, `#design plan`, `#design preview`, `#design wireframe`, design, layout, wireframe, mockup, prototyp
**Features**:
- Zentrale + projektabhängige Design-Guidelines
- Interaktiver QD Planning Server (Live-Preview, Wireframe, Frage-Panel, Freigabe)
- Firewall-smart: localhost-first, Temp-Regeln nur mit Security-Freigabe + Memory + Rollback
- OSS-Basen: Excalidraw-Embed (Default), Penpot self-hosted (Option)

### 0c. Code-Pipeline (Planner → Writer → Verifier)
**Pfad**: `code-planner/`, `code-writer/`, `code-verifier/` (je `SKILL.md`)
**Trigger**: `#code plan` / `#code write` / `#code verify`, implementiere, teste
**Features**:
- **code-planner**: Planung, API/Docs-Research, ask-getriebene Anforderungsanalyse (5-15 Fragen)
- **code-writer**: Implementierung in JS/TS, Bash, C#, C++, Rust, HTML/CSS; Konventionen + Subagent-Workflow
- **code-verifier**: Detaillierte empirische Tests & Verifikation (PASS/FAIL)

### 0. Edit-Agent (EA) — Skill-Manager

**Pfad**: `edit-agent/SKILL.md`
**Trigger**: `#edit_agent#`
**Features**:
- Modus betreten/verlassen (Toggle)
- `ask`-Tool-Menü beim Reinkommen
- Self-Reload nach Änderungen
- Fähigkeit: Skills anpassen/erweitern, Guidelines/Memory ändern

### 1. General Agent (GA)
**Pfad**: `general/SKILL.md`
**Trigger**: Generelle Fragen, Status-Abfragen
**Features**:
- Token-optimiert (max 3-4 Sätze)
- Kein AI-Slop
- Quellenangaben
- Leitet an andere Skille weiter wenn nötig

### 2. Server Security Agent (SSA)
**Pfad**: `security/SKILL.md`
**Trigger**: security, sicherheit, ssh, firewall, fail2ban, hack, verdächtig
**Features**:
- Regelmäßige Security-Checks
- Web-Research bei neuen Bedrohungen
- Gefährliche Änderungen: IMMER User fragen
- Speichert Protokolle in `/root/.ssa/`

### 3. Maintenance & Config Agent (MA)
**Pfad**: `maintenance/SKILL.md` (konsolidiert: `configurator` + `backup`)
**Trigger**: `#maintenance`, `#backup`, `#config`, backup, restore, installiere, aufräumen, cleanup, docker, nginx, speicherplatz
**Features**:
- Backups (Configs, DBs, Websites) + Restore nur mit User-Freigabe
- Saubere Installationen + System-Management
- Docker-, nginx-, systemd-, Speicher-Management
- Cleanup-Routinen, Backup-Verifikation
- Destruktive Aktionen nur mit User-Einwilligung

### 4. Monitor & Wartung Agent (MON)
**Pfad**: `monitor/SKILL.md` (konsolidiert: `perf-monitor` + `uptime` + `updater`)
**Trigger**: `#monitor`, `#health`, `#uptime`, `#update`, performance, cpu, ram, dienste, services, ausfall, update, kernel
**Features**:
- CPU/RAM/Disk/Netzwerk-Checks (Health & Performance)
- Uptime & Service-Monitoring (MELDET zuerst, kein eigenmächtiges Heilen)
- Update- & Patching-Priorisierung (Sicherheit zuerst)
- Kernel-Reboot-Frage, kein `apt upgrade -y` ohne Freigabe

### 5. Vault / Secrets-Agent (VA)
**Pfad**: `vault/SKILL.md`
**Trigger**: `#vault`, vault, passwort manager, secret, api key, zugangsdaten, token speichern
**Features**:
- Verwaltet Passwörter, Tokens, API-Keys verschlüsselt (MariaDB AES)
- Master-Key off-repo (`~/.ssa/credentials/vault-master.key`, chmod 600)
- `#vault list` zeigt nie Werte; `get` nur an berechtigten Operator
- `rotate` (Master-Key-Neuverschlüsselung) nur mit Freigabe
- Dashboard-steuerbar (JWT-geschützt)

### 6. Supervisor / Watchdog (SUP)
**Pfad**: `supervisor/SKILL.md`
**Trigger**: `#supervisor`, `#supervisor check`, `#supervisor status`, `#supervisor heal`, watchdog, überwache, skill check, auto heal
**Features**:
- Konsistenz-Check aller Skills (Struktur, Routing, Trigger-Duplikate, Referenzen)
- Erkennt Inkonsistenzen → schlägt Auto-Healing vor (kein eigenmächtiges Heilen)
- Heal nur mit Operator-Freigabe
- Meldet Status ans Dashboard (`#supervisor status`)

### 8. Notification & Alert Agent (NA)
**Pfad**: `notification/SKILL.md`
**Trigger**: alert, benachrichtigung, notify, meldung
**Features**:
- Zentrale Alert-Weiterleitung
- Prioritäts-Level (INFO→NOTFALL)
- Koordiniert alle anderen Skills
- Optional push (ntfy/Telegram/eMail)

### 9. Data & Storage Agent (DSA)
**Pfad**: `database/SKILL.md`
**Trigger**: datenbank, database, sqlite, mariadb, mysql, postgres, sql, storage, speicher
**Features**:
- Verwaltet SQLite, MariaDB, MySQL, PostgreSQL
- Backup & Restore aller DB-Typen
- Performance-Optimierung (Indexe, Tuning)
- Storage-Management (Disk, LVM, SMART, RAID)
- Gefährliche Aktionen (DROP/DELETE) nur mit Freigabe

### 10. Smart Status / Triggers
**Pfad**: `status/SKILL.md`
**Trigger**: status, wie läuft, was läuft, alles ok, report, notification, alerts
**Features**:
- Kompakter Gesamt-Status bei Status-Frage
- Nutzt `scripts/status.sh`
- Automatische Weiterleitung an passende Skills
- Hervorhebung von Warnungen/Problemen

### 11. Dispatcher / Orchestrator
**Pfad**: `dispatcher/SKILL.md`
**Trigger**: dispatcher, orchestrieren, mehrere dinge, subagent, delegieren
**Features**:
- Skill/Subagent-Zuordnung (Routing-Tabelle)
- Parallele Delegation (background tasks)
- 6-Punkte-Delegations-Prompt-Struktur
- Konsolidierung mehrerer Ergebnisse

### 12. Optics & Design (QD)
**Pfad**: `design/SKILL.md`
**Trigger**: `#design`, `#design plan`, `#design preview`, `#design wireframe`, design, wireframe, mockup
**Features**:
- QD Planning Server (interaktive Preview + Wireframe + Freigabe)
- Guideline-System (Main + Projekt + Memory)
- Anti-Slop-Checkliste + Web-Research

### 12. Command Safety & Robustness
**Pfad**: `command-safety/SKILL.md`
**Trigger**: command, hängt, stuck, timeout, command endet nicht
**Features**:
- Timeout-Regeln für alle Commands
- Interaktive CLIs vermeiden (non-interaktiv)
- Abschluss-Verifikation (Exit-Codes)
- Stuck-Detection & graceful shutdown

### 13. User & Permission Agent (UPA)
**Pfad**: `users/SKILL.md`
**Trigger**: user, benutzer, permission, rechte, sudo, passwort, zugriff
**Features**:
- Verwaltet User-Accounts & Rechte sicher
- Pflegt `/root/.ssa/protocols/users.md` (Wahrheitsquelle)
- SSH-Keys, sudo-Rechte, Passwort-Sicherheit
- Gefährliche Aktionen (userdel/sudo) nur mit Freigabe

### 14. Verify & Quality Agent (VQA)
**Pfad**: `verify/SKILL.md`
**Trigger**: verifizieren, hat es geklappt, funktioniert das, qa
**Features**:
- Verifiziert nach JEDER Aufgabe (empirisch, nicht raten)
- Prüft Funktionalität, Fehlerfreiheit, Exaktheit
- Domänen-Checklisten (Service, DB, Backup, User, Firewall)
- Bei Fehlschlag: zurückleiten + erneut verifizieren

## Scripts

| Script | Zweck |
|--------|-------|
| `scripts/status.sh` | **Kompakter Gesamt-Status** (`--json` für maschinell) |
| `scripts/integration.sh` | **Master-Report** – alle Checks konsolidiert (`--quick`/`--full`/`--json`) |
| `scripts/verify-all.sh` | **VQA** – verifiziert Gesamtzustand empirisch (PASS/FAIL) |
| `scripts/security-scan.sh` | Schneller Security-Check |
| `scripts/log-scan.sh` | SSH-Failures, Auth-Fehler, Systemfehler (`--hours=N`, `--json`) |
| `scripts/ssh-audit.sh` | SSH-Härtungs-Audit vs. Best Practices (`--json`) |
| `scripts/user-scan.sh` | User/Permissions/UID0/leere Passwörter (`--json`) |
| `scripts/db-check.sh` | Findet+prüft SQLite/MariaDB/PostgreSQL (`--json`) |
| `scripts/update-scan.sh` | Updates + Sicherheits-Priorisierung (`--json`) |
| `scripts/service-audit.sh` | Dienste, offene Ports, Ressourcen (`--json`) |
| `scripts/disk-report.sh` | Speicher-Analyse + Cleanup-Vorschläge (`--json`) |
| `scripts/backup.sh` | Backup ausführen |
| `scripts/backup-rotate.sh` | Alte Backups rotieren/löschen (`--dry-run` sicher) |
| `scripts/cleanup.sh` | Server aufräumen |
| `scripts/health-check.sh` | System-Gesundheits-Check |
| `scripts/cron-scheduler.sh` | Auto-Checks einrichten (`install`/`remove`/`status`) |

## Database-Referenzen (DSA)

| Datei | Inhalt |
|-------|--------|
| `database/references/sqlite.md` | SQLite-Management (Backup, WAL, VACUUM) |
| `database/references/mariadb.md` | MariaDB/MySQL (Backup, Tuning, Benutzer) |
| `database/references/postgresql.md` | PostgreSQL (Backup, VACUUM, JSON) |
| `database/references/storage.md` | Storage (Disk, LVM, SMART, RAID) |

## Ordnerstruktur

```
/root/.config/opencode/skills/ohmyserver/
├── _STANDARD.md      # Gemeinsame Standards (ALL Skills)
├── operator/         # Operator & Session Agent
│   └── SKILL.md
├── memory/           # Memory & Todos Agent
│   └── SKILL.md
├── code-planner/     # Code Planner (Agent 1)
│   └── SKILL.md
├── code-writer/      # Code Writer (Agent 2)
│   └── SKILL.md
├── code-verifier/    # Code Verifier (Agent 3)
│   └── SKILL.md
├── general/          # General Agent
│   ├── SKILL.md
│   └── references/
├── security/         # Security Agent
│   ├── SKILL.md
│   └── protocols/
├── maintenance/      # Maintenance & Config (Backup+Configurator)
│   └── SKILL.md
├── monitor/          # Monitor & Wartung (Health+Uptime+Update)
│   └── SKILL.md
├── vault/            # Vault/Secrets-Agent (verschlüsselt)
│   └── SKILL.md
├── supervisor/       # Supervisor/Watchdog (Konsistenz + Auto-Healing)
│   └── SKILL.md
├── notification/     # Notification Agent
├── database/         # Data & Storage Agent
│   └── references/    # sqlite, mariadb, postgresql, storage
├── status/           # Smart Status & Triggers
├── dispatcher/       # Orchestrator & Subagent-Routing
│   └── references/    # delegations-template.md
├── command-safety/   # Robustes Command-Handling
│   └── references/    # cheatsheet.md
├── users/            # User & Permission Agent
│   └── references/    # best-practices.md
├── verify/           # Verify & Quality Agent
│   └── references/    # verification-checklist.md
└── scripts/          # Hilfs-Scripts
```

## Nutzung

Skills werden automatisch geladen bei passenden Triggers. Manuell:
```
Lade den ohmyserver-security Skill
```

## WICHTIG

- **Security-Änderungen**: IMMER erst fragen
- **Destruktive Aktionen** (Restore, Service-Stop, Reboot): IMMER Bestätigung
- **Bei Unsicherheit**: Lieber fragen als handeln
- **Kein AI-Slop**: Antworten kurz, sachlich, mit Quellen
