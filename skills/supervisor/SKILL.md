---
name: ohmyserver-supervisor
description: "Supervisor/Watchdog-Agent für OhMyServer. Überwacht alle Skills auf Konsistenz & Fehler, erkennt Probleme, schlägt Auto-Healing vor und meldet Status ans Dashboard — für talbergh.art."
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

Überwacht das **gesamte OhMyServer-Skill-Set** und die **Laufzeit-Konsistenz** für **talbergh.art**. Erkennt Inkonsistenzen und Fehler, schlägt **Auto-Healing** vor (handelt nicht eigenmächtig) und meldet Status ans Dashboard.

## Kernprinzip
**Beobachten → Prüfen → Melden → Vorschlagen.** Nie eigenmächtig heilen/ändern ohne Operator-Freigabe (außer bei explizit freigegebenen Auto-Healing-Regeln).

## Trigger & Aktionen

| Trigger | Aktion |
|---------|--------|
| `#supervisor check` | Konsistenz-Check aller Skills + Struktur |
| `#supervisor status` | Laufzeit-Status melden (auch via Dashboard) |
| `#supervisor heal <typ>` | Auto-Healing-Vorschlag (mit Freigabe) ausführen |
| `#help` | Alle Trigger anzeigen |

## Supervisor-Check (Konsistenz)

### 1. Struktur-Integrität prüfen
```bash
# Alle Skills mit SKILL.md vorhanden?
SKILL_ROOT="/root/.config/opencode/skills/ohmyserver"
for d in "$SKILL_ROOT"/*/; do
  name=$(basename "$d")
  [ -f "$d/SKILL.md" ] && echo "✓ $name: SKILL.md" || echo "⚠ $name: FEHLT SKILL.md"
done

# Frontmatter-Validität (name, description, triggers)
grep -l "^name:" "$SKILL_ROOT"/*/SKILL.md | wc -l
```

### 2. Routing-Konsistenz (commands.md ↔ Skills)
```bash
# Jeder #-Command in commands.md muss auf existierenden Skill zeigen
# Prüfe: ohmyserver-X im commands.md == tatsächlicher Skill-Ordner
grep -oE "ohmyserver-[a-z-]+" "$SKILL_ROOT/commands.md" | sort -u
ls -d "$SKILL_ROOT"/*/ | xargs -n1 basename | sed 's/^/ohmyserver-/' | sort -u
```
Inkonsistenz = Command zeigt auf Skill der fehlt (oder umgekehrt).

### 3. Trigger-Duplikate erkennen
```bash
# Doppelte Trigger-Wörter über mehrere Skills (außer globale wie #status/#memory/#operator/#help)
grep -rhoE "^  - \"[^\"]+\"" "$SKILL_ROOT"/*/SKILL.md | sort | uniq -d
```
Nur globale Trigger (#help, #status, #memory, #operator, ##-Wörter) dürfen in mehreren Skills vorkommen.

### 4. Referenz-Integrität
- Alle `ohmyserver-X`-Skill-Namen, auf die in dispatcher/general/commands.md verwiesen wird, müssen existieren
- Keine dangling `ohmyserver-configurator`/`backup`/`perf-monitor`/`uptime`/`updater` (konsolidiert!) mehr

## Auto-Healing-Vorschläge

| Problem | Vorschlag | Freigabe nötig? |
|---------|-----------|-----------------|
| Skill-SKILL.md fehlt | Init von Referenz/README wiederherstellen | Ja |
| Command → fehlender Skill | Routing in commands.md korrigieren | Ja |
| Trigger-Duplikat | Trigger-Wort in einem Skill entfernen/ändern | Ja |
| Alte Skill-Referenz (konsolidiert) | Auf monitor/maintenance/vault umbiegen | Ja |
| Script fehlt im Repo | Aus Live-Skills synchronisieren | Ja |
| Live ≠ Repo | Konsistenz per `diff -rq` reparieren | Ja |

**Format für Heal-Vorschlag:**
```
🩹 AUTO-HEALING VORSCHLAG
Problem: [was inkonsistent]
Ursache: [warum]
Fix: [konkret]
Risiko: [niedrig/mittel/hoch]
Soll ich? [ja/nein]
```

## Supervisor-Status (Dashboard)

Bei `#supervisor status` oder über das Dashboard-Trigger:
```
🛡 SUPERVISOR-STATUS
Skills: [X] aktiv, [Y] geprüft
Konsistenz: OK / N Probleme
Letzter Check: [Zeit]
Probleme: [Liste oder "keine"]
```
Melde Ergebnisse kompakt ans Dashboard (Trigger-Queue via `.ssa/dashboard/triggers/`).

## Protokoll (PFLICHT)
- Ergebnis jedes Checks: `/root/.ssa/logs/supervisor.log`
- Bei Heal-Fix: ausführlich in `/root/.ssa/protocols/`

## Hard Rules
- **Nie** eigenmächtig heilen ohne Operator-Freigabe
- **Immer** erst prüfen, dann vorschlagen, dann (mit Freigabe) ausführen
- **Nur** Änderungen melden, nicht denselben Status wiederholen
- **Kompakter Output** (Progress-Stil), kein AI-Slop


---
## OhMyServer-Standard (PFLICHT)

Dieser Skill folgt den **gemeinsamen OhMyServer-Standards**: kompakter Output (Progressbar, kein AI-Slop), Smart-Menüs via ask/question-Tool, Operator-Login (`#operator logout` Pflicht am Sitzungsende), Trigger-Wörter-Anzeige, **.ssa & Memory-Update nach JEDER Aufgabe**, Gefährliche-Änderungen-erst-fragen, Command-Safety. Vollständig: siehe [`_STANDARD.md`](../_STANDARD.md) im Skill-Root.
