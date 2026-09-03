# Storage-Management für talbergh.art

## Kern-Befehle

### Festplatten-Nutzung
```bash
# Übersicht aller Mounts
df -h

# Inodes (wichtig! Dateien können voll sein obwohl Platz da ist)
df -i

# Größte Verzeichnisse finden
du -h --max-depth=1 / | sort -hr | head -15

# Größte Dateien finden
find / -type f -size +100M 2>/dev/null | head -20
```

### Mounts & Partitionen
```bash
# Alle Block-Geräte
lsblk

# Mounts
mount | column -t

# Partitions-Tabellen
sudo fdisk -l
```

### LVM (falls genutzt)
```bash
# Physische Volumes
sudo pvs

# Volume Groups
sudo vgs

# Logical Volumes
sudo lvs

# LVM erweitern (ANAT - kein Platz mehr!)
sudo lvextend -L +10G /dev/vg/root
sudo resize2fs /dev/vg/root
```

## Storage-Health

### SMART (Hardware-Diagnose)
```bash
# SMART-Status (falls SSD/HDD)
sudo smartctl -a /dev/sda  # Pfad anpassen

# Kurztest
sudo smartctl -t short /dev/sda

# Ergebnis
sudo smartctl -l selftest /dev/sda
```

**WICHTIG**: Meldet User sofort wenn SMART Fehler zeigt - das ist ein Frühlkill-Fall!

### RAID (falls genutzt)
```bash
# RAID-Status
cat /proc/mdstat

# Detail-Info
sudo mdadm --detail /dev/md0  # Pfad anpassen
```

## Storage-Intern

### Temp-Dateien
```bash
# Temp-Cleanup (bei Platzmangel)
sudo find /tmp -type f -atime +7 -delete 2>/dev/null

# Journal (systemd-Logs) rotieren
sudo journalctl --vacuum-time=7d
```

### SQLite-Dateien effizient nutzen
```bash
# SQLite WAL aktivieren (weniger I/O)
sqlite3 db.sqlite "PRAGMA journal_mode=WAL;"
```

## Backup-Speicher-Prüfung

```bash
# Backup-Disk überwachen
df -h /root/.ssa

# Alte Backups prüfen (Löschen nur mit Freigabe)
ls -lh /root/.ssa/backups/
```

## Empfehlungs-Muster bei Platzmangel

```
💾 STORAGE-WARNUNG
Disk: [X]/[Y] belegt ([Z]%)
Inodes: [X]/[Y] belegt

Größte Verzeichnisse:
- [Größe] [Pfad]
- [Größe] [Pfad]

Vorschlag:
1. [Aktion] - spart [Größe]
2. [Aktion] - spart [Größe]

Soll ich ausführen?
```

## WICHTIG
- **Niemals** Dateien löschen ohne Freigabe (außer klar temp)
- **Niemals** LVM erweitern ohne Freigabe (kann Mounts beeinflussen)
- **Niemals** SMART/RAID ignorieren - sofort melden
- **Backup-Pflicht** vor Storage-Änderungen
- Bei SQLite-Volumen > 2GB: MariaDB/PostgreSQL empfehlen
