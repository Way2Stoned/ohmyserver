#!/bin/bash
# OhMyServer - Security Quick Check
# Usage: bash security-scan.sh

echo "========================================"
echo "OhMyServer Security Check - $(date)"
echo "========================================"

# System Info
echo -e "\n--- System ---"
cat /etc/os-release | head -3
echo "Uptime: $(uptime -p)"

# SSH Status
echo -e "\n--- SSH ---"
echo "Service: $(sudo systemctl is-active ssh 2>/dev/null || echo 'inactive')"
echo "Config Highlights:"
grep -E "^(PermitRootLogin|PasswordAuthentication|Port|PubkeyAuthentication)" /etc/ssh/sshd_config 2>/dev/null || echo "Config not readable"

# Fail2Ban
echo -e "\n--- Fail2Ban ---"
if command -v fail2ban-client &> /dev/null; then
    sudo fail2ban-client status sshd 2>/dev/null | head -5
else
    echo "Fail2Ban not installed!"
fi

# Open Ports
echo -e "\n--- Open Ports (excluding localhost) ---"
ss -tuln | grep -v "127.0.0.1" | grep -v "::1"

# Failed Logins (last 24h)
echo -e "\n--- Failed Login Attempts (24h) ---"
sudo journalctl -u ssh --since "24 hours ago" 2>/dev/null | grep -c "Failed" || echo "0"

# Last Logins
echo -e "\n--- Recent Logins ---"
last -n 5 2>/dev/null

echo -e "\n========================================"
echo "Check complete: $(date)"
echo "========================================"
