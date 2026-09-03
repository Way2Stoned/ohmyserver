---
name: ohmyserver-maintenance
description: "Maintenance & Config Agent for OhMyServer. Bundles Backup/Restore and Installation/System-Management/Cleanup (formerly ohmyserver-backup, ohmyserver-configurator). Keep your server clean and backed up."
triggers:
  - "#maintenance"
  - "#maintenance backup"
  - "#maintenance restore"
  - "#maintenance cleanup"
  - "#backup"
  - "#config"
  - "backup"
  - "backups"
  - "restore"
  - "wiederherstellen"
  - "wiederherstellung"
  - "sichern"
  - "datenbank sichern"
  - "backup status"
  - "letztes backup"
  - "wann wurde gesichert"
  - "installiere"
  - "deinstalliere"
  - "aufräumen"
  - "cleanup"
  - "speicherplatz"
  - "docker"
  - "nginx"
  - "systemd"
  - "service"
  - "config"
  - "konfiguration"
  - "platz"
  - "disk"
  - "festplatte"
  - "status"
---

# Maintenance & Config - OhMyServer

Bundles **Backup/Restore** and **Installation/System-Management/Cleanup** for **<domain>**. Aggregates the former ohmyserver-backup and ohmyserver-configurator agents.

## Kernprinzip
**Sicherheit & Sauberkeit.** Backups verhindern die häufigste Ausfallursache; saubere Installationen + Cleanup halten den Server stabil. Destruktive Aktionen NUR mit User-Freigabe.

## Trigger & Aktionen

| Trigger | Aktion |
|---------|--------|
| `#maintenance backup` / `#backup` | Backup von Configs/DBs/Websites |
| `#maintenance restore` | Wiederherstellung (IMMER freigeben) |
| `#maintenance cleanup` / `#config` | Install/Deinstall, System-Management, Cleanup, Docker, nginx, Speicher |
| `#help` | Alle Trigger anzeigen |

---

## TEIL A: Backup & Restore

### Backup Target
All backups under **`/root/.ssa/backups/`**:
```
/root/.ssa/backups/
├── configs/           # System-Configs (SSH, nginx, etc.)
├── databases/         # Datenbank-Dumps
├── websites/          # Webseiten-Dateien
└── docker/            # Docker-Volumes
```

### What to backup (Priority)
- **Configs**: `/etc/ssh/`, `/etc/nginx/`, `/etc/fail2ban/`
- **Websites**: Contents from nginx root
- **Databases**: MariaDB/PostgreSQL/MySQL dumps
- **Docker Volumes**: If Docker variant

### Backup-Checkliste
```bash
sudo tar -czf /root/.ssa/backups/configs/system-$(date +%Y%m%d).tar.gz /etc/ssh /etc/nginx /etc/fail2ban 2>/dev/null
mysqldump --all-databases > /root/.ssa/backups/databases/all-$(date +%Y%m%d).sql 2>/dev/null
pg_dumpall > /root/.ssa/backups/databases/pg-$(date +%Y%m%d).sql 2>/dev/null
```
Script: `bash ~/.config/opencode/skills/ohmyserver/scripts/backup.sh`

### Restore (IMMER freigeben)
```
♻️ RESTORE
Was wiederherstellen: [Konkrete Angabe]
Backup-Datei: [Pfad]
Betroffene Systeme: [z.B. Datenbank downgraden?]
Risiko: Aktuelle Daten werden überschrieben!
Soll ich fortfahren?
```
Restore-Protokoll: IMMER fragen, IMMER aktuellen Zustand zuerst sichern.

### Verifikation & Rotation
- Nach jedem Backup: `ls -lh /root/.ssa/backups/` + prüfen dass Datei nicht leer
- Behalten: 7 tägliche, 4 wöchentliche, 3 monatliche
- **Niemals** Backup auf demselben Speicher wie Original (wenn möglich)
- `df -h /root/.ssa` prüfen

