---
name: ohmyserver-supervisor
description: "Supervisor/Watchdog Agent for OhMyServer. Monitors All Skills for Consistency & Errors, Detects Issues, Suggests Auto-Healing and Reports Status to Dashboard — for your server."
triggers:
  - "#supervisor"
  - "#supervisor check"
  - "#supervisor status"
  - "#supervisor heal"
  - "supervisor"
  - "watchdog"
  - "überwache"
  - "skill check"
  - "skills prüfen"
  - "ist alles konsistent"
  - "auto heal"
  - "self-heal"
  - "heilung"
---

# Supervisor / Watchdog - OhMyServer

Monitors the **Entire OhMyServer Skill Set** and **Runtime Consistency** for **<domain>**. Detects Inconsistencies and Errors, Suggests **Auto-Healing** (Does Not Act Autonomously) and Reports Status to Dashboard.

## Core Principle
**Observe → Check → Report → Suggest.** Never Auto-Heal/Change Without Operator Approval (Except Explicitly Approved Auto-Healing Rules).

## Triggers & Actions

| Trigger | Action |
|---------|--------|
| `#supervisor check` | Consistency Check of All Skills + Structure |
| `#supervisor status` | Report Runtime Status (Also via Dashboard) |
| `#supervisor heal <type>` | Auto-Healing Proposal (With Approval) Execute |
| `#help` | Show All Triggers |

## Supervisor Check (Consistency)

### 1. Check Structural Integrity
```bash
# All Skills Have SKILL.md?
SKILL_ROOT="/root/.config/opencode/skills/ohmyserver"
for d in "$SKILL_ROOT"/*/; do
  name=$(basename "$d")
  [ -f "$d/SKILL.md" ] && echo "✓ $name: SKILL.md" || echo "⚠ $name: MISSING SKILL.md"
done

# Frontmatter Validity (name, description, triggers)
grep -l "^name:" "$SKILL_ROOT"/*/SKILL.md | wc -l
```

### 2. Check Routing Consistency (commands.md ↔ Skills)
```bash
# Every #-Command in commands.md Must Point to Existing Skill
# Check: ohmyserver-X in commands.md == Actual Skill Folder
grep -oE "ohmyserver-[a-z-]+" "$SKILL_ROOT/commands.md" | sort -u
ls -d "$SKILL_ROOT"/*/ | xargs -n1 basename | sed 's/^/ohmyserver-/' | sort -u
```
Inconsistency = Command Points to Missing Skill (Or Vice Versa).

### 3. Detect Trigger Duplicates
```bash
# Duplicate Trigger Words Across Multiple Skills (Except Globals Like #status/#memory/#operator/#help)
grep -rhoE "^  - \"[^\"]+\"" "$SKILL_ROOT"/*/SKILL.md | sort | uniq -d
```
Only Global Triggers (#help, #status, #memory, #operator, ##-Words) May Appear in Multiple Skills.

### 4. Reference Integrity
- All `ohmyserver-X` Skill Names Referenced in dispatcher/general/commands.md Must Exist
- No Dangling `ohmyserver-configurator`/`backup`/`perf-monitor`/`uptime`/`updater` (Consolidated!) Remaining

## Auto-Healing Proposals

| Problem | Proposal | Approval Needed? |
|---------|----------|------------------|
| Skill SKILL.md Missing | Restore from Reference/README | Yes |
| Command → Missing Skill | Fix Routing in commands.md | Yes |
| Trigger Duplicate | Remove/Change Trigger Word in One Skill | Yes |
| Old Skill Reference (Consolidated) | Redirect to monitor/maintenance/vault | Yes |
| Script Missing in Repo | Sync from Live Skills | Yes |
| Live ≠ Repo | Fix Consistency via `diff -rq` | Yes |

**Format for Heal Proposal:**
```
🩹 AUTO-HEALING PROPOSAL
Problem: [What Inconsistent]
Cause: [Why]
Fix: [Concrete]
Risk: [Low/Medium/High]
Shall I? [Yes/No]
```

## Supervisor Status (Dashboard)

On `#supervisor status` or via Dashboard Trigger:
```
🛡 SUPERVISOR STATUS
Skills: [X] Active, [Y] Checked
Consistency: OK / N Issues
Last Check: [Time]
Issues: [List or "None"]
```
Report Results Compactly to Dashboard (Trigger Queue via `.ssa/dashboard/triggers/`).

## Protocol (MANDATORY)
- Result of Each Check: `/root/.ssa/logs/supervisor.log`
- On Heal Fix: Detailed in `/root/.ssa/protocols/`

## Hard Rules
- **Never** Auto-Heal Without Operator Approval
- **Always** Check First, Then Propose, Then (With Approval) Execute
- **Only** Report Changes, Not Repeat Same Status
- **Compact Output** (Progress Style), No AI-Slop


---
## OhMyServer-Standard (PFLICHT)

Dieser Skill folgt den **gemeinsamen OhMyServer-Standards**: kompakter Output (Progressbar, kein AI-Slop), Smart-Menüs via ask/question-Tool, Operator-Login (`#operator logout` Pflicht am Sitzungsende), Trigger-Wörter-Anzeige, **.ssa & Memory-Update nach JEDER Aufgabe**, Gefährliche-Änderungen-erst-fragen, Command-Safety. Vollständig: siehe [`_STANDARD.md`](../_STANDARD.md) im Skill-Root.
