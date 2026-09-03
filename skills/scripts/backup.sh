#!/bin/bash
# OhMyServer - Backup Script
# Usage: bash backup.sh [--dry-run]

DRY_RUN=false
STAMP=$(date +%Y%m%d-%H%M)

if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "🔍 DRY RUN MODE - Nothing will be written"
fi

BACKUP_ROOT="/root/.ssa/backups"
CONFIG_DEST="$BACKUP_ROOT/configs"
DB_DEST="$BACKUP_ROOT/databases"

mkdir -p "$CONFIG_DEST" "$DB_DEST" 2>/dev/null

echo "========================================"
echo "OhMyServer Backup - $STAMP"
echo "========================================"

# Check disk space first
DISK_FREE=$(df -h /root/.ssa | tail -1 | awk '{print $4}')
echo "Backup disk free: $DISK_FREE"

# 1. System Configs
echo -e "\n--- System Configs ---"
if [ "$DRY_RUN" = false ]; then
    tar -czf "$CONFIG_DEST/system-$STAMP.tar.gz" \
        /etc/ssh /etc/nginx /etc/fail2ban 2>/dev/null
    echo "✓ Backup: $CONFIG_DEST/system-$STAMP.tar.gz"
else
    echo "[DRY RUN] Would backup: /etc/ssh /etc/nginx /etc/fail2ban"
fi

# 2. Databases
echo -e "\n--- Databases ---"
if command -v mysqldump &> /dev/null; then
    if [ "$DRY_RUN" = false ]; then
        mysqldump --all-databases > "$DB_DEST/all-$STAMP.sql" 2>/dev/null
        echo "✓ MySQL/MariaDB backup: all-$STAMP.sql"
    else
        echo "[DRY RUN] Would dump MySQL/MariaDB"
    fi
else
    echo "No MySQL/MariaDB found"
fi

if command -v pg_dumpall &> /dev/null; then
    if [ "$DRY_RUN" = false ]; then
        pg_dumpall > "$DB_DEST/pg-$STAMP.sql" 2>/dev/null
        echo "✓ PostgreSQL backup: pg-$STAMP.sql"
    else
        echo "[DRY RUN] Would dump PostgreSQL"
    fi
else
    echo "No PostgreSQL found"
fi

# 3. Website files (if nginx config exists)
echo -e "\n--- Websites ---"
if [ -d "/var/www" ] && [ "$DRY_RUN" = false ]; then
    tar -czf "$BACKUP_ROOT/websites-$STAMP.tar.gz" -C /var/www . 2>/dev/null
    echo "✓ Website files backed up"
elif [ -d "/var/www" ]; then
    echo "[DRY RUN] Would backup /var/www"
else
    echo "No /var/www directory found"
fi

# 4. Verify
echo -e "\n--- Verification ---"
if [ "$DRY_RUN" = false ]; then
    du -sh "$CONFIG_DEST" "$DB_DEST" 2>/dev/null
    find "$BACKUP_ROOT" -name "*$STAMP*" -exec ls -lh {} \;
fi

echo -e "\n========================================"
echo "Backup complete: $STAMP"
echo "========================================"
