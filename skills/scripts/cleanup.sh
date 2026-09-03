#!/bin/bash
# OhMyServer - Cleanup Script
# Usage: bash cleanup.sh [--dry-run]

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "🔍 DRY RUN MODE - Nothing will be deleted"
fi

echo "========================================"
echo "OhMyServer Cleanup - $(date)"
echo "========================================"

# Disk Usage
echo -e "\n--- Current Disk Usage ---"
df -h / | tail -1

# Docker Cleanup
echo -e "\n--- Docker Cleanup ---"
if command -v docker &> /dev/null; then
    echo "Docker images: $(docker images -q | wc -l)"
    echo "Docker containers: $(docker ps -a -q | wc -l)"
    if [ "$DRY_RUN" = false ]; then
        docker system prune -f 2>/dev/null
        echo "Pruned unused Docker resources"
    else
        echo "[DRY RUN] Would run: docker system prune -f"
    fi
else
    echo "Docker not installed, skipping"
fi

# Apt Cleanup
echo -e "\n--- Apt Cleanup ---"
if [ "$DRY_RUN" = false ]; then
    sudo apt autoremove -y 2>/dev/null
    sudo apt clean 2>/dev/null
    echo "Cleaned apt cache"
else
    echo "[DRY RUN] Would run: apt autoremove && apt clean"
fi

# Journal Logs
echo -e "\n--- Log Cleanup ---"
if [ "$DRY_RUN" = false ]; then
    sudo journalctl --vacuum-time=7d 2>/dev/null
    echo "Vacuumed logs older than 7 days"
else
    echo "[DRY RUN] Would run: journalctl --vacuum-time=7d"
fi

# Temp Files
echo -e "\n--- Temp Files ---"
TEMP_COUNT=$(find /tmp -type f -atime +7 2>/dev/null | wc -l)
echo "Old temp files (>7 days): $TEMP_COUNT"
if [ "$DRY_RUN" = false ] && [ "$TEMP_COUNT" -gt 0 ]; then
    find /tmp -type f -atime +7 -delete 2>/dev/null
    echo "Deleted old temp files"
fi

# Summary
echo -e "\n--- After Cleanup ---"
df -h / | tail -1

echo -e "\n========================================"
echo "Cleanup complete: $(date)"
echo "========================================"
