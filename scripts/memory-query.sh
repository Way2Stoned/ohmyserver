#!/usr/bin/env bash
# OhMyServer Memory-Query: MariaDB memory_entries on-demand Retrieval
# Nutzung:
#   memory-query.sh list                    # Preview aller Eintraege (Kompakt)
#   memory-query.sh search "<query>"        # FULLTEXT-Suche (nur Preview)
#   memory-query.sh detail <id>             # Volltext eines Eintrags (access_count++)
#   memory-query.sh add <cat> <text>        # Neuer Eintrag (preview auto aus text)
#   memory-query.sh set-importance <id> <0..1>
set -euo pipefail

MARIADB_USER="ohmyserver"
MARIADB_DB="ohmyserver"
CRED_FILE="${CRED_FILE:-$HOME/.ssa/credentials/mariadb-ohmyserver.txt}"

# Operator-Name aus Env/server.json/OS-User (max. portabel)
if [ -z "${OPERATOR_NAME:-}" ] && [ -f "$HOME/.ssa/server.json" ]; then
  OPERATOR_NAME="$(grep -o '"user"[^,]*' "$HOME/.ssa/server.json" 2>/dev/null | head -1 | sed 's/.*: *"//; s/"//')"
fi
OPERATOR_NAME="${OPERATOR_NAME:-$USER}"

[ -f "$CRED_FILE" ] || { echo "✗ Keine Credentials: $CRED_FILE"; exit 1; }
PASS=$(awk -F': ' '/^password:/{print $2}' "$CRED_FILE")
[ -n "$PASS" ] || { echo "✗ Kein Passwort in $CRED_FILE"; exit 1; }

DB() { mariadb -u "$MARIADB_USER" -h 127.0.0.1 -p"$PASS" "$MARIADB_DB" -N -e "$1" 2>/dev/null; }

OP_ID=$(DB "SELECT id FROM operators WHERE name='$OPERATOR_NAME';" | head -1)
[ -n "$OP_ID" ] || { echo "✗ Operator '$OPERATOR_NAME' nicht in DB"; exit 1; }

case "${1:-}" in
  list)
    DB "SELECT id, category, ROUND(importance_score,2), access_count, LEFT(content_preview,60) FROM memory_entries WHERE operator_id=$OP_ID ORDER BY importance_score DESC, id DESC;"
    ;;
  search)
    [ -n "${2:-}" ] || { echo "✗ Nutzung: memory-query.sh search \"<query>\""; exit 1; }
    q=$(printf %s "$2" | sed "s/'/''/g")
    DB "SELECT id, category, LEFT(content_preview,60) FROM memory_entries WHERE operator_id=$OP_ID AND MATCH(content_preview, content_full) AGAINST ('$q' IN BOOLEAN MODE) ORDER BY importance_score DESC LIMIT 10;"
    ;;
  detail)
    [ -n "${2:-}" ] || { echo "✗ Nutzung: memory-query.sh detail <id>"; exit 1; }
    id="$2"
    DB "UPDATE memory_entries SET access_count=access_count+1 WHERE id=$id AND operator_id=$OP_ID;" >/dev/null
    DB "SELECT content_full FROM memory_entries WHERE id=$id AND operator_id=$OP_ID;"
    ;;
  add)
    [ -n "${3:-}" ] || { echo "✗ Nutzung: memory-query.sh add <category> <text>"; exit 1; }
    cat="$2"; text="$3"
    preview="${text:0:150}"
    esc_text=$(printf %s "$text" | sed "s/'/''/g")
    esc_preview=$(printf %s "$preview" | sed "s/'/''/g")
    DB "INSERT INTO memory_entries (operator_id, category, content_preview, content_full, importance_score) VALUES ($OP_ID, '$cat', '$esc_preview', '$esc_text', 0.5); SELECT LAST_INSERT_ID();"
    ;;
  set-importance)
    [ -n "${3:-}" ] || { echo "✗ Nutzung: memory-query.sh set-importance <id> <0..1>"; exit 1; }
    DB "UPDATE memory_entries SET importance_score=${3} WHERE id=${2} AND operator_id=$OP_ID;" >/dev/null
    echo "✓ importance gesetzt"
    ;;
  *)
    echo "Nutzung: memory-query.sh {list|search|detail|add|set-importance}"
    exit 1
    ;;
esac
