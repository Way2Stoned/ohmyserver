---
name: ohmyserver-operator
description: "Operator- & Session-Modul für OhMyServer. Verwaltet Operator-Login/Logout, Trigger-Wörter, Memory und .ssa-Updates für talbergh.art."
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

# Operator & Session-Modul - OhMyServer

Zentrales Modul für **Operator-Verwaltung**, **Trigger-Wörter**, **Memory** und **.ssa-Protokollierung** auf **talbergh.art**.

## Operator-Login / Logout

### Erste Nachricht (Login-Pflicht)
- **Zustand prüfen**: Existiert `/root/.ssa/operators/active-operator.md`?
- **Keine aktive Sitzung** → als ERSTES nach dem Operator-Namen fragen:
  ```
  👤 Operator: Bitte dein Name für die Session? (für Logs & Memory)
  ```
- Nach Nennung → Sitzung starten (siehe unten)
- Der Operator wird für die gesamte Chat-Session gemerkt

### Login durchführen (`#operator login <name>`)
```
1. Operator-Datei anlegen/aktualisieren:  /root/.ssa/operators/<name>.md
2. Aktive Sitzung schreiben:               /root/.ssa/operators/active-operator.md
3. Memory aktualisieren:                   /root/.ssa/operators/memory.md
4. Kurz bestätigen (1 Zeile)
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
**Pflicht**: Der Operator MUSS sich am Ende einer Task/Session mit `#operator logout` abmelden.
```
1. last_logout Zeitstempel aktualisieren
2. active-operator.md LÖSCHEN (Sitzung beendet)
3. Memory aktualisieren (Session-Zusammenfassung)
4. Kompakt bestätigen + offene Punkte nennen
```
```bash
rm /root/.ssa/operators/active-operator.md
```

### Aktive Sitzung auslesen
```bash
# Wer ist eingeloggt? (leer = niemand)
cat /root/.ssa/operators/active-operator.md 2>/dev/null
```

## Trigger-Wörter

Dem Operator IMMER kompakt anzeigen, welche Trigger verfügbar sind:

```
⚡ Trigger: #operator login | #operator logout | #operator status | #help | #memory | #todo | <fach-trigger>
```

### Zentrale Trigger
| Trigger | Aktion |
|---------|--------|
| `#operator login <name>` | Operator anmelden |
| `#operator logout` | Abmelden + Sitzung beenden (PFLICHT am Ende) |
| `#operator status` | Kompakter Status + offene Punkte |
| `#help` | Alle Trigger-Wörter anzeigen |
| `#memory` | Memory anzeigen |
| `status`, `was läuft` | Gesamt-Status (→ ohmyserver-status) |

## Memory-System

Gespeichert in `/root/.ssa/operators/memory.md` — von JEDEM Skill gepflegt.

### Wann aktualisieren (PFLICHT nach jeder Aufgabe)
- **Immer**: Kurzer Log-Eintrag (was gemacht, wann, Ergebnis)
- **Bei Server-Änderungen**: Ausführliches Protokoll (was, wo, wie, vorher/nachher, Risiko)
- **Bei Präferenzen**: Operator-Vorlieben merken (z.B. Output-Stil, Sprachen, Tools)

### memory.md Struktur
```markdown
# Memory - talbergh.art

## Aktiver Operator
- Name: <name>
- Seit: <datum>

## Präferenzen
- Output-Stil: kompakt (Progressbar)
- <weitere>

## Session-Log (neueste oben)
- [YYYY-MM-DD HH:MM] <was gemacht> - <Ergebnis>

## Offene Punkte
- <nicht abgeschlossene Aufgaben>
```

## .ssa-Updates (PFLICHT nach jeder Aufgabe)

### Regel
- **Immer**: `/root/.ssa/logs/<bereich>.log` um 1 Zeile ergänzen
- **Nur bei Server-Änderungen** (Installation/Config/Rechte/Neustart): Ausführlich in `/root/.ssa/protocols/` + ggf. `reports/`

### Log-Zeile Format
```
[YYYY-MM-DD HH:MM] <operator>: <was> - <ergebnis>
```

### Protokoll (bei Server-Änderung)
- `/root/.ssa/protocols/<bereich>-config.md` aktualisieren
- Operator-Name in Kopfzeile + Datum

## Kompakter Output-Stil (ALLGEMEIN für alle Skills)

**WICHTIG**: Dieser Stil gilt für ALLE OhMyServer-Skills.

- **Während der Arbeit**: Progress-artige Statuszeile, keine Fließtexte
  ```
  ⬜ [1/5] Schritt: Beschreibung
  ✅ [1/5] Schritt: Beschreibung
  ⬜ [2/5] ...
  ```
- **Kein laufender Kommentar** — nicht erklären was du grad tust außer im Progress
- **Nur Ergebnisse** berichten, nicht Prozesse beschreiben
- **Am Ende**: Eine kompakte finale Zusammenfassung
  ```
  ✅ FERTIG - <Aufgabe>
   • <Hauptergebnis 1>
   • <Hauptergebnis 2>
   ⚠️ Offen: <falls was offen>
  ```

## Hard Rules
- **Erste Nachricht**: Immer nach Operator-Namen fragen (falls keine aktive Sitzung)
- **`#operator logout` Pflicht** am Ende jeder Sitzung
- **Trigger-Wörter** immer kompakt anzeigen
- **Memory + .ssa-Log** nach jeder Aufgabe aktualisieren
- **Komprimierter Output**, kein AI-Slop


---
## OhMyServer-Standard (PFLICHT)

Dieser Skill folgt den **gemeinsamen OhMyServer-Standards**: kompakter Output (Progressbar, kein AI-Slop), Smart-Menüs via ask/question-Tool, Operator-Login (`#operator logout` Pflicht am Sitzungsende), Trigger-Wörter-Anzeige, **.ssa & Memory-Update nach JEDER Aufgabe**, Gefährliche-Änderungen-erst-fragen, Command-Safety. Vollständig: siehe [`_STANDARD.md`](../_STANDARD.md) im Skill-Root.
