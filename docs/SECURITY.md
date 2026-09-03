# Security Model

OhMyServer is designed with defense-in-depth: secrets never in repo, minimal attack surface, explicit confirmation for dangerous actions.

## Secrets Handling

### Vault Master Key (Off-Repo)

- **Location**: `~/.ssa/credentials/vault-master.key`
- **Permissions**: `chmod 600` (owner read/write only)
- **Generation**: `openssl rand -hex 32` (256-bit)
- **Usage**: AES encryption/decryption via MariaDB `AES_ENCRYPT`/`AES_DECRYPT`
- **Rotation**: `#vault rotate` or `vault.sh regenerate-master` — re-encrypts all secrets with new key (requires explicit confirmation)

> The master key **never leaves the server**. It is not in git, not in backups, not in any config file.

### Database Credentials

- **Location**: `~/.ssa/credentials/mariadb-ohmyserver.txt`
- **Permissions**: `chmod 600`
- **Format**:
  ```
  MariaDB user: ohmyserver
  host: localhost/127.0.0.1
  database: ohmyserver
  password: <generated-or-user-provided>
  ```
- **Access**: Only `vault.sh`, `dashboard/server/config.js`, and skills with explicit DB needs read this file

### Dashboard JWT Secret

- **Location**: `~/.ssa/credentials/dashboard-jwt-secret.txt`
- **Permissions**: `chmod 600`
- **Format**: `password: <base64url-secret>`
- **Fallback**: `DASH_JWT_SECRET` env var, then `insecure-dev-secret-change-me` (logs warning)
- **Rotation**: Replace file content, restart dashboard

### Operator Passwords

- Stored in MariaDB `operators.pass_hash` — **bcrypt(hash, cost=10)**
- Never logged, never in plaintext
- Dashboard login: `/api/auth/login` → returns JWT (12h expiry)
- Sessions tracked in `operator_sessions` table (token_hash = SHA256(JWT))

### Credential Directory Protection

```
~/.ssa/credentials/
├── vault-master.key           # 600 - AES master key
├── mariadb-ohmyserver.txt     # 600 - DB password
├── dashboard-jwt-secret.txt   # 600 - JWT signing key
└── ...                        # 600 - any future secrets
```

**Rule**: Every file in `~/.ssa/credentials/` **MUST** be `chmod 600`. The installer and `ohmyserver-init.sh` enforce this.

## Safe-Change Policy

### Dangerous Actions Require Explicit Confirmation

Any operation that can cause data loss, service disruption, or security changes **MUST** prompt the operator:

```
⚠️ SICHERHEITSÄNDERUNG
Was: <concrete description>
Risiko: <what could go wrong>
Empfehlung: <recommendation>
Soll ich fortfahren? [ja/nein]
```

### Categories Requiring Confirmation

| Category | Examples |
|----------|----------|
| Security config | Firewall rules, SSH hardening, fail2ban changes |
| Service management | Stop/start/restart systemd services, reboot |
| Database | DROP TABLE, DELETE without WHERE, schema migrations |
| User/permissions | `userdel`, `usermod -G`, sudoers changes, SSH keys |
| Secrets | Vault master-key rotation, credential deletion |
| System config | `/etc/` modifications, kernel parameters, disk operations |

### Skills Enforce This

- `ohmyserver-security`: All config changes prompt
- `ohmyserver-maintenance`: Backup restore, cleanup, service ops prompt
- `ohmyserver-users`: User deletion, sudo changes prompt
- `ohmyserver-vault`: Master-key rotation, secret deletion prompt
- `ohmyserver-supervisor`: Auto-heal proposals require approval

### Command Safety

All scripts and skills follow `command-safety` standards:
- `timeout` on every non-instant command (default 30s, configurable)
- No interactive CLIs left open (mysql, psql, vim → non-interactive flags)
- Exit codes checked; non-zero = failure, logged + reported
- Stuck detection: if child process exceeds timeout, SIGTERM → SIGKILL

## Dashboard Security

### Session-Bound Architecture

- Dashboard runs **only while OpenCode/OhMyServer session is active**
- No systemd service, no daemon, no persistent listener
- Started by operator via `dashboard-ctl.sh start` (or skill trigger)
- Stops automatically on OpenCode exit / session end

### Authentication

