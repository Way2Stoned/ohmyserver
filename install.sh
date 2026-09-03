#!/usr/bin/env bash
# ============================================================
# OhMyServer Install-Script (talbergh.art)
# One-Liner: curl -fsSL https://raw.githubusercontent.com/<OWNER>/ohmyserver/main/install.sh | bash
# ============================================================
set -euo pipefail

VERSION="1.0.0"
SKILLS_SRC="${SKILLS_SRC:-}"          # optional: überschreibt Install-Quelle (lokal oder URL)
INSTALL_DIR="${INSTALL_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/ohmyserver}"
SSA_DIR="${SSA_DIR:-$HOME/.ssa}"
REPO_OWNER="${REPO_OWNER:-}"          # GitHub-Benutzername (z.B. 'talbergh')
REPO_NAME="${REPO_NAME:-ohmyserver}"
REPO_BRANCH="${REPO_BRANCH:-main}"
REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}}"
WITH_DB="${WITH_DB:-0}"               # 1 = MariaDB-ohmyserver-DB optional einrichten
LOG="$HOME/.ssa/logs/install.log"

log()  { printf '\033[1;32m✓\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m⚠\033[0m %s\n' "$1"; }
die()  { printf '\033[1;31m✗\033[0m %s\n' "$1" >&2; exit 1; }

echo "=== OhMyServer Installer v${VERSION} ==="

# --- Voraussetzungen ---
for cmd in git curl bash; do
  command -v "$cmd" >/dev/null 2>&1 || die "Fehlendes Tool: $cmd (bitte installieren)"
done
log "Abhängigkeiten (git/curl/bash) vorhanden"

# --- OpenCode + OhMyOpenCode prüfen/smart installieren ---
opencode_installed=0
ohmopen_installed=0
command -v opencode >/dev/null 2>&1 && opencode_installed=1
if [ "$opencode_installed" = "1" ]; then
  if opencode --version >/dev/null 2>&1; then log "OpenCode gefunden: $(opencode --version 2>&1 | head -1)"; else warn "OpenCode gefunden aber nicht funktionsfähig"; opencode_installed=0; fi
else
  warn "OpenCode nicht gefunden - installiere..."
  if curl -fsSL https://opencode.ai/install | bash >/dev/null 2>&1; then
    log "OpenCode via offizielles Script installiert"
  elif command -v npm >/dev/null 2>&1; then
    npm install -g opencode-ai >/dev/null 2>&1 && log "OpenCode via npm installiert" || warn "npm-Installation fehlgeschlagen"
  elif command -v brew >/dev/null 2>&1; then
    brew install anomalyco/tap/opencode >/dev/null 2>&1 && log "OpenCode via brew installiert" || warn "brew-Installation fehlgeschlagen"
  else
    warn "OpenCode-Installation manuell nötig: https://opencode.ai/docs"
  fi
  command -v opencode >/dev/null 2>&1 && opencode_installed=1
