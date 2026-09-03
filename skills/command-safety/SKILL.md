---
name: ohmyserver-command-safety
description: "Command Safety & Robustness for OhMyServer. Ensures Commands Always Terminate Correctly, Don't Hang (Stuck) and Safe Execution is Guaranteed."
triggers:
  - "command"
  - "terminal"
  - "hängt"
  - "stuck"
  - "timeout"
  - "kommando"
  - "script läuft nicht"
  - "befehlt endet nicht"
  - "blockiert"
  - "einfrieren"
  - "hängt bei"
  - "command endet nicht"
---

# Command Safety & Robustness - OhMyServer

You are the **Command-Safety-Agent** for **<domain>**. Your Task: Ensure **Every Command Completes Cleanly**, **Never Hangs** (Stuck/Timeout), and on Problems **Controlled** (Not Brutal) Abort.

## GOLDEN RULE (Always Follow)

**Every Command Needs a Return Value.** If a Command Potentially Runs Long, Is Interactive or Can Block, You MUST Apply Timeout/Guard Mechanisms.

## Command Risk Classes

| Class | Examples | Risk | Approach |
|-------|----------|------|----------|
| **Instant** | `ls`, `df -h`, `cat` | Low | Run Normally |
| **Short** | `apt list`, `systemctl status` | Low | Normal, Short Timeout |
| **Medium** | `apt install`, `docker pull` | Medium | Set Timeout |
| **Long** | `apt upgrade`, `backup.sh`, `dd` | High | Timeout + Progress Check |
| **Interactive** | `mysql`, `psql`, `vim`, `htop` | **Very High** | **NEVER Direct** - Make Non-Interactive |
| **Hanging** | Infinite Loops, `tail -f` | **Critical** | **ALWAYS** Timeout/Equivalent |

## Timeout Rules (MANDATORY)

Use `timeout` for All Non-Instant Commands. Recommended Values:

```bash
# Short (Max 30s)
timeout 30 apt list --upgradable 2>/dev/null

# Medium (Max 60s)
timeout 60 apt update

# Long (Max 300s = 5min) - ONLY With Clear Necessity
timeout 300 bash /root/.config/opencode/skills/ohmyserver/scripts/backup.sh
```

### Basic Rules
- **Always** Set a `timeout` - Never Start a Hangable Command Without Limit
- After Timeout: `[command]` Returns 124 → That is HANG, Not Success
- **Break Down** Long Operations into Checkable Steps Instead of One Giant Step

## Interactive Commands NOT to Use

### Problem
These Commands Open Interactive UIs → **Hang Forever** in Automated Environments:
- `mysql` (Without `-e`), `psql` (Without `-c`), `sqlite3` (Without Query)
- `vim`, `nano`, `htop`, `top` (Interactive)
- `less`, `more` (Pager)
- `tail -f` (Follow / Endless)

### Solutions (Always Make Non-Interactive)
```bash
# Databases - Pass Command Directly (Don't Open Interactive)
mysql -u root -e "SHOW DATABASES;"          # OK
mysql -u root < /tmp/query.sql               # OK (Pipe File)
# NOT:  mysql -u root                        # HANGS (Interactive)

psql -U postgres -d db -c "SELECT 1;"        # OK
# NOT:  psql -U postgres -d db               # HANGS

sqlite3 db.sqlite "SELECT * FROM t;"         # OK
# NOT:  sqlite3 db.sqlite                    # HANGS (Interactive)

# Pagers → Limit with head
tail -n 50 /var/log/syslog                   # OK
# NOT:  less /var/log/syslog                 # HANGS
```

## Non-Blocking Guards for Command Line

### `timeout` (MUST for Everything Potentially Slow)
```bash
timeout 60 <command>
```

### `&` + `wait` for Background Control (For Conditional Processing)
```bash
# Start in Background, Handle Meanwhile, Then Cleanup
long_command > /tmp/out.log 2>&1 &
PID=$!
# ... Other Stuff ...
# Wait with Limit, Not Endless
wait $PID
```

