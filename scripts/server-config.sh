#!/usr/bin/env bash
# server-config.sh — OhMyServer config loader & env bridge
# Usage: source server-config.sh           # load config + export env vars
#        server-config.sh                  # print current config as JSON
#        server-config.sh --export         # print export statements for eval
#        cfg <key>                         # get a config value (after sourcing)

set -euo pipefail

SSA_DIR="${HOME}/.ssa"
CONFIG_FILE="${SSA_DIR}/server.json"

# Default configuration
declare -A DEFAULTS=(
  [server_name]="$(hostname -s)"
  [user]="${USER}"
  [domain]=""
  [purpose]="personal"
  [admin]="${USER}@$(hostname -f 2>/dev/null || hostname -s)"
  [install_dir]="/root/ohmyserver-repo"
  [ssa_dir]="${SSA_DIR}"
  [language]="en"
  [with_db]="false"
  [created_iso]=""
  [updated_iso]=""
)

# Load config from file, falling back to defaults
load_config() {
  declare -gA CONFIG=()
  for key in "${!DEFAULTS[@]}"; do
    CONFIG["$key"]="${DEFAULTS[$key]}"
  done

  if [[ -f "${CONFIG_FILE}" ]]; then
    local json_content
    json_content=$(cat "${CONFIG_FILE}")
    while IFS='=' read -r key value; do
      [[ -n "$key" ]] && CONFIG["$key"]="$value"
    done < <(echo "$json_content" | jq -r 'to_entries[] | "\(.key)=\(.value)"' 2>/dev/null || true)
  fi

  # Ensure ssa_dir matches reality
  CONFIG[ssa_dir]="${SSA_DIR}"
}

# cfg helper - get a config value
cfg() {
  local key="$1"
  echo "${CONFIG[$key]:-}"
}

# Export all config as environment variables
export_env() {
  export OMS_SERVER_NAME="${CONFIG[server_name]}"
  export OMS_USER="${CONFIG[user]}"
  export OMS_DOMAIN="${CONFIG[domain]}"
  export OMS_ADMIN="${CONFIG[admin]}"
  export OMS_PURPOSE="${CONFIG[purpose]}"
  export OMS_INSTALL_DIR="${CONFIG[install_dir]}"
  export OMS_SSA_DIR="${CONFIG[ssa_dir]}"
  export OMS_LANGUAGE="${CONFIG[language]}"
  export OMS_WITH_DB="${CONFIG[with_db]}"
}

# Print config as JSON
print_json() {
  local json="{"
  local first=true
  for key in server_name user domain purpose admin install_dir ssa_dir language with_db created_iso updated_iso; do
    if [[ "$first" == true ]]; then
      first=false
    else
      json+=", "
    fi
    local val="${CONFIG[$key]:-}"
    json+="\"$key\": $(printf '%s' "$val" | jq -Rs .)"
  done
  json+="}"
  echo "$json"
}

# Print export statements for eval
print_exports() {
  for key in server_name user domain purpose admin install_dir ssa_dir language with_db; do
    local env_var="OMS_${key^^}"
    local val="${CONFIG[$key]:-}"
    printf 'export %s=%s\n' "$env_var" "$(printf '%s' "$val" | jq -Rs .)"
  done
}

# Main - only run when executed directly, not when sourced
load_config

# Detect if sourced: $0 will be shell name (bash, zsh, etc.) not script path
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    --export)
      print_exports
      ;;
    --json|"")
      print_json
      ;;
    *)
      echo "Usage: $0 [--export|--json]" >&2
      exit 1
      ;;
  esac
else
  # When sourced, export env vars automatically
  export_env
fi