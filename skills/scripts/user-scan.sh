#!/bin/bash
# OhMyServer - User & Permission Scanner
# Prüft alle User-Accounts, Permissions, sudo-Rechte, SSH
# Usage: bash user-scan.sh [--json]

MODE="text"
[[ "$1" == "--json" ]] && MODE="json"

STAMP=$(date +"%Y-%m-%d %H:%M")

if [ "$MODE" = "json" ]; then
    echo "{"
    echo "  \"timestamp\": \"$STAMP\","
else
    echo "═══ User & Permission Scan — $STAMP ═══"
fi

# ── 1. User mit Login-Shell ──
if [ "$MODE" = "json" ]; then
    echo "  \"login_users\": ["
    FIRST=1
    grep -E "/(bash|sh|zsh)$" /etc/passwd | while IFS=: read -r u x uid gid d s; do
        [ $FIRST -eq 0 ] && echo ","
        printf '    {"user":"%s","uid":%s,"home":"%s","shell":"%s"}' "$u" "$uid" "$d" "$s"
        FIRST=0
    done
    echo ""
    echo "  ],"
else
    echo ""
    echo "── User mit Login-Shell ──"
    grep -E "/(bash|sh|zsh)$" /etc/passwd | cut -d: -f1,3,6,7 | sed 's/:/  /g'
fi

# ── 2. Sudo-Rechte ──
if [ "$MODE" = "json" ]; then
    echo -n "  \"sudo_users\": ["
    sudo_users=$(getent group sudo | cut -d: -f4)
    echo -n "\"$sudo_users\""
    echo "],"
else
    echo ""
    echo "── Sudo-Berechtigte ──"
    echo "  $(getent group sudo | cut -d: -f4)"
fi

# ── 3. UID 0 (KRITISCH) ──
if [ "$MODE" = "json" ]; then
    echo -n "  \"uid0_users\": ["
    FIRST=1
    awk -F: '$3 == 0 {print $1}' /etc/passwd | while read u; do
        [ $FIRST -eq 0 ] && echo -n ","
        echo -n "\"$u\""
        FIRST=0
    done
    echo "],"
else
    echo ""
    echo "── UID 0 Sicherheits-Check ──"
    awk -F: '$3 == 0 {print "  ⚠️  "$1" (sollte NUR root sein)"}' /etc/passwd
fi

# ── 4. Leere Passwörter (KRITISCH) ──
EMPTY_PASS=$(sudo awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null)
if [ "$MODE" = "json" ]; then
    echo -n "  \"empty_password_users\": ["
    FIRST=1
    echo "$EMPTY_PASS" | while read u; do
        [ -n "$u" ] && { [ $FIRST -eq 0 ] && echo -n ","; echo -n "\"$u\""; FIRST=0; }
    done
    echo "],"
else
    echo ""
    echo "── Leere-Passwort-Check (KRITISCH) ──"
    if [ -n "$EMPTY_PASS" ]; then
        echo "  🔴 User mit leerem Passwort: $EMPTY_PASS"
    else
        echo "  ✅ Keine leeren Passwörter gefunden"
    fi
fi

# ── 5. Letzte Logins ──
if [ "$MODE" = "json" ]; then
    echo -n "  \"recent_logins\": ["
    LAST=$(last -n 10 2>/dev/null | awk '{print $1}' | sort -u | tr '\n' ',' | sed 's/,$//')
    echo -n "\"$LAST\""
    echo ""
    echo "}"
else
    echo ""
    echo "── Letzte Logins ──"
    last -n 10 2>/dev/null | head -10
fi

echo ""
[ "$MODE" = "text" ] && echo "═══ Ende ───"
