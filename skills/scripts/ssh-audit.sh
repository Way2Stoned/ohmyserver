#!/bin/bash
# OhMyServer - SSH-Härtungs-Audit
# Prüft die SSH-Konfiguration gegen Best Practices
# Usage: bash ssh-audit.sh [--json]

MODE="text"
[[ "$1" == "--json" ]] && MODE="json"

STAMP=$(date +"%Y-%m-%d %H:%M")

SSHD="/etc/ssh/sshd_config"
if [ ! -f "$SSHD" ]; then
    echo "sshd_config nicht gefunden: $SSHD"
    exit 1
fi

# Werte auslesen (erste nicht-kommentierte Zeile)
get_val() {
    grep -E "^$1\s" "$SSHD" 2>/dev/null | awk '{print $2}' | head -1
}

ROOT_LOGIN=$(get_val PermitRootLogin)
PASS_AUTH=$(get_val PasswordAuthentication)
PUB_AUTH=$(get_val PubkeyAuthentication)
PORT=$(get_val Port)
MAX_TRIES=$(get_val MaxAuthTries)
ALLOW_USERS=$(get_val AllowUsers)

if [ "$MODE" = "json" ]; then
    echo "{"
    echo "  \"timestamp\": \"$STAMP\","
    echo "  \"permit_root_login\": \"${ROOT_LOGIN:-nicht gesetzt}\","
    echo "  \"password_auth\": \"${PASS_AUTH:-nicht gesetzt}\","
    echo "  \"pubkey_auth\": \"${PUB_AUTH:-nicht gesetzt}\","
    echo "  \"port\": \"${PORT:-22}\","
    echo "  \"max_auth_tries\": \"${MAX_TRIES:-nicht gesetzt}\","
    echo "  \"allow_users\": \"${ALLOW_USERS:-nicht gesetzt}\""
    echo "}"
else
    echo "═══ SSH-Härtungs-Audit — $STAMP ═══"
    echo ""
    echo "── Aktuelle Config ──"
    echo "  PermitRootLogin      : ${ROOT_LOGIN:-nicht gesetzt (Default: prohibit-password)}"
    echo "  PasswordAuthentication : ${PASS_AUTH:-nicht gesetzt (Default: yes = SCHWACH)}"
    echo "  PubkeyAuthentication : ${PUB_AUTH:-nicht gesetzt}"
    echo "  Port                 : ${PORT:-22}"
    echo "  MaxAuthTries         : ${MAX_TRIES:-nicht gesetzt}"
    echo "  AllowUsers           : ${ALLOW_USERS:-nicht gesetzt}"
    echo ""
    echo "── Best-Practice-Check ──"
    PASS=0; FAIL=0

    # Root-Login
    if [ "$ROOT_LOGIN" = "no" ] || [ "$ROOT_LOGIN" = "prohibit-password" ]; then
        echo "  ✅ PermitRootLogin: sicher"
        PASS=$((PASS+1))
    else
        echo "  ❌ PermitRootLogin: ${ROOT_LOGIN:-default} UNSICHER (root darf sich einloggen)"
        FAIL=$((FAIL+1))
    fi

    # Passwort-Auth
    if [ "$PASS_AUTH" = "no" ]; then
        echo "  ✅ PasswordAuthentication: aus (nur SSH-Keys)"
        PASS=$((PASS+1))
    else
        echo "  ❌ PasswordAuthentication: ${PASS_AUTH:-default=yes} UNSICHER (Passwort-Login erlaubt)"
        FAIL=$((FAIL+1))
    fi

    # Pubkey
    if [ "$PUB_AUTH" = "yes" ] || [ -z "$PUB_AUTH" ]; then
        echo "  ✅ PubkeyAuthentication: aktiv"
        PASS=$((PASS+1))
    else
        echo "  ❌ PubkeyAuthentication: aus - SSH-Keys deaktiviert!"
        FAIL=$((FAIL+1))
    fi

    # AllowUsers
    if [ -n "$ALLOW_USERS" ]; then
        echo "  ✅ AllowUsers: eingeschränkt auf: $ALLOW_USERS"
        PASS=$((PASS+1))
    else
        echo "  ⚠️  AllowUsers: nicht gesetzt (jeder User kann versuchen)"
    fi

    echo ""
    echo "── ERGEBNIS ──"
    echo "  Bestanden: $PASS  |  Zu beheben: $FAIL"
    if [ "$FAIL" -gt 0 ]; then
        echo "  ⚠️  SSH-Konfiguration ist nicht gehärtet. UPA/SSA-Skill für Fix nötig (fragen)."
    else
        echo "  ✅ SSH gut gehärtet"
    fi
fi
