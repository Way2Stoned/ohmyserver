#!/bin/bash
# OhMyServer - Log & Security Scanner
# Sucht verdächtige Aktivitäten in Logs
# Usage: bash log-scan.sh [--hours N] [--json]

HOURS=24
MODE="text"

for a in "$@"; do
    case "$a" in
        --json) MODE="json" ;;
        --hours=*) HOURS="${a#--hours=}" ;;
    esac
done

STAMP=$(date +"%Y-%m-%d %H:%M")

if [ "$MODE" = "json" ]; then
    echo "{ \"timestamp\": \"$STAMP\", \"hours\": $HOURS,"
else
    echo "═══ Log & Security-Scan (letzte ${HOURS}h) — $STAMP ═══"
fi

# ── SSH-Failures ──
SSH_FAILS=$(timeout 30 sudo journalctl -u ssh --since "$HOURS hours ago" 2>/dev/null | grep -c "Failed")
SSH_SUCCESS=$(timeout 30 sudo journalctl -u ssh --since "$HOURS hours ago" 2>/dev/null | grep -c "Accepted")

# Top-Angreifer-IPs
TOP_IPS=$(timeout 30 sudo journalctl -u ssh --since "$HOURS hours ago" 2>/dev/null | grep "Failed password" | grep -oE "from [0-9.]+" | awk '{print $2}' | sort | uniq -c | sort -rn | head -5)

if [ "$MODE" = "json" ]; then
    echo "  \"ssh_failed_attempts\": $SSH_FAILS,"
    echo "  \"ssh_successful_logins\": $SSH_SUCCESS,"
    echo -n "  \"top_attack_ips\": ["
    FIRST=1
    echo "$TOP_IPS" | while read count ip; do
        [ -n "$ip" ] && { [ $FIRST -eq 0 ] && echo -n ","; printf '{"ip":"%s","attempts":%s}' "$ip" "$count"; FIRST=0; }
    done
    echo "],"
else
    echo ""
    echo "── SSH-Aktivität ──"
    echo "  Fehlgeschlagen: $SSH_FAILS"
    echo "  Erfolgreich  : $SSH_SUCCESS"
    if [ -n "$TOP_IPS" ]; then
        echo "  Top-Angreifer:"
        echo "$TOP_IPS" | sed 's/^/    /'
    fi
fi

# ── Auth-Fehler (sudo, su) ──
AUTH_ERRS=$(timeout 20 sudo journalctl --since "$HOURS hours ago" 2>/dev/null | grep -cE "sudo.*failure|authentication failure|invalid user")
if [ "$MODE" = "json" ]; then
    echo "  \"auth_errors\": $AUTH_ERRS,"
else
    echo ""
    echo "── Auth-Fehler ──"
    echo "  $AUTH_ERRS Fehler (sudo/su/invalid user)"
fi

# ── System-Fehler ──
SYS_ERRS=$(timeout 20 sudo journalctl -p err --since "$HOURS hours ago" 2>/dev/null | wc -l)
ERR_SAMPLE=$(timeout 20 sudo journalctl -p err --since "$HOURS hours ago" 2>/dev/null | head -10)
if [ "$MODE" = "json" ]; then
    echo "  \"system_errors\": $SYS_ERRS"
    echo "}"
else
    echo ""
    echo "── System-Fehler (letzte ${HOURS}h) ──"
    if [ "$SYS_ERRS" -eq 0 ]; then
        echo "  ✅ Keine Systemfehler"
    else
        echo "  ${SYS_ERRS} Fehler gefunden (Sample):"
        echo "$ERR_SAMPLE" | sed 's/^/    /'
    fi
    echo ""
    echo "═══ Ende ───"
fi
