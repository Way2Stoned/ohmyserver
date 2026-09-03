#!/bin/bash
# OhMyServer - Datenbank-Check
# Findet alle Datenbanken und prüft ihren Zustand
# Usage: bash db-check.sh [--json]

MODE="text"
[[ "$1" == "--json" ]] && MODE="json"

STAMP=$(date +"%Y-%m-%d %H:%M")

if [ "$MODE" = "json" ]; then
    echo "{ \"timestamp\": \"$STAMP\","
else
    echo "═══ Datenbank-Check — $STAMP ═══"
fi

# ── SQLite Dateien finden (nur App-relevante, keine System-Caches) ──
if [ "$MODE" = "text" ]; then
    echo ""
    echo "── SQLite-Dateien (App-relevant) ──"
fi
SQ_FOUND=0
while IFS= read -r f; do
    SIZE=$(du -h "$f" 2>/dev/null | cut -f1)
    if [ "$MODE" = "json" ]; then
        [ $SQ_FOUND -eq 0 ] && echo "  \"sqlite\": [" || echo ","
        printf '    {"file":"%s","size":"%s"}' "$f" "$SIZE"
    else
        echo "  📄 $f ($SIZE)"
    fi
    SQ_FOUND=$((SQ_FOUND+1))
done < <(find / \( -name "*.sqlite" -o -name "*.db" \) 2>/dev/null \
    | grep -vE "/proc|/sys|/usr/share|/usr/lib|/var/cache|/var/lib/command-not-found|/var/lib/PackageKit|/var/lib/fwupd|/var/lib/snapd|\.local/share/opencode" \
    | head -20)
[ "$MODE" = "json" ] && { [ $SQ_FOUND -gt 0 ] && echo "  ]," || echo "  \"sqlite\": [],"; }

# ── MariaDB/MySQL ──
if [ "$MODE" = "text" ]; then
    echo ""
    echo "── MariaDB/MySQL ──"
fi
if command -v mysql &> /dev/null && systemctl -q is-active mysql 2>/dev/null; then
    DBS=$(mysql -u root -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|mysql\|information\|performance\|sys")
    if [ "$MODE" = "json" ]; then
        echo -n "  \"mariadb_databases\": ["
        FIRST=1
        echo "$DBS" | while read db; do
            [ -n "$db" ] && { [ $FIRST -eq 0 ] && echo -n ","; echo -n "\"$db\""; FIRST=0; }
        done
        echo "],"
    else
        echo "  ✅ MariaDB/MySQL aktiv. Datenbanken:"
        echo "$DBS" | sed 's/^/    - /'
        # Größe
        mysql -u root -e "SELECT table_schema, ROUND(SUM(data_length+index_length)/1024/1024,2) AS size_mb FROM information_schema.tables GROUP BY table_schema;" 2>/dev/null | head -10
    fi
elif [ "$MODE" = "text" ]; then
    echo "  ℹ️  MariaDB/MySQL nicht installiert oder inaktiv"
    [ "$MODE" = "json" ] && echo "  \"mariadb_databases\": []"
fi

# ── PostgreSQL ──
if [ "$MODE" = "text" ]; then
    echo ""
    echo "── PostgreSQL ──"
fi
if command -v psql &> /dev/null && systemctl -q is-active postgresql 2>/dev/null; then
    PG_DBS=$(sudo -u postgres psql -c "SELECT datname FROM pg_database WHERE datistemplate = false;" 2>/dev/null | grep -E "^\s+\w" | tr -d ' ')
    if [ "$MODE" = "json" ]; then
        echo -n "  \"postgres_databases\": ["
        FIRST=1
        echo "$PG_DBS" | while read db; do
            [ -n "$db" ] && { [ $FIRST -eq 0 ] && echo -n ","; echo -n "\"$db\""; FIRST=0; }
        done
        echo "],"
    else
        echo "  ✅ PostgreSQL aktiv. Datenbanken:"
        echo "$PG_DBS" | sed 's/^/    - /'
    fi
elif [ "$MODE" = "text" ]; then
    echo "  ℹ️  PostgreSQL nicht installiert oder inaktiv"
    [ "$MODE" = "json" ] && echo "  \"postgres_databases\": []"
fi

# ── Zusammenfassung ──
if [ "$MODE" = "json" ]; then
    echo "  \"sqlite_count\": $SQ_FOUND"
    echo "}"
else
    echo ""
    echo "── Zusammenfassung ──"
    echo "  SQLite-Dateien : $SQ_FOUND"
    echo "  MariaDB/MySQL  : $([ -n "$DBS" ] && echo "aktiv ($(echo "$DBS" | wc -l) DBs)" || echo "nicht installiert")"
    echo "  PostgreSQL     : $([ -n "$PG_DBS" ] && echo "aktiv ($(echo "$PG_DBS" | wc -l) DBs)" || echo "nicht installiert")"
    echo "═══ Ende ───"
fi
