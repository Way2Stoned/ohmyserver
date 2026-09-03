# Command-Safety-Cheatsheet / Schnell-Referenz

Beispielhafte Befehlssätze, die in OhMyServer-Operationen vorkommen, mit **sicherer** (non-stuck) Form.

## System-/Status-Commands

| Zweck | SICHER (non-stuck) | UNSICHER (hängend) |
|-------|--------------------|--------------------|
| Prozessliste | `ps aux --sort=-%cpu \| head -15` | `top` |
| Logs ansehen | `tail -n 50 /var/log/syslog` | `less /var/log/syslog` |
| Live-Log folgen | `timeout 10 tail -f /var/log/syslog` | `tail -f ...` (endlos) |
| Service-Status | `systemctl status nginx --no-pager` | - |
| Großer Scan | `timeout 120 bash security-scan.sh` | (ohne Limit) |

## Datenbank-Commands (KRITISCH)

| Zweck | SICHER | UNSICHER (HÄNGT) |
|-------|--------|-------------------|
| MySQL-Query | `mysql -u root -e "SELECT 1;"` | `mysql -u root` |
| MySQL-Restore | `mysql < /tmp/db.sql` | `mysql` interaktiv |
| Postgres-Query | `psql -U postgres -d db -c "..."` | `psql -U postgres` |
| SQLite-Query | `sqlite3 db.sqlite "..."` | `sqlite3 db.sqlite` |
| Dump | `mysqldump --all-databases > file.sql` | - |

**MERKE**: Jede DB-CLI ohne `-e`/`-c`/Query im Argument öffnet eine interaktive Shell → **HÄNGT**.

## Interaktive CLIs komplett vermeiden

Diese öffnen UI-Loops und hängen in Automatisierung:
`vim`, `nano`, `emacs`, `less`, `more`, `htop`, `top`, `tail -f`, `watch`, `ssh` (ohne Command), `mysql` (ohne -e), `psql` (ohne -c), `sqlite3` (ohne Query), `docker run -it`, `apt` (interaktive Prompts → nutze `-y`)

## apt/Install (interaktive Prompts vermeiden)

```bash
# INTERAKTIVE Prompts bei apt → mit -y NICHT-interaktiv machen
apt install -y nginx          # OK
apt upgrade -y                # OK (aber vorher fragen!)
# NICHT:  apt install nginx   # Fragt nach Bestätigung → hängt

# DEBIAN_FRONTEND für dpkg-Prompts
DEBIAN_FRONTEND=noninteractive apt install -y postfix
```

## Timeout-Tabelle

| Command-Typ | Empfohlener `timeout` |
|-------------|----------------------|
| `ls`, `df`, `cat` | Kein nötig (instant) |
| `apt list`, `systemctl status` | 30s |
| `apt update` | 60s |
| `apt install` | 120s |
| `apt upgrade` | 300s |
| `backup.sh` | 300s |
| `docker pull` | 300s |
| `mysqldump` groß | 300s |

## Abschluss-Check-Muster

```bash
# In if-Abfrage
if timeout 60 systemctl restart nginx 2>/dev/null; then
    echo "✅ nginx restarted"
else
    echo "❌ nginx restart FAILED"
fi

# Oder exit-code explizit
timeout 60 command
RC=$?
[ $RC -eq 0 ] && echo "✅" || echo "❌ (exit $RC)"
[ $RC -eq 124 ] && echo "(TIMEOUT - hing!)"
```

## Stuck-Prozess behandeln

```bash
# Prozess-IDs finden
pgrep -f "backup.sh"

# Graceful stoppen
pkill -TERM -f "backup.sh"
sleep 5

# Force stoppen falls nötig
pkill -KILL -f "backup.sh"

# Prüfen ob wirklich tot
pgrep -f "backup.sh" || echo "✅ beendet"
```

## WICHTIG Zusammenfassung
1. **Nie** interaktive CLI direkt
2. **Immer** timeout bei nicht-instanten
3. **Exit-Code prüfen** nach allem
4. **Graceful** vor brutal
5. **Prüfen** ob Prozess schon läuft vor Neu-Start