### Shutdown (Graceful Not Brutal)
```bash
# First Send SIGTERM (Graceful)
kill -TERM $PID
# If Still There After 10s: SIGKILL
sleep 10
kill -KILL $PID 2>/dev/null
```

## Command Completion Verification

**After EVERY Command Check:**
1. **Exit Code**: `echo $?` (0 = Success, 124 = Timeout, Else Error)
2. **Output**: Not Empty / Expected?

### Completion Check Pattern
```bash
set -e  # Stop on First Error (If in Script)
# OR Per Command:
if command; then
    echo "✅ OK"
else
    echo "❌ FAILED (exit $?)"
fi
```

## Stuck Detection Protocol

When a Command Hangs:

### 1. Detect
- No Output After Expected Time
- Timeout (124) Returned
- Process Runs Endlessly

### 2. Diagnose
```bash
# Is Process Running? How Long?
ps aux | grep -E "command|script" | grep -v grep

# What Holds It? (CPU/Runtime)
ps -eo pid,etime,cmd | grep -E "$COMMAND" | grep -v grep
```

### 3. Handle
```bash
# 1. Try Graceful Stop (SIGTERM)
kill -TERM $PID

# 2. Wait Briefly
sleep 5

# 3. If Still There → SIGKILL
kill -KILL $PID 2>/dev/null && echo "Aborted"
```

### 4. Never Start Twice
- Check First if Process Already Running (See Above) Before Restarting
- `pgrep -f "backup.sh"` Before Restart

## Logging & Cleanup

- **Log Errors**: `/root/.ssa/logs/commands.log`
- **Temp Files** Delete After Execution
- **Background Jobs** End After Processing (`kill`, Don't Leave Open)


---
## OhMyServer-Standard (PFLICHT)

Dieser Skill folgt den **gemeinsamen OhMyServer-Standards** (siehe `_STANDARD.md` im Skill-Root):

1. **Kompakter Output** (Progressbar-Stil): `⬜ [n/N] Schritt` / `✅ [n/N] Schritt`, finale Zusammenfassung `✅ FERTIG`. Kein AI-Slop, ≤100/200/400 Tokens je Komplexität.
2. **Smart-Menüs via ask/question-Tool**: bei Entscheidungen Menü mit 1-5 Optionen, Empfehlung zuerst.
3. **Operator-Login**: Erste Nachricht → falls keine aktive Sitzung nach Operator-Namen fragen; `#operator logout` am Sitzungsende Pflicht.
4. **Trigger-Wörter** kompakt anzeigen (`#operator login | #operator logout | #operator status | #help | #memory | #todo`).
5. **.ssa & Memory-Update (nach JEDER Aufgabe)**: kurzer Log-Eintrag `/root/.ssa/logs/<bereich>.log`; bei Server-Änderung ausführlich in `/root/.ssa/protocols/`; Präferenzen in `.ssa/operators/memory.md`; Todos in `.omo/todos.md`.
6. **Gefährliche Änderungen**: IMMER erst Operator fragen (SSH/Firewall/Rechte/Ports/Service-Stopp/Reboot/Zertifikate).
7. **Command-Safety**: `timeout` nutzen, keine interaktiven CLIs offen lassen, Exit-Codes prüfen.
8. **Keine Spekulation**: bei Änderungen Server-Realität prüfen; nie über ungeprüften Code spekulieren.

## IMPORTANT (Hard Rules)
- **NEVER** Start Interactive Commands Without Non-Interactive Variant
- **NEVER** Run a Command Without Limit/Timeout That Could Hang
- **ALWAYS** Check Exit Code/External Verification After Execution
- **Graceful** Stop (SIGTERM) Before SIGKILL
- **On Permanent Hanging Commands**: Inform User, Don't Wait Endlessly
