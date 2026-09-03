#!/bin/bash
# OhMyServer - Service-Audit
# Prüft alle Dienste, Ports, Ressourcen-Auslastung
# Usage: bash service-audit.sh [--json]

MODE="text"
[[ "$1" == "--json" ]] && MODE="json"

STAMP=$(date +"%Y-%m-%d %H:%M")

if [ "$MODE" = "json" ]; then
    echo "{ \"timestamp\": \"$STAMP\","
else
    echo "═══ Service-Audit — $STAMP ═══"
fi

# ── Dienste-Status ──
SERVICES="ssh nginx apache2 docker mysql mariadb postgresql fail2ban redis-server certbot"

if [ "$MODE" = "json" ]; then
    echo "  \"services\": {"
    FIRST=1
    for svc in $SERVICES; do
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
    echo "── Dienste ──"
    DOWN=0
    for svc in $SERVICES; do
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
    echo "  Dienste down: $DOWN"
fi

# ── Offene Ports ──
if [ "$MODE" = "json" ]; then
    echo -n "  \"open_ports\": ["
    FIRST=1
    ss -tuln 2>/dev/null | grep LISTEN | grep -vE "127.0.0.1|::1" | awk '{print $5}' | grep -oE ":[0-9]+$" | cut -d: -f2 | sort -u | while read p; do
        [ -n "$p" ] && { [ $FIRST -eq 0 ] && echo -n ","; echo -n "\"$p\""; FIRST=0; }
    done
    echo "],"
else
    echo ""
    echo "── Offene Ports (extern) ──"
    ss -tuln 2>/dev/null | grep LISTEN | grep -vE "127.0.0.1|::1" | awk '{print $5}' | sort -u | sed 's/^/    /'
fi

# ── Ressourcen ──
LOAD=$(cat /proc/loadavg | awk '{print $1}')
CPUS=$(nproc)
MEM_PCT=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')

if [ "$MODE" = "json" ]; then
    echo "  \"resources\": {\"load\": \"$LOAD/$CPUS\", \"mem_pct\": $MEM_PCT, \"disk_pct\": $DISK_PCT}"
    echo "}"
else
    echo ""
    echo "── Ressourcen ──"
    echo "  Load : $LOAD / $CPUS"
    echo "  RAM   : ${MEM_PCT}%"
    echo "  Disk  : ${DISK_PCT}%"
    echo ""
    echo "── Warnungen ──"
    [ "$MEM_PCT" -gt 85 ] && echo "  ⚠️  RAM hoch (${MEM_PCT}%)"
    [ "$DISK_PCT" -gt 85 ] && echo "  ⚠️  Disk hoch (${DISK_PCT}%)"
    echo "$LOAD" | awk -v c="$CPUS" '{ if ($1 > c*0.7) print "  ⚠️  Hohe CPU-Last" }'
    [ "$DOWN" -gt 0 ] && echo "  🔴 $DOWN Dienst(e) down"
    echo "═══ Ende ───"
fi
