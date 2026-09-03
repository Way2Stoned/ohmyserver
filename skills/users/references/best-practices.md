# User & Permission Best Practices (Linux Server)

Zusammenfassung der Community-Standard-Härtung für User/Rechte-Verwaltung.

## 1. Least Privilege (Minimal-Rechte)

**Regel**: Jeder User bekommt NUR die Rechte die er wirklich braucht.

- **Nur der Owner** hat vollen sudo
- Andere User bekommen **spezifische** Rechte, nicht vollen Admin
- Service-Accounts haben **keine** interaktive Login-Shell

```bash
# Statt vollem sudo:
sudo usermod -aG sudo user   # ❌ zu viel

# Spezifische Rechte (besser):
echo 'user ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx' | sudo tee /etc/sudoers.d/user
```

## 2. SSH-Sicherheit (KRITISCH)

```bash
# /etc/ssh/sshd_config - Gehärtete Empfehlung:
PermitRootLogin no               # Kein Root-Login
PasswordAuthentication no        # Nur SSH-Keys
PubkeyAuthentication yes
AllowUsers talbergh              # Nur erlaubte User
MaxAuthTries 3                   # Max 3 Versuche
```

> **IMMER** `sshd -t` testen BEVOR Reload, sonst lockout!
> ```bash
> sudo sshd -t && sudo systemctl reload sshd
> ```

## 3. Passwort- & Account-Sicherheit

```bash
# Account-Sperre bei Fehlversuchen (fail2ban oder pam_faillock)
sudo apt install fail2ban

# Passwort-Ablauf setzen (für normale User)
sudo chage -M 90 benutzer   # alle 90 Tage ändern

# Expired-Account-Untersuchung
sudo chage -l benutzer
```

## 4. Benutzer-Anlage (sicher)

```bash
# Sicher: mit beschreibung, ssh-key statt passwort
sudo useradd -m -s /bin/bash -c "Web-App Betreiber" web
sudo mkdir -p /home/web/.ssh
sudo tee /home/web/.ssh/authorized_keys >/dev/null <<'EOF'
ssh-rsa AAAA... user@host
EOF
sudo chown -R web:web /home/web/.ssh
sudo chmod 700 /home/web/.ssh
sudo chmod 600 /home/web/.ssh/authorized_keys
```

## 5. Service-Accounts (Datei-Zugriffe)

- **Keine Shell**: `/usr/sbin/nologin`
- **Nur benötigte Dateirechte**

```bash
sudo useradd -r -s /usr/sbin/nologin app-service
```

## 6. Detektions-Checks (regelmäßig via UPA)

```bash
# 1. User mit UID 0 (sollte NUR root sein)
awk -F: '$3 == 0 {print $1}' /etc/passwd

# 2. Leere Passwörter (KRITISCH!)
sudo awk -F: '($2 == "") {print $1}' /etc/shadow

# 3. User mit Login-Shell
grep -E "/(bash|sh|zsh)$" /etc/passwd

# 4. Sudo-Mitglieder
getent group sudo

# 5. Ungenutzte Accounts (30+ Tage kein Login)
last -n 30 | awk '{print $1}' | sort -u
```

## 7. Sudoer-Härtung

```bash
# defaults - Passwort-Auth für sudo (sicher)
# Defaults EXISTIERT bereits, nicht schwächen mit NOPASSWD (außer spezifisch)

# visudo nutzen (NIE direkt nano)
sudo visudo

# Nur EIN Admin in sudo Group
```

## 8. Datei-Permissions (Dienste)

| Verzeichnis | Besitzer | Perms | Zweck |
|-------------|----------|-------|-------|
| /home/*/ | user | 700/750 | Persönliche Daten |
| /root/ | root | 700 | Root-Daten |
| /etc/shadow | root | 640 | Passwort-Hashes |
| /etc/ssh/sshd_config | root | 600 | SSH-Konfig |
| ~/.ssh/ | user | 700 | SSH |
| ~/.ssh/authorized_keys | user | 600 | SSH-Keys |

## 9. Außer Betrieb genommene Accounts

- **Deaktivieren** statt löschen (auditbar):
```bash
sudo usermod -L user   # lock (deaktiviert)
sudo usermod -s /usr/sbin/nologin user
```
- Nach Standzeit: dokumentieren in users.md + ggf. löschen (fragen!)

## 10. Was NIE tun

- ❌ Passwort in Klartext ablegen / in Cron
- ❌ `PermitRootLogin yes` + `PasswordAuthentication yes`
- ❌ Vollen sudo an Nicht-Admin geben
- ❌ Service-Account mit `/bin/bash`
- ❌ authorized_keys mit Gruppe/Außenwelt lesbar (600!)

## WICHTIG (Zusammenfassung)
1. **Least Privilege**: nur nötige Rechte
2. **SSH-Keys** statt Passwort-Login
3. **Root-Login aus**
4. **users.md pflegen** bei jeder Änderung
5. **Backup** passwd/shadow/sudoers vor Änderung
6. **visudo** nutzen, nie direkt editieren