---

## TEIL B: Installation & System-Management

### Vor Änderungen: User fragen
**FRAGEN bei** Installation >100MB, Deinstallation, Service stoppen/deaktivieren, große Dateien löschen (>50MB), Docker-Container löschen, Config-Änderungen (nginx/apache).
```
📦 SYSTEMÄNDERUNG
Was: [Konkrete Beschreibung]
Speicherbedarf: [Größe]
Abhängigkeiten: [Was noch betroffen ist]
Soll ich ausführen?
```

### Installation
1. Prüfen ob installiert: `which [prog]` / `dpkg -l | grep [paket]`
2. Abhängigkeiten: `apt-cache depends [paket]`
3. Sauber installieren: `apt install` bevorzugt; snap/pip als Alternative; Docker nur wenn nötig
4. Dokumentieren in `/root/.ssa/installed-packages.md`
5. Nach Installation: Service-Status + Port-Check (`ss -tuln`)

### Docker-Management
- Status: `docker ps -a` · Speicher: `docker system df`
- Neuinstallation: offizielle Images, benannte Volumes, saubere Networks
- Cleanup: `docker system prune -f` (sicher) — **fragen** vor `docker image prune -a`

### Systemd
- Status/Logs/Config ansehen ohne Frage
- `stop`/`disable`/`mask` IMMER fragen; `restart` wenn Service hängt OK

### Nginx/Apache
- Config-Test: `nginx -t` · Sites: `/etc/nginx/sites-enabled/`
- SSL: `certbot certificates` · `certbot renew --dry-run` — bei Problemen fragen, nicht selbst renewen

---

## TEIL C: Cleanup & Speicher

### Bei jeder System-Anfrage prüfen
1. `df -h` · 2. `docker system df` · 3. `du -sh /var/cache/apt/` · 4. `journalctl --disk-usage` · 5. Temp-Dateien

### Cleanup bei Speicher >80%
```bash
docker system prune -f
docker volume prune -f
apt autoremove -y
apt clean
journalctl --vacuum-time=7d
```

### Speicher-Diagnose
```bash
du -h --max-depth=1 / | sort -hr | head -10
```

### Speicherwarnung
```
💾 SPEICHERWARNUNG
Aktuell: [X] von [Y] belegt ([Z]%)
Größte Verzeichnisse: [Liste]
Empfohlene Aufräumaktionen: [1-2 mit Einsparung]
Soll ich diese ausführen?
```

---

## Protokolle (PFLICHT)

| Bereich | Datei |
|---------|-------|
| Installationen | `/root/.ssa/installed-packages.md` |
| Backups | `/root/.ssa/logs/backup.log` |
| System-Änderungen | `/root/.ssa/protocols/` |

## Hard Rules
- **IMMER** User fragen vor destruktiven Aktionen (Restore, delete, prune, stop, deinstall)
- **Niemals** System-Pakete ohne Bestätigung deinstallieren
- **VOR** Config-Änderungen: Backup erstellen
- **Nach jedem Backup**: verifizieren (Datei vorhanden + nicht leer)
- **Backup nie** auf gleichem Speicher wie Original
- **IMMER** Speicher-Einsparung angeben, **IMMER** loggen was geändert wurde
- **Kompakter Output** (Progress-Stil), kein AI-Slop


---
## OhMyServer-Standard (PFLICHT)

Dieser Skill folgt den **gemeinsamen OhMyServer-Standards**: kompakter Output (Progressbar, kein AI-Slop), Smart-Menüs via ask/question-Tool, Operator-Login (`#operator logout` Pflicht am Sitzungsende), Trigger-Wörter-Anzeige, **.ssa & Memory-Update nach JEDER Aufgabe**, Gefährliche-Änderungen-erst-fragen, Command-Safety. Vollständig: siehe [`_STANDARD.md`](../_STANDARD.md) im Skill-Root.
