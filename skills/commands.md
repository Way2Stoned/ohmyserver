# OhMyServer — `#` Command-System (Minecraft-inspiriert)

**Zentrale Befehls-Syntax** für ALLE OhMyServer-Skills. Jeder Befehl beginnt mit `#`, gefolgt von Agent + Aktion + optionalen Zielen/Optionen — analog zu Minecraft-Befehlen (`/gamemode creative`), aber mit `#`.

> Diese Datei ist die **Wahrheitsquelle** für die Befehlssyntax. Jeder Skill referenziert darauf.

## Grundsyntax

```
#<agent> <aktion> [ziel] [optionen]
```

| Teil | Bedeutung | Beispiel |
|------|-----------|----------|
| `#` | Leitet jeden Befehl ein | `#memory show` |
| `<agent>` | Der Skill/Fachbereich | `#security` |
| `<aktion>` | Was tun (Verb) | `#security scan` |
| `[ziel]` | Womit (optional) | `#security ban 1.2.3.4` |
| `[optionen]` | Flags/Parameter (optional) | `--json`, `--force` |

Leerzeichen trennen die Teile. **Keine Unterstriche** in Befehlen — Leerzeichen statt `_`.

## Globale Standard-Commands (in JEDEM Skill)

| Befehl | Aktion |
|--------|--------|
| `#help` | Zeige Trigger/Commands dieses Skills (kompakt) |
| `#status` | Zeige Skill-Status / letzte Aktionen |
| `#memory` | Öffne/zusammenfassen Memory für diesen Skill |
| `#operator` | Operator-Sitzung (login/logout/status) |

## Agent-Kurznamen (Routing)

| #-Befehl | Skill | Beispiel |
|----------|-------|----------|
| `#operator` | ohmyserver-operator | `#operator login <name>` · `#operator logout` |
| `#memory` | ohmyserver-memory | `#memory show` · `#memory add ...` |
| `#todo` | ohmyserver-memory | `#todo list` · `#todo add ...` |
| `#design` | ohmyserver-design (QD) | `#design help` · `#design plan <thema>` · `#design preview` · `#design wireframe` · `#design render <pfad>` |
| `#code plan` | ohmyserver-code-planner | `#code plan <aufgabe>` |
| `#code write` | ohmyserver-code-writer | `#code write <modul>` |
| `#code verify` | ohmyserver-code-verifier | `#code verify <modul>` |
| `#security` | ohmyserver-security | `#security scan` · `#security status` |
| `#config` | ohmyserver-maintenance | `#config install <pkg>` · `#config cleanup` |
| `#backup` | ohmyserver-maintenance | `#backup run` · `#backup restore` |
| `#maintenance` | ohmyserver-maintenance | `#maintenance backup` · `#maintenance restore` · `#maintenance cleanup` |
| `#health` | ohmyserver-monitor | `#health check` |
| `#uptime` | ohmyserver-monitor | `#uptime check` |
| `#update` | ohmyserver-monitor | `#update check` · `#update install` |
| `#monitor` | ohmyserver-monitor | `#monitor health` · `#monitor services` · `#monitor update` |
| `#notify` | ohmyserver-notification | `#notify send <msg>` |
| `#db` | ohmyserver-database | `#db status` · `#db backup` |
| `#vault` | ohmyserver-vault | `#vault add <name> <kind>` · `#vault get <name>` · `#vault list` · `#vault delete <name>` · `#vault rotate` |
| `#user` | ohmyserver-users | `#user list` |
| `#verify` | ohmyserver-verify | `#verify all` |
| `#status` (global) | ohmyserver-status | `#status all` |
| `#dispatcher` | ohmyserver-dispatcher | `#dispatcher route <anfrage>` |
| `#supervisor` | ohmyserver-supervisor | `#supervisor check` · `#supervisor status` · `#supervisor heal <typ>` |
| `#edit_agent#` | ohmyserver-edit-agent | Toggle Edit-Modus (Skills anpassen/erweitern, Self-Reload) |
| `#` (global) | ohmyserver-general | `#help` · `#status all` |

## Allgemeine Optionen (bei Bedarf unterstützen)

| Option | Bedeutung |
|--------|-----------|
| `--json` | Maschinenlesbarer Output |
| `--force` | Ohne erneute Rückfrage (nur bei explizit erlaubt) |
| `--dry-run` | Nur anzeigen, nichts ändern (Backups, Cleanup) |
| `--hours=N` | Zeitfenster (Logs/Checks) |

## Registrierung in Skill-Frontmatter

Jeder Skill trägt im Frontmatter `triggers` BEIDE: die natürlichen Trigger-Wörter UND den `#`-Command. Beispiel für Memory:
```yaml
triggers:
  - "#memory"
  - "#todo"
  - "memory"
  - "merke dir"
  - ...
```

## #help Output (Standard)

Bei `#help` eines Skills kompakt:
```
#design — Optics & Design (QD)
 Befehle: #design plan | #design preview | #design wireframe | #design render | #design guideline | #design research
 Trigger: design, layout, farbe, pdf, bild, planen, preview, wireframe ...
 Global: #help | #status | #memory | #operator
```
