---
name: ohmyserver-memory
description: "Memory & Todos Agent for OhMyServer. Manages Operator Memory, Todo Lists and Tasks via Trigger Words and Smart ask-Tool Menus for your server."
triggers:
  - "#memory"
  - "#todo"
  - "memory"
  - "erinnere"
  - "merke dir"
  - "vergiss nicht"
  - "todo"
  - "todos"
  - "to-do"
  - "tasks"
  - "aufgaben"
  - "offene punkte"
  - "was ist offen"
  - "checkliste"
  - "präferenzen"
  - "einstellungen merken"
---

# Memory & Todos Agent - OhMyServer

Manages the **Memory System** and **Todo/Task Lists** for **<domain>**. Uses `ask`/`question`-Tool for Smart Selection Menus, So Operator Types Minimally.

## Core Principle

**The Operator Should Type As Little As Possible.** Wherever Possible: **Smart Menus via `question`-Tool** Instead of Free Text Input. The Agent Recognizes Needs and Offers Matching Options (e.g. "What Do You Want to Do?" With Buttons Instead of Open Question).

## Files

| File | Purpose |
|------|---------|
| `/root/.ssa/operators/memory.md` | Legacy Backup (Preferences, Session Log, Open Points) — FROM NOW: MariaDB as Source of Truth |
| MariaDB `ohmyserver.memory_entries` | **Central Memory Database** (Preview + Fulltext, importance/access) |
| `/root/.ssa/operators/<name>.md` | Per-Operator Main File |
| `/root/.ssa/operators/active-operator.md` | Current Session (Who Is Logged In) |
| `.omo/todos.md` | Todo/Task List (Project-Related, in Work Directory) |

## Triggers & Actions

| Trigger | Action |
|---------|--------|
| `#memory` | Show/Manage Central Memory DB (MariaDB On-Demand) |
| `#todo` | Show/Manage Todo List |
| `remember X` -> `#memory add` | Store Something Permanently in MariaDB |
| `todo: X` | Add Task to Todo List |
| `what is open` | Name Open Points/Todos |
| `#memory search <query>` | Fulltext Search in MariaDB (No Dump!) |
| `#memory detail <id>` | Fulltext On-Demand (access_count++) |
| `#help` | Show All Triggers |

## MariaDB Memory (98% Approach) — MANDATORY

### Core Rule: NEVER Load Entire Memory Context
- **Always** Only Preview (≤150 Chars) From `memory_entries.content_preview` in Context
- **Fulltext** (`content_full`) ONLY On-Demand via `#memory detail <id>`
- **Write** Dual: MariaDB (Source of Truth) + `.ssa/operators/memory.md` (Backup/Backward Compat)

### Show Memory (`#memory`)
```
📒 MEMORY - <domain>
ID | Category | Preview
1  | preference| Output Style: Compact
2  | episodic  | Session Started...
3  | semantic  | Web Dashboard Requirement...
```

[Search] [Details] [Add] [Categorize]
```
Use `question`-Tool as Menu. **Never** Load All Fulltexts at Once.

### New Entry (`remember ...` / `#memory add`)
```
1. Detect Category: preference / episodic / semantic / procedural
2. Identify Content → Preview (≤150 Chars) + Fulltext
3. MariaDB INSERT (operator_id, category, content_preview, content_full)
4. Simultaneously: Append Line to .ssa/operators/memory.md (Backup)
5. Confirm (1 Line)
```

### Search (`#memory search <query>`)
```bash
# Use Helper Script /root/ohmyserver-repo/scripts/memory-query.sh
bash /root/ohmyserver-repo/scripts/memory-query.sh search "<query>"
# Or Direct: FULLTEXT Search in MariaDB
mariadb -u ohmyserver -h 127.0.0.1 -p"PASS" ohmyserver \
  "SELECT id, category, content_preview FROM memory_entries WHERE MATCH(content_full) AGAINST ('<query>' IN BOOLEAN MODE) ORDER BY importance_score DESC LIMIT 10;"
```

