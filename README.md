# OhMyServer (talbergh.art)

OhMyServer ist ein modulares **OpenCode-Skill-Set** für die Verwaltung des talbergh.art-Servers. Es besteht aus spezialisierten Agenten (Security, Config, Backup, DB, Design, Memory …), einem zentralen Dispatcher, Operator-/Session-Verwaltung, optionalem Web-Dashboard und einem sicheren Secrets-Vault.

> **Hinweis:** Dieses Repo ist privat. Es enthält die verteilbaren Skill-/Script- und Konfigurationsdateien. **Keine Secrets oder Credentials** einchecken (Passwörter/API-Keys gehören in `~/.ssa/credentials/` bzw. den Vault).

## Schnellinstallation (One-Liner)

```bash
curl -fsSL https://raw.githubusercontent.com/<OWNER>/ohmyserver/main/install.sh | bash
```

Der Installer:
- prüft, ob **OpenCode** + **OpenCode-Konfig** vorhanden sind (installiert OpenCode bei Bedarf smart: offizielles Script → npm → brew)
- fragt interaktiv, ob **kostenlose Modelle** oder **bestehende Accounts/API-Tokens** genutzt werden sollen
- kopiert die Skills nach `~/.config/opencode/skills/ohmyserver/`
- legt die Laufzeit-Struktur `~/.ssa/` an (logs, operators, credentials, protocols, backups, …)
- richtet optional (`WITH_DB=1`) die MariaDB-Datenbank + dedizierten Account `ohmyserver` ein

### Optionen

| Variable | Wirkung |
|----------|---------|
| `WITH_DB=1` | MariaDB-DB `ohmyserver` + User `ohmyserver` einrichten |
| `SKILLS_SRC=/pfad` | Aus lokaler Quelle statt GitHub installieren (Entwicklung) |
| `INSTALL_DIR=…` | Zielverzeichnis überschreiben |
| `SSA_DIR=…` | Laufzeit-Verzeichnis überschreiben |
| `REPO_OWNER=…` | GitHub-Repository-Owner (für git-clone-basiertes Update) |

## Struktur

```
ohmyserver/
├── install.sh          # One-Liner-Installer
├── README.md
├── skills/             # OpenCode-Skill-Dateien
│   ├── _STANDARD.md    # gemeinsame Standards
│   ├── commands.md     # #-Command-Referenz
│   └── <each-skill>/SKILL.md
├── scripts/            # ausführbare Server-/Status-/Audit-Skripte
└── docs/               # erweiterte Dokumentation
```

## Abhängigkeiten

- **OpenCode** (Terminal-AI-Agent) — wird vom Installer geprüft/installiert
- **git, curl, bash** — für Installation
- **MariaDB/MySQL** — optional (`WITH_DB=1`) für Dashboard-Auth, Memory-System, Vault

## Update

```bash
git clone https://github.com/<OWNER>/ohmyserver.git && cd ohmyserver && ./install.sh
```

## Sicherheit

- Secrets/Passwörter landen **nie** im Repo, sondern in `~/.ssa/credentials/` (chmod 600) bzw. im Vault-Agent
- Das Dashboard ist **nur erreichbar, solange OpenCode/OhMyServer aktiv** ist (Start/Stop an Session-Lebenszyklus gekoppelt)
- Operator-Login am Dashboard: Name + Passwort (gespeichert in MariaDB, gehasht)
