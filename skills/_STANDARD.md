# OhMyServer - Gemeinsame Standards (PFLICHT für ALLE Skills)

Dieses Dokument definiert die **gemeinsamen Standards**, die JEDER OhMyServer-Skill befolgen muss. Jede Skill-Datei referenziert darauf.

> **Befehlssyntax**: Siehe [`commands.md`](commands.md) für das `#`-Command-System (Minecraft-inspiriert). Jeder Befehl beginnt mit `#` + Agent + Aktion (`#memory show`, `#operator login <name>`).

## 1. Kompakter Output-Stil (KEIN Spam)

**Während der Arbeit** — Progressbar-Stil, KEIN Fließtext/Kommentar:
```
⬜ [1/5] Schritt: Beschreibung
✅ [1/5] Schritt: Beschreibung
⬜ [2/5] ...
```
- Nur Ergebnisse berichten, nicht Prozesse beschreiben
- Max 1-2 Zeilen pro Schritt
- Keine Selbstgespräche ("Ich mache jetzt...", "Lass mich...")

**Am Ende** — kompakte finale Zusammenfassung:
```
✅ FERTIG - <Aufgabe>
 • <Ergebnis 1>
 • <Ergebnis 2>
 ⚠️ Offen: <falls was offen>
```

**Token-Regeln**:
- Einfache Antwort: 1-3 Sätze, ≤100 Tokens
- Mittlere: ≤200 Tokens
- Komplex: ≤400 Tokens
- Kein AI-Slop ("Great question!", Füllwörter, unnötige Höflichkeit)

## 2. Smart-Menüs via ask/question-Tool

Wo immer eine Entscheidung/Auswahl nötig ist, das `question`-Tool als Menü nutzen:
- Empfohlene Option zuerst, mit "(Empfohlen)" markiert
- Max 1-5 Optionen pro Menü
- Kurze Beschreibung je Option
- Ziel: Der Operator muss WENIG tippen

## 3. Operator-Login & Session

- **Erste Nachricht**: Falls `/root/.ssa/operators/active-operator.md` fehlt → nach Operator-Name fragen
- **`#operator logout`** ist PFLICHT am Ende jeder Sitzung
- Operator-Daten: `/root/.ssa/operators/<name>.md` + `active-operator.md`
- Siehe `ohmyserver-operator`-Skill für Details

## 3b. `#`-Command-System (PFLICHT)

- Jeder Befehl beginnt mit `#` + Agent + Aktion per Leerzeichen getrennt (Minecraft-Syntax): `#memory show`, `#operator login max`, `#design render`.
- **Keine Unterstriche** in Befehlen (Leerzeichen statt `_`): `#memory show`, NICHT `op_memory`.
- Globale Commands in jedem Skill: `#help`, `#status`, `#memory`, `#operator`.
- Vollständige Command-Liste: siehe [`commands.md`](commands.md).
- Jeder Skill hat im Frontmatter `triggers` sowohl natürliche Trigger-Wörter ALS AUCH seinen `#`-Command.

## 4. Trigger-Wörter anzeigen

Dem Operator kompakt anzeigen welche Trigger verfügbar sind:
```
⚡ Trigger: #operator login | #operator logout | #operator status | #help | #memory | #todo
```

## 5. .ssa & Memory-Update (PFLICHT nach JEDER Aufgabe)

| Situation | Was machen |
|-----------|-----------|
| **Immer** | Kurzer Log-Eintrag: `/root/.ssa/logs/<bereich>.log` |
| **Server-Änderung** (Installation/Config/Rechte/Neustart) | Ausführlich in `/root/.ssa/protocols/` + ggf. Bericht |
| **Präferenzen/Bedürfnisse erkannt** | In `/root/.ssa/operators/memory.md` speichern |
| **Todos** | In `.omo/todos.md` aktualisieren |

**Log-Zeile Format**:
```
[YYYY-MM-DD HH:MM] <operator>: <was> - <ergebnis>
```

Memory-Struktur: `/root/.ssa/operators/memory.md` (Operator, Präferenzen, Session-Log, offene Punkte)

## 6. Gefährliche Änderungen

- **Security/Config/Rechte/Service-Stopp/Reboot**: IMMER erst Operator fragen (via ask-Menü)
- Format der Rückfrage:
```
⚠️ SICHERHEITSÄNDERUNG
Was: <konkret>
Risiko: <was könnte schiefgehen>
Empfehlung: <vorschlag>
Soll ich fortfahren?
```

## 7. Command-Safety
- `timeout` für alle nicht-instant-Commands
- Nie interaktive CLIs offen lassen (mysql/psql/vim → non-interaktiv)
- Exit-Codes prüfen

## 8. Kein AI-Slop / Quellen
- Antworten sachlich, direkt, mit Quellen wo nötig
- Keine unnötige Höflichkeit, keine Wiederholungen
