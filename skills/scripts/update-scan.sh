#!/bin/bash
# OhMyServer - Update-Scanner
# Zeigt Updates mit Sicherheits-Priorisierung
# Usage: bash update-scan.sh [--json]

MODE="text"
[[ "$1" == "--json" ]] && MODE="json"

STAMP=$(date +"%Y-%m-%d %H:%M")

if ! command -v apt &> /dev/null; then
    echo "apt nicht verfügbar"
    exit 1
fi

# Aktualisiere Paketliste (mit timeout um hängen zu vermeiden)
timeout 60 sudo apt update -qq 2>/dev/null

# apt list liefert "Listing..." Zeile; echte Pakete enden auf "/... upgradable"
UPDLIST=$(timeout 30 apt list --upgradable 2>/dev/null | grep -E "upgradable" | grep -v "^Listing" || true)

SEC_COUNT=0
ALL_COUNT=0
SEC_PKGS=""
ALL_PKGS=""

while IFS= read -r line; do
    [ -z "$line" ] && continue
    pkg=${line%%/*}
    ALL_COUNT=$((ALL_COUNT+1))
    ALL_PKGS="$ALL_PKGS $pkg"
    # Heuristik: sicherheitsrelevante Pakete
    if echo "$pkg" | grep -qiE "openssl|openssh|libssl|libc6|nginx|apache|docker|mysql|mariadb|postgres|php|python|curl|wget|sudo|systemd|kernel|linux"; then
        SEC_COUNT=$((SEC_COUNT+1))
        SEC_PKGS="$SEC_PKGS $pkg"
    fi
done <<< "$UPDLIST"

if [ "$MODE" = "json" ]; then
    echo "{"
    echo "  \"timestamp\": \"$STAMP\","
    echo "  \"total_updates\": $ALL_COUNT,"
    echo "  \"security_relevant_updates\": $SEC_COUNT,"
    echo "  \"security_packages\": [\"$(echo $SEC_PKGS | sed 's/ /\",\"/g')\"],"
    echo "  \"all_packages\": [\"$(echo $ALL_PKGS | sed 's/ /\",\"/g')\"]"
    echo "}"
else
    echo "═══ Update-Scan — $STAMP ═══"
    echo ""
    echo "── Verfügbare Updates ──"
    if [ "$ALL_COUNT" -eq 0 ]; then
        echo "  ✅ System ist aktuell"
    else
        echo "  📦 $ALL_COUNT Updates verfügbar"
    fi
    echo ""
    echo "── Sicherheitsrelevante (Priorität) ──"
    if [ "$SEC_COUNT" -eq 0 ]; then
        echo "  ✅ Keine offenen Sicherheits-Updates"
    else
        echo "  🔴 $SEC_COUNT sicherheitsrelevant:"
        echo "$SEC_PKGS" | tr ' ' '\n' | sed 's/^/    - /'
    fi
    echo ""
    echo "── Alle Pakete ──"
    echo "$ALL_PKGS" | tr ' ' '\n' | sed 's/^/    /'
    echo ""
    echo "⚠️  Hinweis: Installiere Updates nur mit UPA-Skill (Frage nötig)."
fi
