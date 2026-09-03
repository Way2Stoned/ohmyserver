# MariaDB / MySQL - Datenbank-Management

## Grundlagen

MariaDB und MySQL sind Client/Server-Datenbanken. Fast identisch in Nutzung.

**Zugriff**: `mysql -u root -p` (Passwort) oder ohne -p wenn root via socket (Ubuntu).

## Verbindung

```bash
# Als root
sudo mysql   # Ubuntu root hat i.d.R. kein Passwort (auth_socket)

# Mit Benutzer
mysql -u benutzer -p

# Remote (selten, nicht empfohlen)
mysql -h <host> -u benutzer -p
```

## Häufige Befehle

### Datenbanken & Tabellen
```sql
-- Alle Datenbanken
SHOW DATABASES;

-- Wechseln
USE datenbank;

-- Tabellen auflisten
SHOW TABLES;

-- Schema einer Tabelle
DESCRIBE tabelle;
-- oder
SHOW CREATE TABLE tabelle;
```

### Einfache Abfragen
```sql
-- Alle Zeilen
SELECT * FROM tabelle LIMIT 10;

-- Mit Filter
SELECT * FROM tabelle WHERE spalte = 'wert';

-- Zählen
SELECT COUNT(*) FROM tabelle;
```

### Benutzerverwaltung
```sql
-- Benutzer auflisten
SELECT User, Host FROM mysql.user;

-- Neuen Benutzer (nur mit Freigabe!)
CREATE USER 'neuer'@'localhost' IDENTIFIED BY 'sicheres_passwort';
GRANT SELECT, INSERT, UPDATE ON datenbank.* TO 'neuer'@'localhost';
FLUSH PRIVILEGES;
```

## Backups

```bash
# Alle Datenbanken
mysqldump --all-databases > /root/.ssa/backups/databases/all-$(date +%Y%m%d).sql

# Einzelne Datenbank
mysqldump datenbank > /root/.ssa/backups/databases/db-$(date +%Y%m%d).sql

# Komprimiert
mysqldump --all-databases | gzip > /root/.ssa/backups/databases/all-$(date +%Y%m%d).sql.gz

# Restore
mysql < /root/.ssa/backups/databases/all-$(date +%Y%m%d).sql
# oder für einzelne DB
mysql datenbank < /root/.ssa/backups/databases/db-$(date +%Y%m%d).sql
```

## Performance-Tuning

### Wichtige Variablen prüfen
```sql
-- Aktuelle Werte
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW VARIABLES LIKE 'max_connections';
SHOW VARIABLES LIKE 'query_cache_type';

-- Status
SHOW STATUS LIKE 'Slow_queries';
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Innodb_buffer_pool_read%';
```

### Wichtige Empfehlungen
- **innodb_buffer_pool_size**: 50-60% des RAM (wenn DB dediziert nutzt, sonst weniger)
- **max_connections**: Nur erhöhen wenn nötig (max 100-150 pro Standard)
- **query_cache**: Meistens DEAKTIVIERT (Contention bei writes)

### Slow-Query-Log aktivieren
```sql
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 0.5;  -- 0.5 Sekunden Schwelle
```

Dann analysieren: `/var/log/mysql/mariadb-slow.log`

### Indexe optimieren
```sql
-- Indexe einer Tabelle entfernen/neu
SHOW INDEX FROM tabelle;

-- Index-Hinweis (nur Expert, nicht vorschnell)
EXPLAIN SELECT ...;  -- Prüfen ob Index genutzt wird
```

## Tabellen-Optimierung

```sql
-- Tabellen defragmentieren (Platz freigeben)
OPTIMIZE TABLE tabelle;

-- MariaDB: Table-Check
CHECK TABLE tabelle;
```

## Sicherheit

- **Root nur lokal** - nie als root über Netzwerk
- **Keine Weak-Passwörter** für DB-Benutzer
- **Backup vor JEDEM Schema-Change**
- **Keine** `DROP`/`DELETE` ohne WHERE ohne Freigabe

## Fehlerbehandlung

| Fehler | Lösung |
|--------|--------|
| Access denied | Benutzer/Berechtigungen prüfen, root nutzen |
| Too many connections | max_connections erhöhen (fragen!), Prozesse killen |
| 1064 syntax error | SQL prüfen, Query-String Quoting |
| Out of disk space | Backup-Cleanup, Log-Rotation |

## WICHTIG
- **Backup vor** Migration/Update (100% Pflicht)
- **Niemals** DROP DATABASE ohne Freigabe
- **Disk-Usage** im Auge behalten (InnoDB kann viel Platz fressen)
