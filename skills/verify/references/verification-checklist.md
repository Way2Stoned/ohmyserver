# VQA - Verifikations-Checklist (je Domäne)

Konkrete Checks, die der Verify & Quality Agent nach jedem Aufgabentyp ausführt.

## 1. Service / Installation

```bash
# Läuft der Service?
systemctl is-active nginx       # → "active"

# Antworte ich lokal?
curl -I http://localhost        # → HTTP/1.1 200

# Port offen?
ss -tuln | grep :80             # → zeigt PORT

# Kein Fehler in Logs?
journalctl -u nginx -n 20 --no-pager | grep -iE "error|fail" || echo "clean"
```

**ERFOLG**: Service active + HTTP 2xx + Port offen + keine Fehler-Logs

## 2. Config-Änderung (nginx, ssh, etc.)

```bash
# 1. Config-Test (KRITISCH - nie reload ohne Test)
sudo nginx -t                   # → "test is successful"
# ODER
sudo sshd -t                    # für SSH

# 2. Erst dann Reload
sudo systemctl reload nginx

# 3. Dann verifizieren
systemctl is-active nginx
curl -I http://localhost
```

**ERFOLG**: `-t` erfolgreich + Service aktiv + Antwortet

## 3. Datenbank

### MariaDB/MySQL
```bash
# Tabelle existiert
mysql -u root -e "SHOW TABLES IN db;" | grep tabelle

# Daten einfügen + lesen (Roundtrip!)
mysql -u root -e "INSERT INTO db.t (c) VALUES ('test'); SELECT * FROM db.t;"
# → Wert erscheint
```

### SQLite
```bash
sqlite3 db.sqlite ".tables"         # Tabelle da
sqlite3 db.sqlite "SELECT * FROM t;"  # Daten da
```

### PostgreSQL
```bash
sudo -u postgres psql -d db -c "\dt"      # Tabellen
sudo -u postgres psql -d db -c "SELECT count(*) FROM t;"
```

**ERFOLG**: Tabelle da + Daten Roundtrip funktioniert

## 4. Backup

```bash
# Datei existiert UND nicht leer
ls -lh /root/.ssa/backups/databases/*.sql
du -sh /root/.ssa/backups/

# Dump lesbar prüfen
head -20 /root/.ssa/backups/databases/latest.sql | grep -i "create\|insert" || echo "WARNUNG: leer/invalid"
```

**ERFOLG**: Datei da + nicht leer + Inhalt plausibel

## 5. User & Permission

```bash
# User existiert
getent passwd benutzer        # → zeigt Zeile

# In sudo-Gruppe (falls erwartet)
getent group sudo | grep benutzer

# SSH-Key-Permissions korrekt
stat -c "%a" /home/benutzer/.ssh/authorized_keys  # → 600

# Shell korrekt
getent passwd benutzer | cut -d: -f7   # → /bin/bash oder /usr/sbin/nologin
```

**ERFOLG**: User da + richtig in Gruppen + korrekte Shell + Key-Perms 600

## 6. Firewall / Port

```bash
# Port offen wie gewollt
ss -tuln | grep :80

# Zum testen von außen (falls erlaubt)
curl -I http://talebergh.art
```

**ERFOLG**: Port offen + von außen erreichbar (nur testen was freigegeben)

## 7. Update / Patching

```bash
# Version installiert
apt list --installed | grep paket

# Service danach noch aktiv
systemctl is-active [service]

# Kein kaputter Dependency
apt check
```

**ERFOLG**: Neue Version + Service aktiv + apt check OK

## 8. Cleanup

```bash
# Disk freigegeben
df -h / | tail -1    # vorher vs. nachher vergleichen

# Kein Service kaputt durch cleanup
for s in nginx docker ssh; do systemctl is-active $s; done

# Docker-Cleanup verifizieren
docker system df
```

**ERFOLG**: Mehr freier Platz + alle Dienste noch aktiv

## 9. Sicherheits-Check (SSA)

```bash
# SSH-Config gehärtet?
grep -E "PermitRootLogin|PasswordAuthentication" /etc/ssh/sshd_config

# Ports minimal?
ss -tuln | grep -vE "127.0.0.1|::1"

# Fail2Ban aktiv?
systemctl is-active fail2ban
```

**ERFOLG**: Root-login no + nur nötige Ports + fail2ban aktiv

## Generelle VQA-Regeln

1. **NICHT** nur Exit-Code 0 checken - Funktionalität testen
2. **IMMER** Roundtrip testen (schreiben+lesen bei DB)
3. **IMMER** Service nach Änderung neu prüfen
4. **IMMER** Logs auf Fehler scannen
5. **IMMER** gegen User-Erwartung (nicht nur "es geht irgendwie")
6. **Beweis** liefern (konkrete Ausgabe, nicht "sollte ok sein")
