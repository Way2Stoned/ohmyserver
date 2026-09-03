#!/usr/bin/env bash
# ohmyserver-init.sh — Interactive server identity onboarding
# Usage: ohmyserver-init.sh [--yes]  # --yes skips prompts, uses defaults/existing
# Idempotent and re-runnable. Writes ~/.ssa/server.json

set -euo pipefail

SSA_DIR="${HOME}/.ssa"
CONFIG_FILE="${SSA_DIR}/server.json"
TEMP_FILE="${CONFIG_FILE}.tmp"

YES_MODE=false
for arg in "$@"; do
  case "$arg" in
    --yes|-y) YES_MODE=true ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# Cleanup on exit/interrupt
cleanup() {
  [[ -f "${TEMP_FILE}" ]] && rm -f "${TEMP_FILE}"
}
trap cleanup EXIT INT TERM

# Default values (matching server-config.sh)
DEFAULT_SERVER_NAME="$(hostname -s)"
DEFAULT_USER="${USER}"
DEFAULT_DOMAIN=""
DEFAULT_PURPOSE="personal"
DEFAULT_ADMIN="${USER}@$(hostname -f 2>/dev/null || hostname -s)"
DEFAULT_INSTALL_DIR="/root/ohmyserver-repo"
DEFAULT_SSA_DIR="${SSA_DIR}"
DEFAULT_LANGUAGE="en"
DEFAULT_WITH_DB="false"

# Load existing config if present
declare -A CURRENT=(
  [server_name]="${DEFAULT_SERVER_NAME}"
  [user]="${DEFAULT_USER}"
  [domain]="${DEFAULT_DOMAIN}"
  [purpose]="${DEFAULT_PURPOSE}"
  [admin]="${DEFAULT_ADMIN}"
  [install_dir]="${DEFAULT_INSTALL_DIR}"
  [ssa_dir]="${DEFAULT_SSA_DIR}"
  [language]="${DEFAULT_LANGUAGE}"
  [with_db]="${DEFAULT_WITH_DB}"
  [created_iso]=""
  [updated_iso]=""
)

if [[ -f "${CONFIG_FILE}" ]]; then
  json_content=$(cat "${CONFIG_FILE}")
  while IFS='=' read -r key value; do
    [[ -n "$key" ]] && CURRENT["$key"]="$value"
  done < <(echo "$json_content" | jq -r 'to_entries[] | "\(.key)=\(.value)"' 2>/dev/null || true)
fi

# Prompt helper
prompt_with_default() {
  local prompt="$1"
  local var_name="$2"
  local default="${CURRENT[$var_name]}"
  local value=""

  if [[ "$YES_MODE" == true ]]; then
    value="$default"
  else
    read -r -p "${prompt} [${default}]: " value
    value="${value:-$default}"
  fi

  CURRENT["$var_name"]="$value"
}

# Ensure .ssa directories exist
mkdir -p "${SSA_DIR}/backups" "${SSA_DIR}/credentials" "${SSA_DIR}/logs" \
         "${SSA_DIR}/operators" "${SSA_DIR}/protocols" "${SSA_DIR}/reports"

echo "=== OhMyServer Initialization ==="

# Server name
prompt_with_default "What is this server for / its name?" "server_name"

# Main user/admin
prompt_with_default "Who is the main user/admin?" "user"

# Domain
prompt_with_default "What domain does it use (if any)?" "domain"

# Purpose
prompt_with_default "What is the server's purpose? (web, mail, dev, personal, company, ...)" "purpose"

# Admin email
prompt_with_default "Admin contact email" "admin"

# Language
prompt_with_default "Preferred language (en, de, es, fr)" "language"

# Database
if [[ "$YES_MODE" == true ]]; then
  CURRENT[with_db]="${CURRENT[with_db]}"
else
  read -r -p "Should it set up MariaDB? (y/N) [${CURRENT[with_db]}]: " db_answer
  case "${db_answer,,}" in
    y|yes) CURRENT[with_db]="true" ;;
    n|no|"") CURRENT[with_db]="${CURRENT[with_db]}" ;;
    *) CURRENT[with_db]="${CURRENT[with_db]}" ;;
  esac
fi

# Timestamps
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
if [[ -z "${CURRENT[created_iso]}" ]]; then
  CURRENT[created_iso]="${NOW_ISO}"
fi
CURRENT[updated_iso]="${NOW_ISO}"

# Fixed paths
CURRENT[install_dir]="${DEFAULT_INSTALL_DIR}"
CURRENT[ssa_dir]="${DEFAULT_SSA_DIR}"

# Write JSON to temp file then atomically move
{
  echo "{"
  first=true
  for key in server_name user domain purpose admin install_dir ssa_dir language with_db created_iso updated_iso; do
    if [[ "$first" == true ]]; then
      first=false
    else
      printf ",\n"
    fi
    val="${CURRENT[$key]}"
    printf '  "%s": %s' "$key" "$(printf '%s' "$val" | jq -Rs .)"
  done
  echo ""
  echo "}"
} > "${TEMP_FILE}"

mv "${TEMP_FILE}" "${CONFIG_FILE}"

# Source the config loader to export env vars in this session
# shellcheck source=/dev/null
source /root/ohmyserver-repo/scripts/server-config.sh

# Print summary
echo ""
echo "Server: ${CURRENT[server_name]} | User: ${CURRENT[user]} | Domain: ${CURRENT[domain]} | Purpose: ${CURRENT[purpose]} | Language: ${CURRENT[language]}"
echo "Config written to: ${CONFIG_FILE}"
echo "Environment variables exported in this session (OMS_*)."
echo "Note: To persist env vars, add 'source /root/ohmyserver-repo/scripts/server-config.sh' to your shell rc file."