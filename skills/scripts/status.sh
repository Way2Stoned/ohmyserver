#!/bin/bash
# OhMyServer - Status Report
# Gibt kompakten Gesamt-Status des Servers aus
# Usage: bash status.sh [--full] [--json]

MODE="compact"
if [[ "$1" == "--full" ]]; then MODE="full"; fi
if [[ "$1" == "--json" ]]; then MODE="json"; fi

STAMP=$(date +"%Y-%m-%d %H:%M")

if [ "$MODE" = "json" ]; then
    echo "{"
    echo "  \"timestamp\": \"$STAMP\","
else
    echo "═══ OhMyServer Status — $STAMP ═══"
fi

# ── System ──
UPTIME=$(uptime -p | sed 's/up //')
LOAD=$(cat /proc/loadavg | awk '{print $1}')
CPUS=$(nproc)
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_PCT=$(( MEM_USED * 100 / MEM_TOTAL ))

if [ "$MODE" = "json" ]; then
    echo "  \"system\": {\"uptime\": \"$UPTIME\", \"load\": \"$LOAD/$CPUS\", \"disk\": ${DISK_PCT}, \"mem\": ${MEM_PCT}},"
else
    echo ""
    echo "── SYSTEM ──"
    echo "  Uptime : $UPTIME"
    echo "  Load   : $LOAD / $CPUS"
    echo "  Disk   : ${DISK_PCT}%"
    echo "  Mem    : ${MEM_PCT}%"
fi

# ── Services ──
if [ "$MODE" = "json" ]; then
    echo "  \"services\": {"
    FIRST=1
    for svc in ssh nginx docker mysql mariadb postgresql fail2ban certbot; do
        if systemctl list-units --type=service 2>/dev/null | grep -q "$svc.service"; then
            ST=$(systemctl is-active $svc)
            [ $FIRST -eq 0 ] && echo ","
            printf '    "%s": "%s"' "$svc" "$ST"
            FIRST=0
        fi
    done
    echo ""
    echo "  },"
else
    echo ""
    echo "── SERVICES ──"
    DOWN=0
    for svc in ssh nginx docker mysql mariadb postgresql fail2ban certbot; do
        if systemctl list-units --type=service 2>/dev/null | grep -q "$svc.service"; then
            ST=$(systemctl is-active $svc)
            if [ "$ST" = "active" ]; then
                echo "  ✅ $svc"
            else
                echo "  🔴 $svc ($ST)"
                DOWN=$((DOWN+1))
            fi
        fi
    done
fi

# ── Security ──
FAILED=$(sudo journalctl -u ssh --since "24 hours ago" 2>/dev/null | grep -c "Failed" 2>/dev/null)
FAILED="${FAILED:-0}"
if command -v fail2ban-client &> /dev/null; then
    BANNED=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}')
    BANNED_TOTAL=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Total banned" | awk '{print $NF}')
    FB="aktiv"
else
    BANNED="n/a"; BANNED_TOTAL="n/a"; FB="nicht installiert"
fi

if [ "$MODE" = "json" ]; then
    echo "  \"security\": {\"failed_ssh_24h\": ${FAILED:-0}, \"banned_now\": \"$BANNED\", \"banned_total\": \"$BANNED_TOTAL\"},"
else
    echo ""
    echo "── SECURITY ──"
    echo "  SSH-Failures (24h): ${FAILED:-0}"
    echo "  Fail2Ban          : $FB (banned: $BANNED jetzt / $BANNED_TOTAL gesamt)"
fi

# ── Updates ──
if command -v apt &> /dev/null; then
    UPDLIST=$(apt list --upgradable 2>/dev/null | grep -E "upgradable")
    ALL_UPDATES=$(echo "$UPDLIST" | grep -c "upgradable")
    SEC_UPDATES=$(echo "$UPDLIST" | grep -c "security")
    ALL_UPDATES="${ALL_UPDATES:-0}"
    SEC_UPDATES="${SEC_UPDATES:-0}"
    if [ "$MODE" = "json" ]; then
        echo "  \"updates\": {\"available\": $ALL_UPDATES, \"security\": $SEC_UPDATES}"
    else
        echo ""
        echo "── UPDATES ──"
        echo "  Verfügbar : $ALL_UPDATES (davon $SEC_UPDATES sicherheitsrelevant)"
    fi
fi

if [ "$MODE" = "json" ]; then
    echo "}"
else
    echo ""
    echo "═══ Ende Status ───"
    echo ""
    # Warnungen hervorheben
    WARN=""
    [ "$DISK_PCT" -gt 85 ] && WARN="$WARN\n  ⚠️ Disk fast voll (${DISK_PCT}%)"
    [ "$MEM_PCT" -gt 85 ] && WARN="$WARN\n  ⚠️ RAM fast voll (${MEM_PCT}%)"
    [ "${FAILED:-0}" -gt 20 ] && WARN="$WARN\n  ⚠️ Viele SSH-Failures (${FAILED})"
    [ "${DOWN:-0}" -gt 0 ] && WARN="$WARN\n  🔴 ${DOWN} Dienst(e) down"
    [ "${SEC_UPDATES:-0}" -gt 0 ] 2>/dev/null && WARN="$WARN\n  🔴 ${SEC_UPDATES} Sicherheits-Updates offen"
    [ -n "$WARN" ] && echo -e "Warnungen:$WARN\n"
fi