fi
if [ -d "$HOME/.config/opencode" ] || [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/opencode" ]; then
  ohmopen_installed=1; log "OhMyOpenCode/OpenCode-Konfig gefunden"
else
  warn "OhMyOpenCode-Konfig nicht gefunden - wird durch Skill-Installation eingerichtet"
fi

# --- Model-Auswahl (free Models vs. bestehende Accounts/API-Tokens) ---
if [ "$opencode_installed" = "1" ] && [ -t 0 ]; then
  printf '\nMöchtest du OpenCode-Modelle nutzen?\n'
  printf '  [1] Kostenlose Modelle (ohne Account/API-Key)\n'
  printf '  [2] Bestehende Accounts/API-Tokens verwenden\n'
  printf 'Auswahl [1/2]: '; read -r MODEL_CHOICE
  MODEL_CHOICE="${MODEL_CHOICE:-1}"
  if [ "$MODEL_CHOICE" = "2" ]; then
    printf 'Bitte stelle deine API-Tokens/Accounts bereit (z.B. als Umgebungsvariablen ANTHROPIC_API_KEY, OPENAI_API_KEY, GEMINI_API_KEY).\n'
    printf 'Hinweis: OhMyServer speichert Secrets sicher über seinen Vault-Agent (nicht im Klartext).\n'
  else
    log "Kostenlose Modelle aktiviert - kein API-Key nötig"
  fi
else
  log "Nicht-interaktive Installation - Modelle werden später via OpenCode konfiguriert"
fi

# --- Zielverzeichnis ---
mkdir -p "$INSTALL_DIR"
mkdir -p "$SSA_DIR"/{backups,credentials,design/project-guidelines,design/renders,logs,operators,protocols,reports}
log "Verzeichnisse angelegt: $INSTALL_DIR, $SSA_DIR"

# --- Quellen laden ---
if [ -n "$SKILLS_SRC" ] && [ -d "$SKILLS_SRC" ]; then
  # Lokale Kopie (Entwicklung) - rekursiv inkl. Scripts
  cp -r "$SKILLS_SRC"/. "$INSTALL_DIR"/
  log "Skills aus lokaler Quelle kopiert: $SKILLS_SRC"
elif [ -n "$SKILLS_SRC" ] && [[ "$SKILLS_SRC" == http* ]]; then
  # Direkte Tarball-URL
  curl -fsSL "$SKILLS_SRC" | tar xz -C "$INSTALL_DIR" 2>/dev/null \
    && log "Skills aus Tarball: $SKILLS_SRC" || die "Tarball-Extraktion fehlgeschlagen"
elif command -v git >/dev/null 2>&1 && [ -n "$REPO_OWNER" ]; then
  # Sauberste Variante: git clone (löst Struktur auf, ermöglicht Updates)
  TMP="$(mktemp -d)"
  git clone --depth 1 -b "$REPO_BRANCH" "https://github.com/${REPO_OWNER}/${REPO_NAME}.git" "$TMP"
  cp -r "$TMP/skills"/. "$INSTALL_DIR"/
  rm -rf "$TMP"
  log "Skills via git clone geladen (updatable)"
else
  # Fallback: einzelne Dateien per curl (ohne git/owner nötig)
  for f in README.md _STANDARD.md commands.md; do
    curl -fsSL "$REPO_RAW/$f" -o "$INSTALL_DIR/$f" 2>/dev/null && log "Datei: $f" || warn "Konnte $f nicht laden"
  done
  # Skill-Ordner über GitHub-API-Liste rekursiv
  for skill in $(curl -fsSL "https://api.github.com/repos/${REPO_OWNER:-x}/${REPO_NAME}/contents/skills" 2>/dev/null | grep '"name"' | sed 's/.*"name": *"\([^"]*\)".*/\1/' | grep -v '\.md'); do
    mkdir -p "$INSTALL_DIR/$skill"
    curl -fsSL "$REPO_RAW/skills/$skill/SKILL.md" -o "$INSTALL_DIR/$skill/SKILL.md" 2>/dev/null \
      && log "Skill: $skill" || warn "Skill fehlt/übersprungen: $skill"
  done
  log "Skills via curl geladen"
fi

# --- MariaDB-ohmyserver-DB optional einrichten (dedizierter Account) ---
if [ "$WITH_DB" = "1" ]; then
  if command -v mariadb >/dev/null 2>&1; then
    MYSQL_CLI="sudo mariadb"
  elif command -v mysql >/dev/null 2>&1; then
    MYSQL_CLI="sudo mysql"
  else
    MYSQL_CLI=""
    warn "WITH_DB=1 aber kein mariadb/mysql gefunden - DB-Setup übersprungen"
  fi
  if [ -n "$MYSQL_CLI" ]; then
    DB_USER="ohmyserver"; DB_NAME="ohmyserver"
    PW="${MARIADB_PW:-$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)}"
    SQL=$(cat <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${PW}';
CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${PW}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL
)
    echo "$SQL" | $MYSQL_CLI 2>/dev/null
    mkdir -p "$SSA_DIR/credentials"
    umask 077
    printf 'MariaDB user: %s\nhost: localhost/127.0.0.1\ndatabase: %s\npassword: %s\n' "$DB_USER" "$DB_NAME" "$PW" > "$SSA_DIR/credentials/mariadb-ohmyserver.txt"
    chmod 600 "$SSA_DIR/credentials/mariadb-ohmyserver.txt"
    log "MariaDB-DB '${DB_NAME}' + User '${DB_USER}' eingerichtet (+ Credential in .ssa/credentials)"
  fi
fi

# --- OpenCode-Registrierung prüfen ---
if [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/opencode" ]; then
  log "OpenCode-Konfig gefunden (Skills werden via ~/.config/opencode/skills erkannt)"
else
  warn "Kein OpenCode-Konfigverzeichnis gefunden - prüfe Installationspfad"
fi

# --- Log ---
mkdir -p "$(dirname "$LOG")"
printf '[%s] install v%s nach %s (quelle=%s)\n' "$(date -u +%F_%T)" "$VERSION" "$INSTALL_DIR" "${SKILLS_SRC:-github}" >> "$LOG"

echo
echo "✅ FERTIG - OhMyServer installiert nach:"
echo "   $INSTALL_DIR"
echo "   Laufzeit-Daten: $SSA_DIR"
echo
echo "Hinweis: Starte OpenCode neu, damit die Skills geladen werden."
echo "Falls du git-basiert aktualisieren willst: git clone <REPO> && ./install.sh"
