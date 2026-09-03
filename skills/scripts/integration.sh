#!/bin/bash
# OhMyServer - Integration Master Scan
# Führt alle Checks aus & konsolidiert zu einem Gesamt-Report
# Usage: bash integration.sh [--json] [--quick]
#   --quick  : nur Status + kritische Checks (schneller)
#   --full   : alle Checks (langsamer)
#   --json   : maschinenlesbar

MODE="text"
LEVEL="full"
for a in "$@"; do
    case "$a" in
        --json) MODE="json" ;;
        --quick) LEVEL="quick" ;;
        --full) LEVEL="full" ;;
    esac
done

SCRIPTS="/root/.config/opencode/skills/ohmyserver/scripts"
STAMP=$(date +"%Y-%m-%d %H:%M")

# ── Sammle Ausgaben aller Scripts ──
STATUS_OUT=$($SCRIPTS/status.sh --json 2>/dev/null)
SEC_OUT=$($SCRIPTS/log-scan.sh --hours=24 --json 2>/dev/null)
SVC_OUT=$($SCRIPTS/service-audit.sh --json 2>/dev/null)
DISK_OUT=$($SCRIPTS/disk-report.sh --json 2>/dev/null)

if [ "$LEVEL" = "full" ]; then
    DB_OUT=$($SCRIPTS/db-check.sh --json 2>/dev/null)
    USR_OUT=$($SCRIPTS/user-scan.sh --json 2>/dev/null)
    UPD_OUT=$($SCRIPTS/update-scan.sh --json 2>/dev/null)
fi

# ── Parse kritische Werte ──
DISK_PCT=$(echo "$DISK_OUT" | grep -oE '"disk_pct": [0-9]+' | grep -oE '[0-9]+')
MEM_PCT=$(echo "$SVC_OUT" | grep -oE '"mem_pct": [0-9]+' | grep -oE '[0-9]+')
SSH_FAILS=$(echo "$SEC_OUT" | grep -oE '"ssh_failed_attempts": [0-9]+' | grep -oE '[0-9]+')
DOWN_COUNT=$(echo "$SVC_OUT" | grep -cE '"inactive"|"failed"')
DOWN_COUNT=${DOWN_COUNT:-0}

# ── Ausgabe ──
if [ "$MODE" = "json" ]; then
    echo "{"
    echo "  \"integration_report\": {"
    echo "    \"timestamp\": \"$STAMP\","
    echo "    \"quick\": \"$([ $LEVEL = quick ] && echo true || echo false)\","
    echo "    \"disk_pct\": ${DISK_PCT:-0},"
    echo "    \"mem_pct\": ${MEM_PCT:-0},"
    echo "    \"ssh_failures_24h\": ${SSH_FAILS:-0},"
    echo "    \"services_down\": ${DOWN_COUNT:-0}"
    echo "  }"
    echo "}"
else
    echo "══════════════════════════════════════════"
    echo "  OhMyServer INTEGRATION REPORT — $STAMP"
    echo "══════════════════════════════════════════"
    echo ""
    echo "── KERN-GESUNDHEIT ──"
    echo "  Disk: ${DISK_PCT}%  |  RAM: ${MEM_PCT}%  |  SSH-Failures(24h): ${SSH_FAILS}"
    echo "  Dienste down: ${DOWN_COUNT}"
    echo ""
    echo "── WARNUNGEN ──"
    WARN=0
    [ "${DISK_PCT:-0}" -gt 85 ] && { echo "  ⚠️ Disk fast voll"; WARN=1; }
    [ "${MEM_PCT:-0}" -gt 85 ] && { echo "  ⚠️ RAM fast voll"; WARN=1; }
    [ "${SSH_FAILS:-0}" -gt 20 ] && { echo "  ⚠️ Viele SSH-Failures"; WARN=1; }
    [ "${DOWN_COUNT:-0}" -gt 0 ] && { echo "  🔴 Dienste down"; WARN=1; }
    [ "$WARN" -eq 0 ] && echo "  ✅ Keine kritischen Warnungen"
    echo ""
    echo "── DETAILS (einzelne Scripts) ──"
    echo "  ▶ status.sh       : $SCRIPTS/status.sh"
    echo "  ▶ log-scan.sh     : $SCRIPTS/log-scan.sh --hours=24"
    echo "  ▶ service-audit.sh: $SCRIPTS/service-audit.sh"
    echo "  ▶ disk-report.sh  : $SCRIPTS/disk-report.sh"
    if [ "$LEVEL" = "full" ]; then
        echo "  ▶ db-check.sh     : $SCRIPTS/db-check.sh"
        echo "  ▶ user-scan.sh    : $SCRIPTS/user-scan.sh"
        echo "  ▶ update-scan.sh  : $SCRIPTS/update-scan.sh"
    fi
    echo ""
    echo "Gib ein einzelnes Script an für Details, z.B.:"
    echo "  bash $SCRIPTS/status.sh"
    echo "══════════════════════════════════════════"
fi
