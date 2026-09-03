# Development Guide

How to extend OhMyServer: add skills, modify routing, run verification.

## Skill Anatomy

Every skill is a directory under `skills/` with:

```
skills/<skill-name>/
├── SKILL.md           # Required: frontmatter + behavior
├── references/        # Optional: domain-specific docs
└── commands.md        # Optional: skill-specific command extensions
```

### SKILL.md Frontmatter

```yaml
---
name: "ohmyserver-<name>"
description: "One-line purpose"
version: "1.0.0"
author: "Your Name"
triggers:
  - "#<command>"
  - "natural language trigger"
  - "another trigger"
tags:
  - category
  - category
requires:
  - dependency
---
```

**Required fields**: `name`, `description`, `version`, `triggers`

**`name` convention**: `ohmyserver-<kebab-case-name>` (matches skill directory)

**`triggers`**: Must include BOTH:
- The `#`-command (e.g., `#security scan`)
- Natural language triggers (e.g., `security`, `scan`, `sicherheit`)

### SKILL.md Body

After frontmatter, document the skill's behavior, commands, and any references.

Follow `_STANDARD.md`:
- Compact output (progressbar style)
- `#`-command system
- Smart menus via `ask`/`question`
- Operator login/session awareness
- `.ssa` logging + memory updates
- Security confirmation for dangerous changes
- Command safety (timeouts, exit codes)

### Example Minimal Skill

`skills/ohmyserver-example/SKILL.md`:

```markdown
---
name: "ohmyserver-example"
description: "Example skill template"
version: "1.0.0"
author: "You"
triggers:
  - "#example"
  - "example"
  - "beispiel"
tags:
  - utility
---

# Example Skill

## Commands

| Command | Action |
|---------|--------|
| `#example hello` | Greeting |
| `#example status` | Show status |

## Implementation

Delegates to `scripts/example.sh` (create if needed).
```

## Adding a New Skill

### 1. Create Skill Directory

```bash
mkdir -p skills/ohmyserver-<name>/references
```

### 2. Write SKILL.md

Use the template above. Ensure triggers include your `#`-command.

### 3. Register in Dispatcher Routing

Edit `skills/commands.md` — add to **Agent-Kurznamen (Routing)** table:

```markdown
| `#<command>` | ohmyserver-<name> | `#<command> <action>` · `#<command> <action>` |
```

### 4. Add Global Commands

Your skill automatically gets: `#help`, `#status`, `#memory`, `#operator` (via `_STANDARD.md`)

### 5. Create Helper Scripts (Optional)

If your skill needs CLI tools, add to `scripts/`:

```bash
# scripts/example.sh
#!/usr/bin/env bash
source scripts/server-config.sh
# ... implementation
```

Make executable: `chmod +x scripts/example.sh`

### 6. Add References (Optional)

Domain-specific docs in `skills/ohmyserver-<name>/references/`:
- `cheatsheet.md`
- `best-practices.md`
- `protocol.md`

### 7. Test

```bash
# In OpenCode with OhMyServer loaded:
#example hello
#example status
#help          # Should show your skill
#status all    # Should include your skill
```

### 8. Run Verification Gate

```bash
./scripts/verify-all.sh
```

Must pass (PASS on all checks) before considering skill complete.

## Routing & Dispatcher

### Command Routing (`skills/commands.md`)

Central registry mapping `#<agent>` → skill. Two tables:

1. **Agent-Kurznamen (Routing)** — maps `#<command>` prefix to skill name
2. **Global Standard-Commands** — `#help`, `#status`, `#memory`, `#operator` in every skill

### Dispatcher Skill (`skills/dispatcher/`)

For complex multi-skill tasks, the dispatcher orchestrates:
- Reads `commands.md` routing table
- Spawns parallel background subagents (6-point prompt structure)
- Consolidates results
- Template: `dispatcher/references/delegations-template.md`

### Adding a Subagent Delegation

In your skill, delegate to dispatcher:

```markdown
# In your skill's behavior:
"For complex tasks, use #dispatcher route <request>"

# Dispatcher will parse and route to appropriate skills
```

## Verification Gate (`scripts/verify-all.sh`)

**Mandatory** for all changes. Empirical verification (PASS/FAIL), not linting.

### What It Checks

| Check | Description |
|-------|-------------|
| Skill structure | All skills have SKILL.md with required frontmatter |
| Trigger uniqueness | No duplicate `#`-commands across skills |
| Routing consistency | `commands.md` entries match actual skill directories |
| Script executability | All `scripts/*.sh` are executable, have shebang |
| Config loading | `server-config.sh` loads `server.json` without error |
| Vault operation | `vault.sh list` works (if DB configured) |
| Dashboard health | `/api/health` returns 200 (if dashboard running) |
| Memory system | `memory-query.sh` returns valid output |
| Security scan | `security-scan.sh` completes without critical findings |

### Running

```bash
# Full verification (all checks)
./scripts/verify-all.sh

# Quick mode (subset)
./scripts/verify-all.sh --quick

# JSON output for CI
./scripts/verify-all.sh --json
```

### Exit Codes

- `0` = PASS (all checks passed)
- `1` = FAIL (one or more checks failed)
- `2` = ERROR (script error)

### Adding Custom Verification

Add checks to `verify-all.sh` or create skill-specific verification in `skills/verify/references/verification-checklist.md`.

## Conventions Checklist

Before submitting a new skill or change:

- [ ] Skill directory under `skills/ohmyserver-<name>/`
- [ ] `SKILL.md` with valid frontmatter (name, description, version, triggers)
- [ ] Triggers include both `#`-command AND natural language
- [ ] Follows `_STANDARD.md` (compact output, `#`-commands, ask menus, operator session, `.ssa` logging, security prompts, command safety)
- [ ] Registered in `skills/commands.md` routing table
- [ ] Helper scripts in `scripts/` (executable, shebang, source `server-config.sh`)
- [ ] References in `skills/ohmyserver-<name>/references/` (if needed)
- [ ] `verify-all.sh` passes
- [ ] No hardcoded values (use `server.json` via `server-config.sh`)
- [ ] No secrets in code (use vault / `~/.ssa/credentials/`)
- [ ] Documentation updated (this file, ARCHITECTURE.md if structural)

## Testing Locally

### With Local Source Install

```bash
# From OhMyServer repo root
SKILLS_SRC=/path/to/ohmyserver-repo ./install.sh
```

### With OpenCode Direct

```bash
# In OpenCode, load skill directly:
Lade den ohmyserver-<name> Skill
```

### Script Testing

```bash
# Test script in isolation
cd /path/to/ohmyserver-repo
source scripts/server-config.sh
./scripts/<script>.sh --help
./scripts/<script>.sh --dry-run
./scripts/<script>.sh --json
```

## Updating Existing Skills

1. Modify `SKILL.md` and/or references
2. Update `commands.md` if triggers changed
3. Run `verify-all.sh`
4. Test in OpenCode: `#help`, `#<command>`, `#status`

## Removing a Skill

1. Remove `skills/ohmyserver-<name>/`
2. Remove entry from `skills/commands.md`
3. Remove any dedicated scripts in `scripts/`
4. Run `verify-all.sh`

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) — system overview
- [INSTALL.md](INSTALL.md) — local source install for development
- `_STANDARD.md` — shared standards (in skills/)
- `commands.md` — command routing (in skills/)
- `scripts/verify-all.sh` — verification gate