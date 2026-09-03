# Storage Management for <domain>

## Core Commands

### Disk Usage
```bash
# Overview All Mounts
df -h

# Inodes (Important! Files Can Be Full Despite Free Space)
df -i

# Largest Directories
du -h --max-depth=1 / | sort -hr | head -15

# Largest Files
find / -type f -size +100M 2>/dev/null | head -20
```

### Mounts & Partitions
```bash
# All Block Devices
lsblk

# Mounts
mount | column -t

# Partition Tables
sudo fdisk -l
```

### LVM (If Used)
```bash
# Physical Volumes
sudo pvs

# Volume Groups
sudo vgs

# Logical Volumes
sudo lvs

# Extend LVM (ANAT - No More Space!)
sudo lvextend -L +10G /dev/vg/root
sudo resize2fs /dev/vg/root
```

## Storage Health

### SMART (Hardware Diagnosis)
```bash
# SMART Status (If SSD/HDD)
sudo smartctl -a /dev/sda  # Adjust Path

# Short Test
sudo smartctl -t short /dev/sda

# Result
sudo smartctl -l selftest /dev/sda
```

**IMPORTANT**: Alert User Immediately If SMART Shows Errors - That's an Early Kill Case!

### RAID (If Used)
```bash
# RAID Status
cat /proc/mdstat

# Detail Info
sudo mdadm --detail /dev/md0  # Adjust Path
```

## Storage Internals

### Temp Files
```bash
# Temp Cleanup (When Low Space)
sudo find /tmp -type f -atime +7 -delete 2>/dev/null

# Journal (systemd Logs) Rotate
sudo journalctl --vacuum-time=7d
```

### Use SQLite Files Efficiently
```bash
# Enable SQLite WAL (Less I/O)
sqlite3 db.sqlite "PRAGMA journal_mode=WAL;"
```

## Backup Storage Check

```bash
# Monitor Backup Disk
df -h /root/.ssa

# Check Old Backups (Delete Only With Approval)
ls -lh /root/.ssa/backups/
```

## Recommendation Pattern on Low Space

```
💾 STORAGE WARNING
Disk: [X]/[Y] Used ([Z]%)
Inodes: [X]/[Y] Used

Largest Directories:
- [Size] [Path]
- [Size] [Path]

Proposal:
1. [Action] - Saves [Size]
2. [Action] - Saves [Size]

Should I Execute?
```

## IMPORTANT
- **Never** Delete Files Without Approval (Except Clearly Temp)
- **Never** Extend LVM Without Approval (Can Affect Mounts)
- **Never** Ignore SMART/RAID - Alert Immediately
- **Backup Required** Before Storage Changes
- For SQLite Volume > 2GB: Recommend MariaDB/PostgreSQL
