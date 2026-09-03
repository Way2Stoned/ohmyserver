#!/usr/bin/env bash
# OhMyServer Memory-Migration: .ssa/operators/memory.md -> MariaDB memory_entries
# Nutzung: memory-migrate.sh [--dry-run]
# Zweistufig (98%-Ansatz): Preview in Kontext, Volltext on-demand aus DB.
set -euo pipefail

MARIADB_USER="ohmyserver"
MARIADB_DB="ohmyserver"
CRED_FILE="${CRED_FILE:-$HOME/.ssa/credentials/mariadb-ohmyserver.txt}"
SRC_FILE="${SRC_FILE:-$HOME/.ssa/operators/memory.md}"
OPERATOR_NAME="${OPERATOR_NAME:-talbergh}"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

log() { printf '✓ %s\n' "$1"; }
warn() { printf '⚠ %s\n' "$1"; }

if [ ! -f "$CRED_FILE" ]; then die "Keine Credentials: $CRED_FILE"; fi
PASS=$(awk -F': ' '/^password:/{print $2}' "$CRED_FILE")
if [ -z "$PASS" ]; then echo "✗ Kein Passwort in $CRED_FILE"; exit 1; fi
if [ ! -f "$SRC_FILE" ]; then echo "✗ Quell-Memory fehlt: $SRC_FILE"; exit 1; fi

OP_ID=$(mariadb -u "$MARIADB_USER" -h 127.0.0.1 -p"$PASS" "$MARIADB_DB" -N -e "SELECT id FROM operators WHERE name='$OPERATOR_NAME';" 2>/dev/null | head -1)
if [ -z "$OP_ID" ]; then
  echo "✗ Operator '$OPERATOR_NAME' nicht in DB (Dashboard noch nie gestartet?)"
  exit 1
fi
log "Operator '$OPERATOR_NAME' (id=$OP_ID)"

import_line() {
  local ts cat content preview
  ts="$1"; cat="$2"; content="$3"
  preview="${content:0:150}"
  if [ "$DRY_RUN" = "1" ]; then
    printf '  [%s] %s: %s\n' "$ts" "$cat" "$preview"
    return
  fi
  mariadb -u "$MARIADB_USER" -h 127.0.0.1 -p"$PASS" "$MARIADB_DB" -e \
    "INSERT INTO memory_entries (operator_id, category, content_preview, content_full, importance_score) VALUES ($OP_ID, '$cat', '$(printf %s "$preview" | sed "s/'/''/g")', '$(printf %s "$content" | sed "s/'/''/g")', 0.5);" 2>/dev/null
}

prefs_done=0
log "Lese $SRC_FILE"
if [ "$DRY_RUN" = "1" ]; then echo "  (Dry-Run - keine DB-Änderungen)"; fi

while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%$'\r'}"
  # - [timestamp] text
  if [[ "$line" =~ ^-\ \[([0-9-]+[ ]?[0-9:]*)\]\ (.*)$ ]]; then
    ts="${BASH_REMATCH[1]}"; rest="${BASH_REMATCH[2]}"
    cat="episodic"
    case "$rest" in
      *Anforderung*|*Idee*|*Constraint*|*MariaDB*|*eingerichtet*|*Dashboard*) cat="semantic" ;;
    esac
    import_line "$ts" "$cat" "$rest"
    continue
  fi
  # Präferenzen-Zeilen unter "## Präferenzen"
  if [[ "$line" =~ ^-\ (Output-Stil|Kein AI-Slop|Smart-Menüs|Name:|Seit:) ]]; then
    [ "$prefs_done" = "0" ] && { import_line "2026-09-03" "preference" "Präferenz: $line"; prefs_done=1; }
    continue
  fi
done < "$SRC_FILE"

[ "$DRY_RUN" = "1" ] && { echo "Dry-Run beendet."; exit 0; }
COUNT=$(mariadb -u "$MARIADB_USER" -h 127.0.0.1 -p"$PASS" "$MARIADB_DB" -N -e "SELECT COUNT(*) FROM memory_entries WHERE operator_id=$OP_ID;" 2>/dev/null)
log "Migration fertig. memory_entries gesamt: $COUNT"
echo "[$(date -u +%F_%T)] memory-migrate: $COUNT Eintraege fuer '$OPERATOR_NAME' importiert aus $SRC_FILE" >> "$HOME/.ssa/logs/database.log"
