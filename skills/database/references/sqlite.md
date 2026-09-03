# SQLite - Datenbank-Management

## Grundlagen

SQLite ist eine **dateibasierte** Datenbank - keine Server-Installation nötig. Alle Daten in einer Datei.

**WICHTIG**: SQLite-Datei ist ein Produktions-Abhängigkeit. Immer sichern.

## Häufige Befehle

### Verbinden & Abfragen
```bash
# Einfache Abfrage
sqlite3 /pfad/db.sqlite "SELECT * FROM benutzer LIMIT 10;"

# In interaktive Shell
sqlite3 /pfad/db.sqlite

# Im interaktiven Modus: Befehle
.tables          # Tabellen auflisten
.schema          # Schema zeigen
.headers on      # Spaltennamen anzeigen
.mode column     # Tabellen-Format
```

### Tabellen prüfen
```bash
# Schema einer Tabelle
sqlite3 /pfad/db.sqlite ".schema tabelle"

# Zeilenanzahl
sqlite3 /pfad/db.sqlite "SELECT COUNT(*) FROM tabelle;"

# Tabellengröße
du -h /pfad/db.sqlite
```

### Backup
```bash
# Backup-Methode 1 (sicher, konsistent)
sqlite3 /pfad/db.sqlite ".backup /root/.ssa/backups/databases/db-$(date +%Y%m%d).sqlite"

# Backup-Methode 2 (SQL-Dump)
sqlite3 /pfad/db.sqlite ".dump" > /root/.ssa/backups/databases/db-$(date +%Y%m%d).sql

# Restore (aus Backup-Datei)
sqlite3 /pfad/db.sqlite ".restore /root/.ssa/backups/databases/db-20260101.sqlite"
```

### Sicherheit: WAL-Modus aktivieren (empfohlen)
```bash
# WAL = Write-Ahead-Logging - besserer Performance + weniger Locks
sqlite3 /pfad/db.sqlite "PRAGMA journal_mode=WAL;"
```

## Optimierung

### VACUUM (defragmentieren, Platz freigeben)
```bash
# Platten-Platz zurückgewinnen (nach vielen Löschungen)
sqlite3 /pfad/db.sqlite "VACUUM;"
```

### Indexe
```bash
# Bestehende Indexe anzeigen
sqlite3 /pfad/db.sqlite "PRAGMA index_list(tabelle);"

# Neuen Index erstellen (Kann Lese-Performance stark verbessern)
sqlite3 /pfad/db.sqlite "CREATE INDEX idx_benutzer_email ON benutzer(email);"
```

## Wichtigste Befehle bei "database is locked"

1. Prüfe ob andere Prozesse zugreifen: `lsof /pfad/db.sqlite`
2. WAL aktivieren: `PRAGMA journal_mode=WAL;`
3. Busy-Timeout setzen: `sqlite3 /pfad/db.sqlite "PRAGMA busy_timeout=5000;"`

## Fehlerbehandlung

| Fehler | Lösung |
|--------|--------|
| database is locked | WAL aktivieren, busy_timeout setzen |
| no such table | Pfad prüfen, Datei korrekt? |
| disk I/O error | Disk prüfen, Datei-Reparatur |
| malformed database | Backup wiederherstellen |

## Sicherheit

- **Niemals** die SQLite-Datei löschen ohne Backup
- **Bei Produktion**: Backup vor JEDEM Schreib-Vorgang
- **Immer** Benutzer über erste DROP/ALTER informieren