- **Operator login**: name + password → bcrypt verify → JWT (12h)
- **JWT validation**: HS256 with secret from `~/.ssa/credentials/dashboard-jwt-secret.txt`
- **Token hash stored**: `operator_sessions.token_hash = SHA256(JWT)` for logout/revocation
- **All API endpoints** (except `/api/health`) require `Authorization: Bearer <JWT>`

### Skill Trigger Whitelist

Only these skills can be triggered from the dashboard UI:
```
status, maintenance, monitor, vault, verify, security, supervisor
```

**Blocked**: `operator`, `memory`, `dispatcher`, `code-planner`, `code-writer`, `code-verifier`, `edit-agent`, `design`, `users`, `database`, `backup`, `config`, `update`, `notify`

Rationale: Dashboard is for **observability + safe actions**. Complex/stateful skills require interactive OpenCode session.

### Network Exposure

- **Default**: Binds to `127.0.0.1:8787` (localhost only)
- **Public access**: Only via nginx reverse proxy + TLS (see [DASHBOARD.md](DASHBOARD.md))
- **WebSocket**: Same origin policy, authenticated via JWT on connection upgrade

### OpenCode Database Access

- Dashboard opens `~/.local/share/opencode/opencode.db` **read-only** (`readonly: true` in better-sqlite3)
- Queries only `session`, `message`, `part`, `todo` tables
- No write access, no schema modification

## Uninstall Security

`scripts/uninstall.sh` (being built in parallel) will:

1. **Confirm** before any destructive action
2. **Preserve backups** by default (`~/.ssa/backups/`)
3. **Optionally remove** `~/.ssa/` (with explicit `--purge` flag)
4. **Optionally drop** MariaDB `ohmyserver` database/user (with confirmation)
5. **Remove** cron jobs added by `cron-scheduler.sh`
6. **Clean up** `~/.config/opencode/skills/ohmyserver/`

## Threat Model

| Threat | Mitigation |
|--------|------------|
| Repo leak | No secrets in git; `.gitignore` excludes `~/.ssa/credentials/` |
| Credential theft | All secrets chmod 600; master key off-repo; DB passwords hashed |
| Dashboard exposure | Localhost-only by default; nginx+TLS for public; JWT auth; skill whitelist |
| SQL injection | Parameterized queries (mariadb.js prepared statements) |
| XSS/CSRF | No user-generated HTML; API-only; JWT in header (not cookie) |
| Privilege escalation | Skills run as operator user; sudo only via explicit `#config` prompts |
| Supply chain | `verify-all.sh` empirical gate; minimal deps; pinned versions in dashboard `package-lock.json` |

## Audit Checklist

Run periodically (or via `#supervisor check`):

- [ ] `~/.ssa/credentials/*` all `chmod 600`
- [ ] `vault-master.key` not in any backup/git
- [ ] MariaDB `ohmyserver` user has only `localhost`/`127.0.0.1` access
- [ ] Dashboard not exposed without nginx+TLS
- [ ] JWT secret rotated from default (`insecure-dev-secret-change-me`)
- [ ] Operator passwords bcrypt-hashed in DB
- [ ] `verify-all.sh` passes (PASS on all checks)
- [ ] No world-writable files in `~/.ssa/`

## Incident Response

1. **Suspected credential compromise**:
   - Rotate vault master key: `#vault rotate`
   - Rotate DB password: update `mariadb-ohmyserver.txt` + MariaDB user
   - Rotate JWT secret: replace `dashboard-jwt-secret.txt`, restart dashboard
   - Revoke all operator sessions: `DELETE FROM operator_sessions;`

2. **Suspected dashboard breach**:
   - Stop dashboard: `dashboard-ctl.sh stop`
   - Check `~/.ssa/logs/dashboard.log` for anomalous triggers
   - Rotate JWT secret + DB password

3. **Full compromise**:
   - Follow incident response plan in `~/.ssa/protocols/incident-response.md` (create one per server)

## See Also

- [INSTALL.md](INSTALL.md) — credential setup during install
- [ARCHITECTURE.md](ARCHITECTURE.md) — vault, dashboard, supervisor architecture
- [DASHBOARD.md](DASHBOARD.md) — dashboard deployment + nginx TLS
- [DEVELOPMENT.md](DEVELOPMENT.md) — adding skills securely