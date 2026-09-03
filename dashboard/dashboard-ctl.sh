#!/usr/bin/env bash
# OhMyServer Dashboard - Lifecycle-Control (session-gebunden)
# Start:   dashboard-ctl.sh start
# Stop:    dashboard-ctl.sh stop
# Status:  dashboard-ctl.sh status
# Läuft NUR solange OpenCode/OhMyServer aktiv ist (kein Daemon, kein systemd).
set -euo pipefail

DASH_DIR="${DASH_DIR:-/root/ohmyserver-repo/dashboard}"
DASH_PORT="${DASH_PORT:-8787}"
DASH_HOST="${DASH_HOST:-127.0.0.1}"
PID_FILE="${PID_FILE:-/root/.ssa/dashboard/dashboard.pid}"
LOG_FILE="${LOG_FILE:-/root/.ssa/logs/dashboard.log}"

log() { printf '[%s] %s\n' "$(date -u +%F_%T)" "$*" >> "$LOG_FILE"; }

is_running() {
  [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

case "${1:-status}" in
  start)
    mkdir -p "$(dirname "$PID_FILE")" "$(dirname "$LOG_FILE")"
    if is_running; then
      echo "Dashboard läuft bereits (pid $(cat "$PID_FILE"))"
      exit 0
    fi
    cd "$DASH_DIR"
    DASH_PORT="$DASH_PORT" DASH_HOST="$DASH_HOST" nohup node server/index.js >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    sleep 1
    if is_running; then
      echo "Dashboard gestartet: http://$DASH_HOST:$DASH_PORT (pid $(cat "$PID_FILE"))"
      log "start pid=$(cat "$PID_FILE") port=$DASH_PORT"
    else
      echo "Dashboard-Start fehlgeschlagen - siehe $LOG_FILE"
      exit 1
    fi
    ;;
  stop)
    if is_running; then
      kill -TERM "$(cat "$PID_FILE")" 2>/dev/null || true
      rm -f "$PID_FILE"
      echo "Dashboard gestoppt"
      log "stop"
    else
      rm -f "$PID_FILE"
      echo "Dashboard läuft nicht"
    fi
    ;;
  status)
    if is_running; then
      echo "Dashboard läuft (pid $(cat "$PID_FILE")) auf http://$DASH_HOST:$DASH_PORT"
    else
      echo "Dashboard läuft nicht"
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|status}" >&2
    exit 1
    ;;
esac
