# Installation & Onboarding

This guide covers installing OhMyServer as an OpenCode addon, the interactive onboarding flow, all configuration options, and the upgrade path.

## One-Liner Install

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/ohmyserver/main/install.sh | bash
```

The installer (`install.sh`) is the entrypoint. It will be superseded by `scripts/ohmyserver-init.sh` for interactive onboarding (being built in parallel).

## What the Installer Does

1. **Checks prerequisites**: `git`, `curl`, `bash`
2. **Installs/verifies OpenCode**: official script → npm → brew (smart fallback)
3. **Interactive model selection**: free models vs. existing API accounts/tokens
4. **Copies skills** to `~/.config/opencode/skills/ohmyserver/`
5. **Creates runtime structure** under `~/.ssa/`:
   ```
   ~/.ssa/
   ├── backups/
   ├── credentials/          # chmod 600, vault master-key, DB creds
   ├── design/
   ├── logs/
   ├── operators/            # operator profiles + memory.md
   ├── protocols/            # audit logs
   ├── reports/
   └── dashboard/triggers/   # skill trigger queue for dashboard
   ```
6. **Optionally provisions MariaDB** (`WITH_DB=1`): database `ohmyserver`, user `ohmyserver`, credentials stored in `~/.ssa/credentials/mariadb-ohmyserver.txt` (chmod 600)

## Configuration Options

All options are environment variables. Set them before running the installer.

| Variable | Default | Description |
|----------|---------|-------------|
| `WITH_DB` | `0` | Set to `1` to provision MariaDB database + user |
| `SKILLS_SRC` | (empty) | Local path or tarball URL to install from (development) |
| `INSTALL_DIR` | `~/.config/opencode/skills/ohmyserver` | Target directory for skills |
| `SSA_DIR` | `~/.ssa` | Runtime data directory |
| `REPO_OWNER` | (empty) | GitHub owner for git-clone-based install/update |
| `REPO_NAME` | `ohmyserver` | Repository name |
| `REPO_BRANCH` | `main` | Branch to clone |
| `MARIADB_PW` | (auto-generated) | Password for MariaDB `ohmyserver` user |

### Examples

```bash
# With MariaDB + custom install dir
WITH_DB=1 INSTALL_DIR=/opt/ohmyserver curl -fsSL https://raw.githubusercontent.com/<owner>/ohmyserver/main/install.sh | bash

# From local source (development)
SKILLS_SRC=/home/<user>/dev/ohmyserver ./install.sh

# Non-interactive (CI/CD)
WITH_DB=1 REPO_OWNER=<owner> ./install.sh
```

## Interactive Onboarding (`ohmyserver-init.sh`)

> **Note**: `scripts/ohmyserver-init.sh` is being built in parallel. It will replace the inline onboarding in `install.sh` with a dedicated, reusable script.

Planned features:
- Interactive wizard for server identity (`server.json`): name, domain, purpose, admin contact
- Guided OpenCode model/account setup
- Optional MariaDB provisioning with secure password generation
- Vault master-key generation (off-repo, `~/.ssa/credentials/vault-master.key`, chmod 600)
- Dashboard JWT secret generation (`~/.ssa/credentials/dashboard-jwt-secret.txt`, chmod 600)
- Operator account creation (stored in MariaDB, bcrypt-hashed)
- Writes `~/.ssa/server.json` — the single source of truth for server identity

### `server.json` Schema

Managed by `scripts/server-config.sh` (loads + exports `OMS_*` env vars):

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

Usage:
```bash
# Load config + export env vars
source scripts/server-config.sh

# Or use the helper
cfg server_name   # → prints value
```

## Post-Install

1. **Restart OpenCode** to load the new skills
2. **First run**: OpenCode will prompt for operator name (stored in `~/.ssa/operators/active-operator.md`)
3. **Run `#help`** to see all available `#`-commands
4. **Run `#status all`** for a compact system overview

## Upgrade Path

### Via Git (Recommended)

```bash
cd /path/to/ohmyserver-repo
git pull
./install.sh
```

The installer is idempotent — it updates skills in place, preserves `~/.ssa/` runtime data, and re-runs MariaDB provisioning only if `WITH_DB=1` and DB doesn't exist.

### Via Re-Run Installer

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/ohmyserver/main/install.sh | bash
```

Same behavior: skills updated, runtime preserved.

### Breaking Changes

If a version introduces breaking changes (e.g., `server.json` schema, DB migrations), the installer will:
1. Detect existing installation
2. Prompt for migration confirmation
3. Run migration scripts (via `scripts/migrate-*.sh` if they exist)
4. Update `server.json` `updated_iso` timestamp

## Uninstall

> **Note**: `scripts/uninstall.sh` is being built in parallel.

Planned clean removal:
- Removes `~/.config/opencode/skills/ohmyserver/`
- Optionally removes `~/.ssa/` (with confirmation, preserves backups by default)
- Drops MariaDB `ohmyserver` database/user (with confirmation)
- Removes any cron jobs added by `scripts/cron-scheduler.sh`

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| OpenCode not found after install | Restart shell, verify `opencode --version` |
| Skills not loading | Check `~/.config/opencode/skills/ohmyserver/` exists |
| MariaDB connection failed | Verify `~/.ssa/credentials/mariadb-ohmyserver.txt` exists, chmod 600 |
| Dashboard won't start | Check `DASH_JWT_SECRET` in `~/.ssa/credentials/dashboard-jwt-secret.txt` |

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) — how the pieces fit together
- [SECURITY.md](SECURITY.md) — secrets handling, credentials, vault
- [DASHBOARD.md](DASHBOARD.md) — web dashboard deployment