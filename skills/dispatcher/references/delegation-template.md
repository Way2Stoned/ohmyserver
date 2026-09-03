# Dispatcher - Delegations-Prompts & Orchestrierungs-Patterns

## Das 6-Punkte-Delegations-Prompt-Template

Jeder Subagent-Aufruf MUSS diese Struktur haben:

```
1. TASK:          Atomisches, spezifisches Ziel (eine Aktion pro Delegation)
2. EXPECTED OUTCOME: Konkrete Deliverables mit Erfolgskriterien
3. REQUIRED TOOLS:  Explizite Tool-Whitelist (verhindert Tool-Sprawl)
4. MUST DO:        Erschöpfende Anforderungen - nichts implizit lassen
5. MUST NOT DO:    Verbotene Aktionen - rogue-Verhalten blockieren
6. CONTEXT:        Dateipfade, bestehende Patterns, Constraints
```

### Example Prompt (Delegating Security Scan)
```
TASK: Run a security scan on <domain>.
EXPECTED OUTCOME: Report with open ports, SSH safety status, Fail2Ban status, suspicious logs.
REQUIRED TOOLS: bash (only security-scan.sh + read-only checks).
MUST DO: 
  - Execute scripts/security-scan.sh
  - Check /var/log/auth.log for failures
  - Name specific IPs if anomalies found
  - Make NO changes
MUST NOT DO:
  - NO SSH config changes
  - NO Firewall rule changes
  - NO package installations
  - No interactive CLIs
CONTEXT: Server <domain>, User <user>. Security Baseline: /root/.ssa/protocols/baseline.md
```

## Dispatcher-Routing-Matrix (erweitert)

| Anfrage enthält... | Parallel route zu... |
|--------------------|---------------------|
| "Server langsam" | monitor |
| "SSH gehackt" | security |
| "DB weg" | database + maintenance |
| "Install X" | maintenance |
| "Alles checken" | status (zuerst), dann je Bedarf |
| "Update + Security" | monitor + security |
| "Backup + DB" | maintenance + database |
| "Docker + Speicher" | maintenance + database(storage) |
| "Password/Token/API-Key" | vault |

## Parallele Delegation (Background)

```text
Nutze run_in_background=true für unabhängige Checks.
Starte 2-5 gleichzeitig.
Warte NICHT synchron - beende Response, warte auf <system-reminder>.
Sammle Ergebnisse via background_output(task_id="bg_...").
Folge-Aufgaben via task(task_id="ses_...").
```

### Wann parallel vs sequenziell
| Abhängigkeit | Ansatz |
|--------------|--------|
| A und B unabhängig | **Parallel** |
| B braucht Ergebnis von A | **Sequenziell** |
| 3 unabhängige | **Alle 3 parallel** |

## Skill-Verzeichnis für Dispatcher

| Agent | Skill-Datei | Delegiere wenn... |
|-------|-------------|-------------------|
| SSA | `security/SKILL.md` | Security/SSH/Hack |
| MA | `maintenance/SKILL.md` | Install/Cleanup/Backup/Restore |
| MON | `monitor/SKILL.md` | Performance/Health/Dienste/Updates |
| VA | `vault/SKILL.md` | Passwörter/Tokens/API-Keys |
| NA | `notification/SKILL.md` | Alerts |
| DSA | `database/SKILL.md` | DB/SQL/Storage |
| UPA | `users/SKILL.md` | User/Rechte/Zugriff |
| VQA | `verify/SKILL.md` | Verifizieren/QA |
| Status | `status/SKILL.md` | Gesamt-Status |
| CmdSafety | `command-safety/SKILL.md` | Bei jedem langen Command |

## Anti-Duplication-Regel
Nach Delegation an einen Subagent: **nicht dieselbe Suche selbst wiederholen**.
Warte auf Ergebnis statt parallel dasselbe zu machen.

## Fehlerbehandlung

| Problem | Lösung |
|---------|--------|
| Subagent fehlgeschlagen | `task(task_id="ses_...")` fortsetzen |
| Ergebnis unvollständig | Fokus-Re-Run mit klarer Korrektur |
| 2+ Fehlschläge | Oracle konsultieren |
| Ergebnis inkonsistent | Prüfen, gegensätzlich → nachfragen |
