#!/bin/bash
# OhMyServer - Verify All
# VQA: Verifiziert den Gesamtzustand des Servers nach Aufgaben
# Prüft ob alles wie erwartet läuft (empirisch, nicht raten)
# Usage: bash verify-all.sh [--json]

MODE="text"
[[ "$1" == "--json" ]] && MODE="json"

STAMP=$(date +"%Y-%m-%d %H:%M")
PASS=0
FAIL=0
FAILURES=""

if [ "$MODE" = "json" ]; then
    echo "{ \"timestamp\": \"$STAMP\","
    echo "  \"checks\": ["
else
    echo "═══ OhMyServer VERIFY-ALL — $STAMP ═══"
    echo "(Empirische Verifikation des Gesamtzustands)"
fi

FIRST=1
report() {
    local name="$1" status="$2" detail="$3"
    if [ "$MODE" = "json" ]; then
        [ $FIRST -eq 0 ] && echo ","
        printf '    {"check":"%s","status":"%s","detail":"%s"}' "$name" "$status" "$detail"
        FIRST=0
    else
        if [ "$status" = "PASS" ]; then
            echo "  ✅ $name"
            PASS=$((PASS+1))
        else
            echo "  ❌ $name — $detail"
            FAIL=$((FAIL+1))
            FAILURES="$FAILURES\n  ❌ $name — $detail"
        fi
    fi
}

# ── 1. SSH läuft ──
SSH_ST=$(systemctl is-active ssh 2>/dev/null)
if [ "$SSH_ST" = "active" ]; then report "SSH-Dienst" "PASS" "aktiv"; else report "SSH-Dienst" "FAIL" "$SSH_ST"; fi

# ── 2. Nginx/Apache ──
if systemctl list-units --type=service 2>/dev/null | grep -qE "nginx|apache2"; then
    WEB=$(systemctl is-active nginx 2>/dev/null || systemctl is-active apache2 2>/dev/null)
    if [ "$WEB" = "active" ]; then
        HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null)
        if [ "$HTTP" = "200" ] || [ "$HTTP" = "301" ]; then
            report "Webserver" "PASS" "aktiv, HTTP $HTTP"
        else
            report "Webserver" "FAIL" "läuft aber HTTP $HTTP"
        fi
    else
        report "Webserver" "FAIL" "$WEB" | sed 's/^/    /'
    fi
fi

# ── 3. Disk-Space ──
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
if [ "$DISK_PCT" -le 85 ]; then report "Disk-Space" "PASS" "${DISK_PCT}%"; else report "Disk-Space" "FAIL" "${DISK_PCT}% voll"; fi

# ── 4. RAM ──
MEM_PCT=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
if [ "$MEM_PCT" -le 85 ]; then report "RAM" "PASS" "${MEM_PCT}%"; else report "RAM" "FAIL" "${MEM_PCT}%"; fi

# ── 5. Fail2Ban ──
if systemctl list-units --type=service 2>/dev/null | grep -q "fail2ban"; then
    F2B=$(systemctl is-active fail2ban)
    if [ "$F2B" = "active" ]; then report "Fail2Ban" "PASS" "aktiv"; else report "Fail2Ban" "FAIL" "$F2B"; fi
fi

# ── 6. SSH-Failures ──
SSH_FAILS=$(timeout 20 sudo journalctl -u ssh --since "24 hours ago" 2>/dev/null | grep -c "Failed")
if [ "${SSH_FAILS:-0}" -le 20 ]; then report "SSH-Angriffe" "PASS" "$SSH_FAILS in 24h"; else report "SSH-Angriffe" "FAIL" "$SSH_FAILS in 24h"; fi

# ── 7. Crash-Log-Prüfung ──
CRASHES=$(timeout 20 sudo journalctl -p err --since "24 hours ago" 2>/dev/null | grep -cE "segfault|panic|oom-kill")
if [ "${CRASHES:-0}" -eq 0 ]; then report "Crash-Check" "PASS" "keine"; else report "Crash-Check" "FAIL" "$CRASHES kritische Ereignisse"; fi

# ── 8. Updates ──
if command -v apt &> /dev/null; then
    UPD=$(timeout 20 apt list --upgradable 2>/dev/null | grep -c "upgradable")
    if [ "${UPD:-0}" -eq 0 ]; then report "Updates" "PASS" "System aktuell"; else report "Updates" "FAIL" "$UPD offen"; fi
fi

# ── Abschluss ──
if [ "$MODE" = "json" ]; then
    echo ""
    echo "  ],"
    echo "  \"pass\": $PASS,"
    echo "  \"fail\": $FAIL"
    echo "}"
else
    echo ""
    echo "── ERGEBNIS ──"
    echo "  Bestanden: $PASS | Fehlgeschlagen: $FAIL"
    if [ "$FAIL" -gt 0 ]; then
        echo "  Fehler:"
        echo -e "$FAILURES"
        echo "  → Weitere Analyse nötig (VQA zurückleiten)"
    else
        echo "  ✅ ALLE CHECKS BESTANDEN - Server ist gesund"
    fi
fi
