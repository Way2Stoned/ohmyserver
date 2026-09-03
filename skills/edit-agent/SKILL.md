---
name: ohmyserver-edit-agent
description: "Edit-Agent für OhMyServer. Ermöglicht dem Operator die OhMyServer-Skills anzupassen/zu erweitern. Einstieg per #edit_agent#, ask-Menü-Auswahl beim Reinkommen, Ausstieg per #edit_agent#, Self-Reload der geänderten Skills."
triggers:
  - "#edit_agent#"
  - "edit agent"
  - "skill ändern"
  - "skill anpassen"
  - "skill erweitern"
  - "skill bearbeiten"
  - "skillset"
  - "skill anlegen"
  - "neuen skill"
  - "skill erstellt"
  - "config edit"
  - "ohmyserver anpassen"
---

# Edit-Agent (EA) — OhMyServer

Verwaltet die **OhMyServer-Skill-Dateien selbst**. Damit kann der Operator das Skillset **anpassen/erweitern**, ohne dass ein Entwickler die Dateien von Hand editieren muss.

## Modus-Einstieg & Ausstieg

| Aktion | Command | Effekt |
|--------|---------|--------|
| **Modus betreten** | `#edit_agent#` | Wechselt in den Edit-Modus, fragt via ask-Tool was zu tun ist |
| **Modus verlassen** | `#edit_agent#` (erneut) | Wechselt zurück, lädt geänderte Skills neu (Self-Reload) |

> `#edit_agent#` ist ein **Toggle** — beim Reingehen und wieder Rausgehen.

## Beim Einstieg (`#edit_agent#` → rein)

**IMMER** als Erstes das `question`/`ask`-Tool nutzen, um zu fragen was der Operator machen möchte:

```markdown
question(
  "Edit-Modus aktiv. Was möchtest du tun?",
  [
    "Neuen Skill anlegen",
    "Bestehenden Skill bearbeiten",
    "Trigger/Commands ändern",
    "Guideline/Memory ändern",
    "Skill löschen",
    "Nur anschauen (Übersicht)",
    "Edit-Modus beenden"
  ],
  multiple=false
)
```

Danach gezielt weiterfragen (Smart-Menü, wenig tippen).

## Aufgaben (Edit-Modus)

### 1. Neuen Skill anlegen
```
1. Ordner anlegen: skills/ohmyserver/<name>/SKILL.md
2. Frontmatter: name + description + triggers (inkl. #-Command)
3. Inhalt: Zweck, Ablauf, Standards (referenziert _STANDARD.md)
4. #-Command in commands.md + Dispatcher-Routing + README registrieren
5. Self-Reload
```

### 2. Bestehenden Skill bearbeiten
- Datei lesen, gezielt editieren (Edit-Tool)
- Frontmatter/Trigger konsistent halten
- `_STANDARD.md`-Verweis erhalten

### 3. Trigger/Commands ändern
- Frontmatter `triggers`-Liste anpassen (`#`-Command + natürliche Wörter)
- `commands.md` + Dispatcher-Tabelle aktualisieren
- README Trigger-Übersicht anpassen

### 4. Guideline/Memory ändern
- Design-Guidelines: `skills/ohmyserver/design/guidelines/`
- Memory: `/root/.ssa/operators/memory.md`
- Projekt-Guidelines: `/root/.ssa/design/project-guidelines/`

### 5. Skill löschen
```
1. Operator-Freigabe einholen (destruktiv!)
2. Ordner + Referenzen entfernen (commands.md, Dispatcher, README)
3. Backup der Datei vor Löschen (optional, .ssa/backups)
```

## Self-Reload (wichtig)

Nach JEDER Änderung an Skill-Dateien:
1. **Geänderte SKILL.md-Datei(en) neu lesen** (Read-Tool) — damit der neue Inhalt im aktiven Kontext wirksam wird
2. **Frontmatter validieren** (beginnt mit `---`, hat `name`/`description`/`triggers`)
3. **Konsistenz prüfen**: `_STANDARD.md`-Verweis, `#`-Command registriert
4. Dispatcher/README/commands.md aktualisiert?

**"Self-Reload"** = Der Agent liest die modifizierten Skills frisch ein, sodass die neuen Trigger/Regeln ab sofort im Gespräch aktiv sind (nicht erst nach Neustart). Bei mehreren geänderten Skills: alle re-lesen.

## Ausstieg (`#edit_agent#` → raus)

Beim Verlassen:
1. Zusammenfassen was geändert wurde (kompakt)
2. Self-Reload aller geänderten Skills durchführen
3. Zurück zum Normalmodus

```
✅ EDIT-MODUS BEENDET
 Geändert: <liste>
 Neu geladen: <skills>
 Anpassung aktiv ab jetzt.
```

## Sicherheitsregeln

- **Nie** `_STANDARD.md` / `commands.md` unsynchronisiert lassen (alle Skills konsistent)
- **Destruktive** Aktionen (Skill löschen): IMMER Operator-Freigabe per ask-Menü
- **Backup** vor größeren Edits (`.ssa/backups/`)
- Nach jedem Edit: Frontmatter + Registrierung verifizieren

## Referenz
- Befehle: [`commands.md`](../commands.md)
- Standards: [`_STANDARD.md`](../_STANDARD.md)
- Skill-Übersicht: [`README.md`](../README.md)
