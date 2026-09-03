#!/bin/bash
# OhMyServer - Disk-Report
# Analysiert Speicher-Nutzung & schlägt Cleanup vor
# Usage: bash disk-report.sh [--json]

MODE="text"
[[ "$1" == "--json" ]] && MODE="json"

STAMP=$(date +"%Y-%m-%d %H:%M")

if [ "$MODE" = "json" ]; then
    echo "{ \"timestamp\": \"$STAMP\","
else
    echo "═══ Disk-Report — $STAMP ═══"
fi

# ── Übersicht ──
DISK_USED=$(df / | tail -1 | awk '{print $3}')
DISK_AVAIL=$(df / | tail -1 | awk '{print $4}')
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')

if [ "$MODE" = "json" ]; then
    echo "  \"disk_pct\": $DISK_PCT,"
    echo "  \"disk_used\": \"$DISK_USED\","
    echo "  \"disk_avail\": \"$DISK_AVAIL\","
else
    echo ""
    echo "── Übersicht ──"
    echo "  Belegt: $DISK_USED | Frei: $DISK_AVAIL | $DISK_PCT%"
    if [ "$DISK_PCT" -gt 85 ]; then
        echo "  🔴 KRITISCH - Fast voll!"
    elif [ "$DISK_PCT" -gt 70 ]; then
        echo "  ⚠️  Warnung - Aufräumen empfohlen"
    else
        echo "  ✅ Disk-Status OK"
    fi
fi

# ── Größte Verzeichnisse ──
TOP_DIRS=$(timeout 30 du -h --max-depth=1 / 2>/dev/null | sort -hr | head -10)
if [ "$MODE" = "json" ]; then
    echo -n "  \"largest_dirs\": ["
    FIRST=1
    echo "$TOP_DIRS" | while read size path; do
        [ -n "$path" ] && { [ $FIRST -eq 0 ] && echo -n ","; printf '{"path":"%s","size":"%s"}' "$path" "$size"; FIRST=0; }
    done
    echo "],"
else
    echo ""
    echo "── Größte Verzeichnisse ──"
    echo "$TOP_DIRS" | sed 's/^/    /'
fi

# ── Größte Dateien ──
TOP_FILES=$(timeout 30 find / -type f -size +50M 2>/dev/null | grep -vE "proc|sys" | head -10)
if [ "$MODE" = "json" ]; then
    echo -n "  \"largest_files\": ["
    FIRST=1
    echo "$TOP_FILES" | while read f; do
        [ -n "$f" ] && { [ $FIRST -eq 0 ] && echo -n ","; s=$(du -h "$f" 2>/dev/null | cut -f1); printf '{"file":"%s","size":"%s"}' "$f" "$s"; FIRST=0; }
    done
    echo "],"
else
    echo ""
    echo "── Größte Dateien (>50M) ──"
    if [ -n "$TOP_FILES" ]; then
        while read f; do
            s=$(du -h "$f" 2>/dev/null | cut -f1)
            echo "    $s  $f"
        done <<< "$TOP_FILES"
    else
        echo "  (keine Dateien >50M gefunden)"
    fi
fi

# ── Log-Dateien ──
LOG_SIZE=$(timeout 20 du -sh /var/log/ 2>/dev/null | cut -f1)
JOURNAL_SIZE=$(timeout 20 sudo journalctl --disk-usage 2>/dev/null | tail -1)

if [ "$MODE" = "json" ]; then
    echo "  \"log_dir_size\": \"$LOG_SIZE\","
    echo "  \"journal_size\": \"$JOURNAL_SIZE\""
    echo "}"
else
    echo ""
    echo "── Logs ──"
    echo "  /var/log/ : $LOG_SIZE"
    echo "  Journal   : $JOURNAL_SIZE"
    echo ""
    echo "── Cleanup-Empfehlung ──"
    [ "$DISK_PCT" -gt 70 ] && echo "  ▶ Führe aus: bash cleanup.sh --dry-run (SCA-Skill)"
    echo "  ▶ Bei Platzmangel: bash backup-rotate.sh --dry-run"
    echo "═══ Ende ───"
fi
