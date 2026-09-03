# User & Permission Best Practices (Linux Server)

Summary of Community Standard Hardening for User/Rights Management.

## 1. Least Privilege (Minimal Rights)

**Rule**: Every User Gets ONLY the Rights They Actually Need.

- **Only the Owner** Has Full Sudo
- Other Users Get **Specific** Rights, Not Full Admin
- Service Accounts Have **No** Interactive Login Shell

```bash
# Instead of Full Sudo:
sudo usermod -aG sudo user   # ❌ Too Much

# Specific Rights (Better):
echo 'user ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx' | sudo tee /etc/sudoers.d/user
```

## 2. SSH Security (CRITICAL)

```bash
# /etc/ssh/sshd_config - Hardened Recommendation:
PermitRootLogin no               # No Root Login
PasswordAuthentication no        # Only SSH Keys
PubkeyAuthentication yes
AllowUsers <user>                # Only Allowed Users
MaxAuthTries 3                   # Max 3 Attempts
```

> **ALWAYS** `sshd -t` Test BEFORE Reload, Otherwise Lockout!
> ```bash
> sudo sshd -t && sudo systemctl reload sshd
> ```

## 3. Password & Account Security

```bash
# Account Lock on Failed Attempts (fail2ban or pam_faillock)
sudo apt install fail2ban

# Set Password Expiry (for Normal Users)
sudo chage -M 90 user   # Change Every 90 Days

# Expired Account Investigation
sudo chage -l user
```

## 4. User Creation (Secure)

```bash
# Secure: With Description, SSH Key Instead of Password
sudo useradd -m -s /bin/bash -c "Web App Operator" web
sudo mkdir -p /home/web/.ssh
sudo tee /home/web/.ssh/authorized_keys >/dev/null <<'EOF'
ssh-rsa AAAA... user@host
EOF
sudo chown -R web:web /home/web/.ssh
sudo chmod 700 /home/web/.ssh
sudo chmod 600 /home/web/.ssh/authorized_keys
```

## 5. Service Accounts (File Access)

- **No Shell**: `/usr/sbin/nologin`
- **Only Required File Rights**

```bash
sudo useradd -r -s /usr/sbin/nologin app-service
```

## 6. Detection Checks (Regular via UPA)

```bash
# 1. Users with UID 0 (Should ONLY Be Root)
awk -F: '$3 == 0 {print $1}' /etc/passwd

# 2. Empty Passwords (CRITICAL!)
sudo awk -F: '($2 == "") {print $1}' /etc/shadow

# 3. Users with Login Shell
grep -E "/(bash|sh|zsh)$" /etc/passwd

# 4. Sudo Members
getent group sudo

# 5. Unused Accounts (30+ Days No Login)
last -n 30 | awk '{print $1}' | sort -u
```

## 7. Sudo Hardening

```bash
# defaults - Password Auth for Sudo (Secure)
# Defaults ALREADY EXISTS, Don't Weaken with NOPASSWD (Except Specific)

# Use visudo (NEVER Direct nano)
sudo visudo

# Only ONE Admin in Sudo Group
```

## 8. File Permissions (Services)

| Directory | Owner | Perms | Purpose |
|-----------|-------|-------|---------|
| /home/*/ | user | 700/750 | Personal Data |
| /root/ | root | 700 | Root Data |
| /etc/shadow | root | 640 | Password Hashes |
| /etc/ssh/sshd_config | root | 600 | SSH Config |
| ~/.ssh/ | user | 700 | SSH |
| ~/.ssh/authorized_keys | user | 600 | SSH Keys |

## 9. Decommissioned Accounts

- **Disable** Instead of Delete (Auditable):
```bash
sudo usermod -L user   # Lock (Disable)
sudo usermod -s /usr/sbin/nologin user
```
- After Stand Time: Document in users.md + Maybe Delete (Ask!)

## 10. What NEVER To Do

- ❌ Store Password in Plaintext / in Cron
- ❌ `PermitRootLogin yes` + `PasswordAuthentication yes`
- ❌ Full Sudo to Non-Admin
- ❌ Service Account with `/bin/bash`
- ❌ authorized_keys Readable by Group/Outside (600!)

## 11. IMPORTANT (Summary)
1. **Least Privilege**: Only Necessary Rights
2. **SSH Keys** Instead of Password Login
3. **Root Login Off**
4. **Maintain users.md** On Every Change
5. **Backup** passwd/shadow/sudoers Before Change
6. **Use visudo**, Never Direct Edit
