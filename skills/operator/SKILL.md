---
name: ohmyserver-operator
description: "Operator & Session Module for OhMyServer. Manages Operator Login/Logout, Trigger Words, Memory and .ssa Updates for your server."
triggers:
  - "#operator"
  - "#operator login"
  - "#operator logout"
  - "#operator status"
  - "operator"
  - "anmelden"
  - "abmelden"
  - "wer bin ich"
  - "mein name"
  - "wer ist eingeloggt"
  - "trigger"
  - "trigger-wörter"
  - "memory"
  - "session"
---

# Operator & Session Module - OhMyServer

Central Module for **Operator Management**, **Trigger Words**, **Memory** and **.ssa Logging** on **<domain>**.

## Operator Login / Logout

### First Message (Login Required)
- **Check State**: Does `/root/.ssa/operators/active-operator.md` Exist?
- **No Active Session** → Ask for Operator Name FIRST:
  ```
  👤 Operator: Please provide your name for this session? (for Logs & Memory)
  ```
- After Name Given → Start Session (See Below)
- Operator Is Remembered for Entire Chat Session

### Perform Login (`#operator login <name>`)
```
1. Create/Update Operator File:  /root/.ssa/operators/<name>.md
2. Write Active Session:         /root/.ssa/operators/active-operator.md
3. Update Memory:                /root/.ssa/operators/memory.md
4. Briefly Confirm (1 Line)
```

```bash
# /root/.ssa/operators/<name>.md
echo "operator: <name>"         >> /root/.ssa/operators/<name>.md
echo "first_seen: $(date -u +%F)" >> /root/.ssa/operators/<name>.md
echo "last_login: $(date -u +%F_%T)" >> /root/.ssa/operators/<name>.md

# /root/.ssa/operators/active-operator.md
echo "<name>" > /root/.ssa/operators/active-operator.md
```

### Logout (`#operator logout`)
**Mandatory**: Operator MUST Log Out at End of Task/Session with `#operator logout`.
```
1. Update last_logout Timestamp
2. DELETE active-operator.md (Session Ended)
3. Update Memory (Session Summary)
4. Compact Confirm + Name Open Points
```
```bash
rm /root/.ssa/operators/active-operator.md
```

### Read Active Session
```bash
# Who Is Logged In? (Empty = Nobody)
cat /root/.ssa/operators/active-operator.md 2>/dev/null
```

## Trigger Words

Show Operator ALL Available Triggers Compactly:

```
⚡ Trigger: #operator login | #operator logout | #operator status | #help | #memory | #todo | <specialist-trigger>
```

### Central Triggers
| Trigger | Action |
|---------|--------|
| `#operator login <name>` | Log In Operator |
| `#operator logout` | Log Out + End Session (MANDATORY at End) |
| `#operator status` | Compact Status + Open Points |
| `#help` | Show All Trigger Words |
| `#memory` | Show Memory |
| `status`, `what runs` | Overall Status (→ ohmyserver-status) |

## Memory System

Stored in `/root/.ssa/operators/memory.md` — Maintained by EVERY Skill.

### When to Update (MANDATORY After Every Task)
- **Always**: Short Log Entry (What Done, When, Result)
- **On Server Changes**: Detailed Protocol (What, Where, How, Before/After, Risk)
- **On Preferences**: Remember Operator Preferences (e.g. Output Style, Languages, Tools)

### memory.md Structure
```markdown
# Memory - <domain>

## Active Operator
- Name: <name>
- Since: <date>

## Preferences
- Output Style: Compact (Progressbar)
- <More>

## Session Log (Newest First)
- [YYYY-MM-DD HH:MM] <What Done> - <Result>

## Open Points
- <Unfinished Tasks>
```

## .ssa Updates (MANDATORY After Every Task)

### Rule
- **Always**: Append 1 Line to `/root/.ssa/logs/<area>.log`
- **Only on Server Changes** (Install/Config/Rights/Restart): Detailed in `/root/.ssa/protocols/` + Maybe `reports/`

### Log Line Format
```
[YYYY-MM-DD HH:MM] <operator>: <what> - <result>
```

### Protocol (On Server Change)
- Update `/root/.ssa/protocols/<area>-config.md`
- Operator Name in Header + Date

## Compact Output Style (GENERAL for All Skills)

**IMPORTANT**: This Style Applies to ALL OhMyServer Skills.

- **During Work**: Progress-Style Status Line, No Flowing Text
  ```
  ⬜ [1/5] Step: Description
  ✅ [1/5] Step: Description
  ⬜ [2/5] ...
  ```
- **No Running Commentary** — Don't Explain What You're Doing Except in Progress
- **Only Report Results**, Not Describe Processes
- **At End**: One Compact Final Summary
  ```
  ✅ DONE - <Task>
   • <Main Result 1>
   • <Main Result 2>
   ⚠️ Open: <If Anything Open>
  ```

## Operator Onboarding

**When Meeting a NEW Operator** (no active session or unknown name), the agent speaks **ENGLISH FIRST** and asks:

1. **Preferred Language** (English/German/Other)
2. **Operator Name** 
3. **Reason / Purpose** for this session
4. **About Them** (their role/task — e.g. admin, developer, ops, etc.)

After collecting, store the operator in the standard operators mechanism (`/root/.ssa/operators/<name>.md` + `active-operator.md`) and switch to the preferred language going forward.

Use `question`-Tool for the language menu:
```markdown
question(
  "Welcome! What is your preferred language?",
  ["English", "Deutsch", "Other"]
)
```

Then ask for name, reason, and role via follow-up questions.

## Hard Rules
- **First Message**: Always Ask for Operator Name (If No Active Session)
- **`#operator logout` Mandatory** at End of Every Session
- **Trigger Words** Always Show Compactly
- **Memory + .ssa Log** Update After Every Task
- **Compact Output**, No AI-Slop


---
## OhMyServer-Standard (PFLICHT)

Dieser Skill folgt den **gemeinsamen OhMyServer-Standards**: kompakter Output (Progressbar, kein AI-Slop), Smart-Menüs via ask/question-Tool, Operator-Login (`#operator logout` Pflicht am Sitzungsende), Trigger-Wörter-Anzeige, **.ssa & Memory-Update nach JEDER Aufgabe**, Gefährliche-Änderungen-erst-fragen, Command-Safety. Vollständig: siehe [`_STANDARD.md`](../_STANDARD.md) im Skill-Root.
