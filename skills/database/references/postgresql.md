# PostgreSQL - Datenbank-Management

## Grundlagen

PostgreSQL ist ein leistungsstarker Client/Server-Server. Zugriff erfolgt über den `postgres` System-Benutzer.

**WICHTIG**: PostgreSQL läuft als `postgres` Benutzer. Admin-Zugriff via `sudo -u postgres`.

## Verbindung

```bash
# Als Admin (via postgres-Systembenutzer)
sudo -u postgres psql

# In bestimmte Datenbank
sudo -u postgres psql -d datenbank

# Mit SQL direkt ausführen (mit sudo als postgres)
sudo -u postgres psql -c "SELECT 1;"

# Als App-Benutzer
psql -U benutzer -d datenbank -h localhost
```

## Häufige Befehle (in psql)

```sql
-- Datenbanken auflisten
\l

-- Wechseln
\c datenbank

-- Tabellen auflisten
\dt

-- Schema zeigen
\d tabellenname

-- Beschreiben
\d+ tabellenname

-- Benutzer
\du

-- SQL beenden (shell)
\q
```

### SQL-Abfragen
```sql
-- Alle Zeilen
SELECT * FROM tabelle LIMIT 10;

-- Filtern
SELECT * FROM tabelle WHERE spalte = 'wert';

-- Zählen
SELECT COUNT(*) FROM tabelle;
```

## Backups

```bash
# Alle Datenbanken (schemas + daten)
sudo -u postgres pg_dumpall > /root/.ssa/backups/databases/pg-all-$(date +%Y%m%d).sql

# Einzelne Datenbank
sudo -u postgres pg_dump datenbank > /root/.ssa/backups/databases/db-$(date +%Y%m%d).sql

# Komprimiert
sudo -u postgres pg_dump datenbank | gzip > /root/.ssa/backups/databases/db-$(date +%Y%m%d).sql.gz

# Restore einzelne DB
sudo -u postgres psql -d datenbank < /root/.ssa/backups/databases/db-$(date +%Y%m%d).sql

# Restore alle
sudo -u postgres psql -f /root/.ssa/backups/databases/pg-all-$(date +%Y%m%d).sql postgres
```

## Performance-Tuning

### Wichtige Checks
```sql
-- Connections
SELECT count(*) FROM pg_stat_activity;

-- Auslastung pro DB
SELECT datname, numbackends, xact_commit, xact_rollback FROM pg_stat_database;

-- Laufzeit (Verbindungsstatus)
SELECT pid, state, wait_event_type, query FROM pg_stat_activity WHERE state = 'active';
```

### Langsame Queries
```sql
-- pg_stat_statements (wenn aktiviert)
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
ORDER BY total_time DESC LIMIT 5;
```

### VACUUM (bloat vermeiden)
```bash
# Manuell VACUUM (electrical - safe)
sudo -u postgres vacuumdb --all --analyze
```

```sql
-- Oder in psql
VACUUM;
ANALYZE;
```

### Autovacuum prüfen
```sql
SHOW autovacuum;
SHOW autovacuum_vacuum_scale_factor;
```

## Schema-Management

### Tabellen erstellen (Beispiel)
```sql
CREATE TABLE benutzer (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Indexe
```sql
-- Anzeigen
\d+ tabellenname

-- Erstellen
CREATE INDEX idx_benutzer_email ON benutzer(email);
```

### JSON-Support
```sql
-- JSONB Spalte
CREATE TABLE dokumente (id SERIAL PRIMARY KEY, daten JSONB);

-- Query
SELECT * FROM dokumente WHERE daten->>'name' = 'wert';
```

## WICHTIG: Sicherheit

- **Niemals** `DROP DATABASE` oder `DROP TABLE` ohne Freigabe
- **Niemals** `DELETE FROM` ohne WHERE
- **Backup VOR** jedem Schema-Change
- **VACUUM** regelmäßig (autovacuum sollte normal laufen)
- **pg_dump/pg_restore**: Sicher global, aber DROP vor einzelnem Restore nötig (fragen)

## Fehlerbehandlung

| Fehler | Lösung |
|--------|--------|
| password authentication failed | Benutzer/Passwort prüfen, als postgres einloggen |
| Could not connect | Service prüfen: `systemctl status postgresql` |
| FATAL: too many connections | max_connections erhöhen (fragen), idle killen |
| Permission denied | GRANT Prüfen, als postgres Admin |

## WICHTIG
- **Immer** `sudo -u postgres` für Admin-Operationen
- **pg_stat_statements** nur wenn aktiviert (nicht Standard)
- **Backup-Pflicht** vor Änderungen
- App-Benutzer nie als superuser