### Detail On-Demand (`#memory detail <id>`)
```bash
bash /root/ohmyserver-repo/scripts/memory-query.sh detail <id>
# → access_count++ (Track Usage for Hot/Cold), Returns content_full
```

### Smart Ask Menu (Example)
Instead of Asking "What Should I Remember?" Openly:
```markdown
question(
  Question: "What Should I Remember?",
  Options: [
    "Output Style Setting",
    "Language Stack Preference (JS/Python/etc.)",
    "Server Fact",
    "Todo/Task",
    "Other"
  ]
)
```
Operator Clicks Option → Agent Asks Targeted Only Missing Info.

## Todo Management (`#todo`)

### Show
```
✅ OPEN TODOS (3)
 1. [High] Deploy Site - nginx config
 2. [Medium] DB Backup Job
 3. [Low] Update README
```
With `question` Menu: `[Done] [Change Priority] [Delete] [Add]`

### Add (`todo: ...`)
```
todo: configure nginx for new site
→ "✅ Todo Added: configure nginx for new site (Priority: Medium)"
```

### Priorities
| Label | Meaning |
|-------|---------|
| `[High]` | Urgent, Blocks Other |
| `[Medium]` | Normal |
| `[Low]` | Whenever |

### Todo Format (in `.omo/todos.md`)
```markdown
# Todos
- [ ] [High] Deploy Site - nginx config (2026-09-03)
- [x] [Medium] DB Setup Done (2026-09-02)
```

## Smart Ask/Menu Tool (GENERAL PRINCIPLE)

**Use Everywhere a Decision/Selection Is Needed:**

### When to Use `question`-Tool
- Multiple Equivalent Options for Operator
- Priority/Category Selection
- Confirmation Before Dangerous Actions
- What Does Operator Want to Do? (Menu Instead of Open Question)

### How to Ask Well
1. **Recommended Option First** (Mark with "(Recommended)")
2. **Max 1-5 Options** Per Menu
3. **Short Description** Per Option
4. **Don't Ask More Than Needed** — Goal is FEWER Questions, Still Capture Everything

### Anti-Patterns
- ❌ Open "What Do You Want?" Questions Where Menu Suffices
- ❌ Too Many Questions (More Than 5 Per Menu)
- ❌ Options Without Description (Operator Doesn't Know What It Means)

## .ssa & Memory Update (MANDATORY)

After EVERY Memory/Todo Change:
- **Write MariaDB** (Source of Truth): `memory_entries` INSERT/UPDATE
- **Legacy Backup** Append: `.ssa/operators/memory.md` Add Line (Backward Compat)
- Update Todo File (`.omo/todos.md`)
- Add Log Line (`/root/.ssa/logs/operator.log`)

## Hard Rules
- **NEVER** Load Entire Memory Context → Only Preview (≤150 Chars) From MariaDB
- **Fulltext** (`content_full`) ONLY On-Demand via `#memory detail <id>` (access_count++)
- **Dual Write**: MariaDB + .ssa/operators/memory.md Always Parallel
- **Always** Use `question`-Tool for Menus/Options
- **Never** Discard Operator Statements Unsaved
- **Show Trigger Words** Compact
- **Compact Output** (Progress Style), No AI-Slop


---
## OhMyServer-Standard (PFLICHT)

Dieser Skill folgt den **gemeinsamen OhMyServer-Standards**: kompakter Output (Progressbar, kein AI-Slop), Smart-Menüs via ask/question-Tool, Operator-Login (`#operator logout` Pflicht am Sitzungsende), Trigger-Wörter-Anzeige, **.ssa & Memory-Update nach JEDER Aufgabe**, Gefährliche-Änderungen-erst-fragen, Command-Safety. Vollständig: siehe [`_STANDARD.md`](../_STANDARD.md) im Skill-Root.
