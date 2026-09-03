#!/bin/bash
# OhMyServer - Health Check Script
# Usage: bash health-check.sh

echo "========================================"
echo "OhMyServer Health Check - $(date)"
echo "========================================"

# System Load
echo -e "\n--- System Load ---"
uptime
LOAD=$(cat /proc/loadavg | awk '{print $1}')
CPUS=$(nproc)
RATIO=$(echo "scale=2; $LOAD / $CPUS" | bc)
echo "Load average: $LOAD (1-min), CPUs: $CPUS, Ratio: $RATIO"
if (( $(echo "$RATIO > 0.7" | bc -l) )); then
    echo "⚠️ HIGH LOAD DETECTED ($RATIO ratio)"
else
    echo "✅ Load OK"
fi

# Memory
echo -e "\n--- Memory ---"
free -h
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_PCT=$(( MEM_USED * 100 / MEM_TOTAL ))
echo "Memory used: $MEM_PCT%"
if [ "$MEM_PCT" -gt 85 ]; then
    echo "⚠️ HIGH MEMORY ($MEM_PCT%)"
else
    echo "✅ Memory OK"
fi

# Disk
echo -e "\n--- Disk ---"
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
echo "Root disk used: $DISK_PCT%"
if [ "$DISK_PCT" -gt 85 ]; then
    echo "⚠️ DISK ALMOST FULL ($DISK_PCT%)"
else
    echo "✅ Disk OK"
fi

# Top processes
echo -e "\n--- Top CPU Processes ---"
ps aux --sort=-%cpu | head -5

# Top Memory processes
echo -e "\n--- Top Memory Processes ---"
ps aux --sort=-%mem | head -5

# Services
echo -e "\n--- Services ---"
for svc in ssh nginx docker mysql fail2ban; do
    if systemctl list-units --type=service 2>/dev/null | grep -q "$svc.service"; then
        STATUS=$(systemctl is-active $svc)
        echo "$svc: $STATUS"
    fi
done

echo -e "\n--- Errors in Logs (last 50) ---"
journalctl -p 3 -n 20 --no-pager 2>/dev/null | tail -20 || echo "No journal"

echo -e "\n========================================"
echo "Health check complete: $(date)"
echo "========================================"
