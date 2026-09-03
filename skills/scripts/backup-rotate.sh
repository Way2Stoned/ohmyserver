#!/bin/bash
# OhMyServer - Backup Rotation
# Behält nur die nötigen Backups, löscht alte (mit dry-run!)
# Usage: bash backup-rotate.sh [--dry-run] [--keep-days N]

DRY_RUN=false
KEEP_DAYS=7
for a in "$@"; do
    case "$a" in
        --dry-run) DRY_RUN=true ;;
        --keep-days=*) KEEP_DAYS="${a#--keep-days=}" ;;
    esac
done

BACKUP_ROOT="/root/.ssa/backups"

if [ "$DRY_RUN" = true ]; then
    echo "🔍 DRY RUN - Zeige was gelöscht würde, lösche nichts"
fi

echo "═══ Backup-Rotation (Keep: ${KEEP_DAYS}d) — $(date +%Y-%m-%d) ═══"

# Finde alte Backups (älter als KEEP_DAYS)
echo ""
echo "── Backups älter als ${KEEP_DAYS} Tage ──"
OLD_FILES=$(find "$BACKUP_ROOT" -type f -mtime +"$KEEP_DAYS" 2>/dev/null)

if [ -z "$OLD_FILES" ]; then
    echo "  ✅ Keine alten Backups (${KEEP_DAYS}d) gefunden"
else
    echo "$OLD_FILES" | while read f; do
        SIZE=$(du -h "$f" | cut -f1)
        echo "  🗑️  $f ($SIZE)"
    done

    # Platz, der frei würde
    TOTAL=$(echo "$OLD_FILES" | xargs du -ch 2>/dev/null | tail -1 | cut -f1)
    echo "  Würde freigeben: $TOTAL"

    if [ "$DRY_RUN" = false ]; then
        echo ""
        echo "── Lösche alte Backups ──"
        echo "$OLD_FILES" | while read f; do
            rm -f "$f"
            echo "  ✅ gelöscht: $f"
        done
        echo "  Fertig."
    else
        echo ""
        echo "  [DRY RUN] Nichts gelöscht."
    fi
fi

# Aktuelle Backups anzeigen
echo ""
echo "── Aktuelle Backups ──"
du -sh "$BACKUP_ROOT" 2>/dev/null
find "$BACKUP_ROOT" -type f -mtime -"$KEEP_DAYS" 2>/dev/null | while read f; do
    echo "  📄 $(du -h "$f" | cut -f1)  ${f#$BACKUP_ROOT/}"
done

echo ""
echo "═══ Ende ───"
