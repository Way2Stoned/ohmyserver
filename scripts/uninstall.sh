#!/usr/bin/env bash
# OhMyServer Uninstaller — removes OhMyServer components interactively
# Usage: uninstall.sh [--yes] [--dry-run] [--keep-opencode] [--remove-data]

set -euo pipefail

YES=0
DRY_RUN=0
KEEP_OPENCODE=0
REMOVE_DATA=0

for arg in "$@"; do
  case "$arg" in
    --yes) YES=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --keep-opencode) KEEP_OPENCODE=1 ;;
    --remove-data) REMOVE_DATA=1 ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

log() { printf '✓ %s\n' "$1"; }
warn() { printf '⚠ %s\n' "$1"; }
err() { printf '✗ %s\n' "$1" >&2; }
dry() { [ "$DRY_RUN" -eq 1 ] && printf '  [DRY-RUN] %s\n' "$1"; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [DRY-RUN] %s\n' "$*"
  else
    eval "$@"
  fi
}

confirm() {
  local prompt="$1"
  if [ "$YES" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    echo "$prompt [auto-yes]"
    return 0
  fi
  read -rp "$prompt (yes/no): " ans
  [ "$ans" = "yes" ]
}

detect_artifacts() {
  OPENCODE_BIN=$(which opencode 2>/dev/null || true)
  OPENCODE_CONFIG="$HOME/.config/opencode"
  OHMYSERVER_SKILLS="$HOME/.config/opencode/skills/ohmyserver"
  SSA_DIR="$HOME/.ssa"
  DASHBOARD_DIR="$HOME/.ssa/dashboard"
  MARIADB_DB="ohmyserver"
  MARIADB_USER="ohmyserver"

  echo "=== Detection Summary ==="
  [ -n "$OPENCODE_BIN" ] && log "OpenCode binary: $OPENCODE_BIN" || warn "OpenCode binary: not found"
  [ -d "$OPENCODE_CONFIG" ] && log "OpenCode config: $OPENCODE_CONFIG" || warn "OpenCode config: not found"
  [ -d "$OHMYSERVER_SKILLS" ] && log "OhMyServer skills: $OHMYSERVER_SKILLS" || warn "OhMyServer skills: not found"
  [ -d "$SSA_DIR" ] && log "Runtime (~/.ssa): $SSA_DIR" || warn "Runtime (~/.ssa): not found"
  [ -d "$DASHBOARD_DIR" ] && log "Dashboard: $DASHBOARD_DIR" || warn "Dashboard: not found"

  if command -v mariadb >/dev/null 2>&1 || command -v mysql >/dev/null 2>&1; then
    local mariadb_cmd="mariadb"
    command -v mariadb >/dev/null 2>&1 || mariadb_cmd="mysql"
    if sudo $mariadb_cmd -e "SHOW DATABASES LIKE '$MARIADB_DB';" 2>/dev/null | grep -q "$MARIADB_DB"; then
      log "MariaDB database '$MARIADB_DB': exists"
      DB_EXISTS=1
    else
      warn "MariaDB database '$MARIADB_DB': not found"
      DB_EXISTS=0
    fi
    if sudo $mariadb_cmd -e "SELECT User FROM mysql.user WHERE User='$MARIADB_USER';" 2>/dev/null | grep -q "$MARIADB_USER"; then
      log "MariaDB user '$MARIADB_USER': exists"
      USER_EXISTS=1
    else
      warn "MariaDB user '$MARIADB_USER': not found"
      USER_EXISTS=0
    fi
  else
    warn "MariaDB/MySQL client: not installed"
    DB_EXISTS=0
    USER_EXISTS=0
  fi

  if ss -tlnp 2>/dev/null | grep -q ':8787' || netstat -tlnp 2>/dev/null | grep -q ':8787'; then
    warn "Dashboard process on :8787: RUNNING"
    DASHBOARD_RUNNING=1
  else
    log "Dashboard process on :8787: not running"
    DASHBOARD_RUNNING=0
  fi

  echo
}

build_removal_plan() {
  REMOVE_A=0; REMOVE_B=0; REMOVE_C=0; REMOVE_D=0; REMOVE_E=0; REMOVE_F=0

  if [ "$KEEP_OPENCODE" -eq 1 ]; then
    warn "[A] OpenCode binary + config: SKIPPED (--keep-opencode)"
  else
    if [ -n "$OPENCODE_BIN" ] || [ -d "$OPENCODE_CONFIG" ]; then
      REMOVE_A=1
    fi
  fi

  if [ -d "$OHMYSERVER_SKILLS" ]; then
    REMOVE_B=1
  fi

  if [ "$REMOVE_DATA" -eq 1 ]; then
    if [ -d "$SSA_DIR" ]; then
      REMOVE_C=1
    fi
  else
    warn "[C] ~/.ssa runtime: KEPT by default (use --remove-data to include)"
  fi

  if [ "$DB_EXISTS" -eq 1 ] || [ "$USER_EXISTS" -eq 1 ]; then
    REMOVE_D=1
  fi

  if [ -d "$DASHBOARD_DIR" ]; then
    REMOVE_E=1
  fi

  REMOVE_F=1
}

print_plan() {
  echo "=== Removal Plan ==="
  [ "$REMOVE_A" -eq 1 ] && echo "  [A] OpenCode binary + ~/.config/opencode (oh-my-opencode)" || echo "  [A] OpenCode binary + config: SKIP"
  [ "$REMOVE_B" -eq 1 ] && echo "  [B] OhMyServer skills (~/.config/opencode/skills/ohmyserver)" || echo "  [B] OhMyServer skills: SKIP"
  [ "$REMOVE_C" -eq 1 ] && echo "  [C] ~/.ssa runtime (logs, operators, credentials, protocols, memory) ⚠ USER DATA" || echo "  [C] ~/.ssa runtime: KEPT (user data)"
  [ "$REMOVE_D" -eq 1 ] && echo "  [D] MariaDB 'ohmyserver' database + user" || echo "  [D] MariaDB: SKIP"
  [ "$REMOVE_E" -eq 1 ] && echo "  [E] Dashboard files (~/.ssa/dashboard + node_modules)" || echo "  [E] Dashboard: SKIP"
  [ "$REMOVE_F" -eq 1 ] && echo "  [F] Other installer artifacts/backups" || echo "  [F] Other artifacts: SKIP"
  echo
}

interactive_menu() {
  if [ "$YES" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    return 0
  fi

  echo "Select items to remove (y/n each):"
  echo

  if [ "$KEEP_OPENCODE" -eq 0 ] && ([ -n "$OPENCODE_BIN" ] || [ -d "$OPENCODE_CONFIG" ]); then
    read -rp "  [A] OpenCode binary + ~/.config/opencode? (y/n): " ans
    [ "$ans" = "y" ] && REMOVE_A=1 || REMOVE_A=0
  fi

  if [ -d "$OHMYSERVER_SKILLS" ]; then
    read -rp "  [B] OhMyServer skills dir? (y/n): " ans
    [ "$ans" = "y" ] && REMOVE_B=1 || REMOVE_B=0
  fi

  if [ -d "$SSA_DIR" ]; then
    if [ "$REMOVE_DATA" -eq 1 ]; then
      read -rp "  [C] ~/.ssa runtime (CONTAINS USER DATA - credentials, memory, logs)? (y/n): " ans
      [ "$ans" = "y" ] && REMOVE_C=1 || REMOVE_C=0
    else
      read -rp "  [C] ~/.ssa runtime (CONTAINS USER DATA - credentials, memory, logs)? (y/n) [default n]: " ans
      [ "$ans" = "y" ] && REMOVE_C=1 || REMOVE_C=0
    fi
  fi

  if [ "$DB_EXISTS" -eq 1 ] || [ "$USER_EXISTS" -eq 1 ]; then
    read -rp "  [D] MariaDB 'ohmyserver' database + user? (y/n): " ans
    [ "$ans" = "y" ] && REMOVE_D=1 || REMOVE_D=0
  fi

  if [ -d "$DASHBOARD_DIR" ]; then
    read -rp "  [E] Dashboard files (~/.ssa/dashboard + node_modules)? (y/n): " ans
    [ "$ans" = "y" ] && REMOVE_E=1 || REMOVE_E=0
  fi

  read -rp "  [F] Other installer artifacts/backups? (y/n): " ans
  [ "$ans" = "y" ] && REMOVE_F=1 || REMOVE_F=0

  echo
}

execute_removal() {
  local removed=()
  local kept=()

  if [ "$REMOVE_A" -eq 1 ]; then
    if confirm "Remove OpenCode binary + ~/.config/opencode?"; then
      if [ -n "$OPENCODE_BIN" ]; then
        run "rm -f '$OPENCODE_BIN'"
        removed+=("OpenCode binary ($OPENCODE_BIN)")
      fi
      if [ -d "$OPENCODE_CONFIG" ]; then
        run "rm -rf '$OPENCODE_CONFIG'"
        removed+=("OpenCode config ($OPENCODE_CONFIG)")
      fi
    else
      kept+=("OpenCode binary + config (user declined)")
    fi
  fi

  if [ "$REMOVE_B" -eq 1 ]; then
    if confirm "Remove OhMyServer skills directory?"; then
      run "rm -rf '$OHMYSERVER_SKILLS'"
      removed+=("OhMyServer skills ($OHMYSERVER_SKILLS)")
    else
      kept+=("OhMyServer skills (user declined)")
    fi
  fi

  if [ "$REMOVE_C" -eq 1 ]; then
    if confirm "Remove ~/.ssa runtime (THIS DELETES YOUR DATA: credentials, memory, logs, protocols)?"; then
      run "rm -rf '$SSA_DIR'"
      removed+=("Runtime ~/.ssa ($SSA_DIR)")
    else
      kept+=("Runtime ~/.ssa (user declined)")
    fi
  fi

  if [ "$REMOVE_D" -eq 1 ]; then
    if confirm "Drop MariaDB 'ohmyserver' database and user?"; then
      if command -v mariadb >/dev/null 2>&1; then
        MARIADB_CMD="mariadb"
      elif command -v mysql >/dev/null 2>&1; then
        MARIADB_CMD="mysql"
      else
        warn "MariaDB/MySQL client not found, skipping database removal"
        kept+=("MariaDB (client not installed)")
      fi

      if [ -n "${MARIADB_CMD:-}" ]; then
        run "sudo $MARIADB_CMD -e \"DROP DATABASE IF EXISTS $MARIADB_DB;\""
        run "sudo $MARIADB_CMD -e \"DROP USER IF EXISTS '$MARIADB_USER'@'localhost';\""
        run "sudo $MARIADB_CMD -e \"DROP USER IF EXISTS '$MARIADB_USER'@'127.0.0.1';\""
        removed+=("MariaDB database '$MARIADB_DB' and user '$MARIADB_USER'")
      fi
    else
      kept+=("MariaDB database/user (user declined)")
    fi
  fi

  if [ "$REMOVE_E" -eq 1 ]; then
    if confirm "Remove dashboard files and node_modules?"; then
      if [ -d "$DASHBOARD_DIR" ]; then
        run "rm -rf '$DASHBOARD_DIR'"
        removed+=("Dashboard ($DASHBOARD_DIR)")
      fi
    else
      kept+=("Dashboard (user declined)")
    fi
  fi

  if [ "$REMOVE_F" -eq 1 ]; then
    if confirm "Remove other installer artifacts/backups?"; then
      local artifacts=(
        "$HOME/.cache/opencode"
        "$HOME/.local/share/opencode"
      )
      for art in "${artifacts[@]}"; do
        if [ -d "$art" ]; then
          run "rm -rf '$art'"
          removed+=("Artifact: $art")
        fi
      done
      if [ -d "$SSA_DIR/backups" ] && [ "$REMOVE_C" -eq 0 ]; then
        run "rm -rf '$SSA_DIR/backups'"
        removed+=("Backups ($SSA_DIR/backups)")
      fi
    else
      kept+=("Other artifacts (user declined)")
    fi
  fi

  echo
  echo "=== Post-Uninstall Summary ==="
  if [ ${#removed[@]} -gt 0 ]; then
    echo "Removed:"
    for item in "${removed[@]}"; do
      echo "  ✓ $item"
    done
  fi
  if [ ${#kept[@]} -gt 0 ]; then
    echo "Kept:"
    for item in "${kept[@]}"; do
      echo "  • $item"
    done
  fi

  if [ "$REMOVE_C" -eq 0 ] && [ -d "$SSA_DIR" ]; then
    echo
    log "Note: ~/.ssa runtime preserved (contains credentials, memory, logs, protocols)"
    log "      Vault secrets and MariaDB-encrypted vault entries are GONE if database was dropped"
  fi

  [ "$DRY_RUN" -eq 1 ] && echo "  (Dry-run complete — no changes made)"
}

main() {
  echo "OhMyServer Uninstaller"
  echo "======================"
  echo

  detect_artifacts
  build_removal_plan
  print_plan

  if [ "$YES" -eq 0 ]; then
    interactive_menu
    print_plan
  fi

  if ! confirm "Proceed with the above removal plan?"; then
    echo "Aborted."
    exit 0
  fi

  execute_removal
}

main "$@"