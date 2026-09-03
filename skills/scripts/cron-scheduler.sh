#!/bin/bash
# OhMyServer - Cron-Scheduler & Auto-Checks Setup
# Richtet automatische regelmäßige Checks ein
# Usage: bash cron-scheduler.sh [install|remove|status]

SCRIPTS="/root/.config/opencode/skills/ohmyserver/scripts"
LOG="/root/.ssa/logs"
CRON_LINE_PREFIX="# OhMyServer Auto-Checks (von cron-scheduler.sh verwaltet)"

ACTION="${1:-status}"

# Stelle sicher dass Log-Ordner existiert
mkdir -p "$LOG"

case "$ACTION" in
    install)
        echo "═══ Installiere OhMyServer Auto-Checks ═══"
        # Entferne alte OhMyServer-Cron-Zeilen zuerst
        crontab -l 2>/dev/null | grep -v "OhMyServer\|\.ssa/logs\|$SCRIPTS" | crontab -
        # Füge neue hinzu
        (
            crontab -l 2>/dev/null
            echo "$CRON_LINE_PREFIX"
            echo "# Stündlich: Security-Scan (SSH-Failures)"
            echo "0 * * * * $SCRIPTS/log-scan.sh --hours=1 >> $LOG/cron.log 2>&1"
            echo "# Täglich: Status + Disk-Report"
            echo "0 6 * * * $SCRIPTS/status.sh --json >> $LOG/cron-status.log 2>&1"
            echo "30 6 * * * $SCRIPTS/disk-report.sh >> $LOG/cron-disk.log 2>&1"
            echo "# Täglich: Sicherheits-Scan"
            echo "0 7 * * * $SCRIPTS/log-scan.sh --hours=24 >> $LOG/cron-security.log 2>&1"
            echo "# Täglich: Update-Scan"
            echo "0 8 * * * $SCRIPTS/update-scan.sh >> $LOG/cron-updates.log 2>&1"
            echo "# Wöchentlich: Backup (Sonntag 4 Uhr)"
            echo "0 4 * * 0 $SCRIPTS/backup.sh >> $LOG/cron-backup.log 2>&1"
        ) | crontab -
        echo "✅ Installiert. Aktive Cron-Jobs:"
        crontab -l | grep -v "^#" | grep -v "^$"
        echo ""
        echo "Logs in: $LOG/cron-*.log"
        ;;

    remove)
        echo "═══ Entferne OhMyServer Auto-Checks ═══"
        crontab -l 2>/dev/null | grep -v "OhMyServer\|\.ssa/logs\|$SCRIPTS" | crontab -
        echo "✅ Entfernt."
        ;;

    status)
        echo "═══ OhMyServer Cron-Status ═══"
        if crontab -l 2>/dev/null | grep -q "$SCRIPTS"; then
            echo "✅ Auto-Checks sind aktiv. Jobs:"
            crontab -l | grep "$SCRIPTS" | sed 's/^/  /'
        else
            echo "ℹ️  Auto-Checks NICHT installiert."
            echo "  ▶ Installiere mit: bash cron-scheduler.sh install"
        fi
        ;;
    *)
        echo "Usage: bash cron-scheduler.sh [install|remove|status]"
        ;;
esac
