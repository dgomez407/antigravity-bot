#!/usr/bin/env bash
# Start Antigravity with a usable Chrome DevTools Protocol (CDP) target, then
# run LazyGravity as the Discord control plane.
#
# Usage:
#   ./run.sh <command> [option]
#
# Optional .env settings:
#   DEBUGGING_PORT=9222
#   ANTIGRAVITY_EXE="/c/path/to/Antigravity IDE.exe"

set -euo pipefail

script_parent="${BASH_SOURCE[0]%/*}"
if [[ "$script_parent" == "${BASH_SOURCE[0]}" ]]; then
  script_parent='.'
fi
readonly SCRIPT_DIR="$(cd "$script_parent" && pwd)"
unset script_parent
cd "$SCRIPT_DIR"

readonly DEBUGGING_PORT="${DEBUGGING_PORT:-9222}"
if [[ -z "${ANTIGRAVITY_EXE:-}" ]]; then
  if [[ -n "${LOCALAPPDATA:-}" ]]; then
    localappdata_unix="$(echo "$LOCALAPPDATA" | tr '\\' '/')"
    if [[ "$localappdata_unix" =~ ^[a-zA-Z]: ]]; then
      drive="${localappdata_unix:0:1}"
      drive_lower="$(echo "$drive" | tr '[:upper:]' '[:lower:]')"
      localappdata_unix="/${drive_lower}${localappdata_unix:2}"
    fi
    readonly ANTIGRAVITY_EXE="${localappdata_unix}/Programs/Antigravity IDE/Antigravity IDE.exe"
  else
    readonly ANTIGRAVITY_EXE="/c/Users/${USER:-$USERNAME}/AppData/Local/Programs/Antigravity IDE/Antigravity IDE.exe"
  fi
else
  readonly ANTIGRAVITY_EXE="$ANTIGRAVITY_EXE"
fi
readonly CDP_VERSION_URL="http://127.0.0.1:${DEBUGGING_PORT}/json/version"
readonly CDP_TARGETS_URL="http://127.0.0.1:${DEBUGGING_PORT}/json/list"
readonly CDP_STARTUP_TIMEOUT_SECONDS=60
readonly SCRIPT_VERSION='2.0.0'
readonly LAZY_GRAVITY_PID_FILE="$SCRIPT_DIR/.lazy-gravity.pid"
readonly LAZY_GRAVITY_LOG_FILE="$SCRIPT_DIR/lazy-gravity.log"
readonly LAZY_GRAVITY_LOCK_FILE="$HOME/AppData/Local/Temp/lazygravity-user/.bot.lock"
readonly LAZY_GRAVITY_DIR="$SCRIPT_DIR/vendor/LazyGravity"
readonly LAZY_GRAVITY_CLI="$LAZY_GRAVITY_DIR/dist/bin/cli.js"

ACTION='help'

# Color must be disabled before the readonly color constants are initialized.
for argument in "$@"; do
  if [[ "$argument" == '--no-color' ]]; then
    export NO_COLOR=1
    break
  fi
done

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  readonly COLOR_BLUE=$'\033[34m'
  readonly COLOR_GREEN=$'\033[32m'
  readonly COLOR_RED=$'\033[31m'
  readonly COLOR_YELLOW=$'\033[33m'
  readonly COLOR_RESET=$'\033[0m'
else
  readonly COLOR_BLUE=''
  readonly COLOR_GREEN=''
  readonly COLOR_RED=''
  readonly COLOR_YELLOW=''
  readonly COLOR_RESET=''
fi

log_info() {
  printf '%s[INFO]%s %s\n' "$COLOR_BLUE" "$COLOR_RESET" "$*"
}

log_success() {
  printf '%s[OK]%s %s\n' "$COLOR_GREEN" "$COLOR_RESET" "$*"
}

log_warning() {
  printf '%s[WARN]%s %s\n' "$COLOR_YELLOW" "$COLOR_RESET" "$*"
}

log_error() {
  printf '%s[ERROR]%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$*" >&2
}

show_help() {
  printf '%s\n' \
    'Antigravity Discord bot launcher' \
    '' \
    'Usage:' \
    '  ./run.sh <command> [option]' \
    '' \
    'Commands:' \
    '  start             Start Antigravity IDE and LazyGravity.' \
    '  stop              Stop the managed LazyGravity bot and Antigravity IDE.' \
    '  status            Show LazyGravity, CDP, and workbench status.' \
    '  repair-sessions   Reset stale renamed chat bindings without conversation IDs.' \
    '  build-lazygravity Build the local LazyGravity submodule.' \
    '  doctor            Run LazyGravity environment and dependency checks.' \
    '  cdp-status        Show CDP endpoint health and available target titles.' \
    '' \
    'Options:' \
    '  -h, --help        Show this help menu.' \
    '  --no-color        Disable colored launcher output.' \
    '  -V, --version     Show launcher version.' \
    '' \
    'The start command:' \
    '  1. Reuses or starts Antigravity IDE with CDP enabled.' \
    '  2. Waits for a usable Antigravity IDE workbench target.' \
    '  3. Starts LazyGravity in the background and writes lazy-gravity.log.' \
    '' \
    'Running without a command shows this help menu.' \
    '' \
    'Configuration:' \
    '  DEBUGGING_PORT    CDP port. Default: 9222' \
    '  ANTIGRAVITY_EXE   Antigravity executable path in Git Bash format.' \
    '  NO_COLOR          Set to any non-empty value to disable colors.'
}

parse_arguments() {
  while (( $# > 0 )); do
    case "$1" in
      -h|--help)
        ACTION='help'
        ;;
      start|stop|status|repair-sessions|build-lazygravity|doctor|cdp-status)
        ACTION="$1"
        ;;
      --no-color)
        export NO_COLOR=1
        ;;
      -V|--version)
        ACTION='version'
        ;;
      *)
        log_error "Unknown option: $1"
        printf 'Run ./run.sh --help for usage.\n' >&2
        exit 2
        ;;
    esac
    shift
  done
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    log_error "Required command not found: $command_name"
    exit 1
  fi
}

read_lazy_gravity_pid() {
  local pid=''

  if [[ -f "$LAZY_GRAVITY_LOCK_FILE" ]]; then
    IFS= read -r pid < "$LAZY_GRAVITY_LOCK_FILE" || true
  elif [[ -f "$LAZY_GRAVITY_PID_FILE" ]]; then
    IFS= read -r pid < "$LAZY_GRAVITY_PID_FILE" || true
  fi

  printf '%s' "$pid"
}

lazy_gravity_is_running() {
  local pid
  pid="$(read_lazy_gravity_pid)"
  [[ -n "$pid" ]] &&
    powershell.exe -NoProfile -Command \
      "if (Get-Process -Id $pid -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" \
      >/dev/null 2>&1
}

cdp_endpoint_is_ready() {
  curl --silent --fail --max-time 2 "$CDP_VERSION_URL" >/dev/null 2>&1
}

cdp_has_workbench_target() {
  curl --silent --fail --max-time 2 "$CDP_TARGETS_URL" 2>/dev/null |
    grep --quiet '"url": *"[^"]*workbench/workbench.html"'
}

cdp_is_ready() {
  cdp_endpoint_is_ready && cdp_has_workbench_target
}

start_antigravity() {
  if [[ ! -x "$ANTIGRAVITY_EXE" ]]; then
    log_error "Antigravity executable not found at: $ANTIGRAVITY_EXE"
    log_error "Set ANTIGRAVITY_EXE in .env using a Git Bash path."
    exit 1
  fi

  log_info "Starting Antigravity with CDP on port $DEBUGGING_PORT..."
  "$ANTIGRAVITY_EXE" "--remote-debugging-port=$DEBUGGING_PORT" >/dev/null 2>&1 &
}

wait_for_cdp() {
  local elapsed=0

  log_info "Waiting for an Antigravity IDE workbench target..."
  while (( elapsed < CDP_STARTUP_TIMEOUT_SECONDS )); do
    if cdp_is_ready; then
      log_success "Antigravity CDP workbench target is ready on port $DEBUGGING_PORT."
      return 0
    fi
    sleep 1
    ((elapsed += 1))
  done

  log_error "No usable Antigravity IDE target appeared at $CDP_TARGETS_URL."
  log_error "Close every Antigravity window, then run ./run.sh again."
  return 1
}

show_cdp_status() {
  require_command curl
  require_command grep
  require_command sed

  if ! cdp_endpoint_is_ready; then
    log_error "CDP endpoint is not responding at $CDP_VERSION_URL."
    return 1
  fi

  log_success "CDP endpoint is responding on port $DEBUGGING_PORT."
  if cdp_has_workbench_target; then
    log_success "A usable Antigravity IDE workbench target is available."
  else
    log_warning "No usable Antigravity IDE workbench target is available."
  fi

  printf '\nCDP targets:\n'
  curl --silent --fail --max-time 2 "$CDP_TARGETS_URL" |
    grep -o '"title": *"[^"]*"' |
    sed -E 's/"title": *"([^"]*)"/  - \1/'
}

start_lazy_gravity() {
  local pid
  local elapsed=0

  if lazy_gravity_is_running; then
    pid="$(read_lazy_gravity_pid)"
    printf '%s\n' "$pid" > "$LAZY_GRAVITY_PID_FILE"
    log_warning "LazyGravity is already running with PID $pid."
    return
  fi

  if [[ -f "$LAZY_GRAVITY_LOCK_FILE" ]]; then
    log_warning "Removing stale LazyGravity lock file."
    rm -f "$LAZY_GRAVITY_LOCK_FILE"
  fi

  rm -f "$LAZY_GRAVITY_PID_FILE"
  log_info "Starting LazyGravity in verbose mode..."
  node "$LAZY_GRAVITY_CLI" --verbose start >> "$LAZY_GRAVITY_LOG_FILE" 2>&1 &
  while (( elapsed < 10 )); do
    sleep 1
    if lazy_gravity_is_running; then
      pid="$(read_lazy_gravity_pid)"
      printf '%s\n' "$pid" > "$LAZY_GRAVITY_PID_FILE"
      log_success "LazyGravity started with PID $pid."
      log_info "Log file: $LAZY_GRAVITY_LOG_FILE"
      return
    fi
    ((elapsed += 1))
  done

  rm -f "$LAZY_GRAVITY_PID_FILE"
  log_error "LazyGravity did not publish a live lock PID. Check $LAZY_GRAVITY_LOG_FILE."
  return 1
}

stop_managed_processes() {
  local pid
  local stopped=0

  require_command powershell.exe

  pid="$(read_lazy_gravity_pid)"
  if [[ -n "$pid" ]] && powershell.exe -NoProfile -Command \
    "if (Get-Process -Id $pid -ErrorAction SilentlyContinue) { Stop-Process -Id $pid -Force; exit 0 } else { exit 1 }" \
    >/dev/null 2>&1; then
    log_info "Stopping LazyGravity PID $pid..."
    stopped=1
    log_success "LazyGravity stopped."
  else
    log_warning "Managed LazyGravity process is not running."
  fi
  rm -f "$LAZY_GRAVITY_PID_FILE"

  if cdp_endpoint_is_ready; then
    require_command powershell.exe
    log_info "Stopping the Antigravity process listening on CDP port $DEBUGGING_PORT..."
    powershell.exe -NoProfile -Command \
      "\$ownerPid=(Get-NetTCPConnection -State Listen -LocalPort $DEBUGGING_PORT -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty OwningProcess); if (\$ownerPid) { Stop-Process -Id \$ownerPid -Force }" \
      >/dev/null
    stopped=1
    log_success "Antigravity CDP process stopped."
  else
    log_warning "Antigravity CDP is not running on port $DEBUGGING_PORT."
  fi

  if (( stopped == 0 )); then
    log_info "Nothing was running."
  fi
}

show_status() {
  local pid
  local exit_code=0

  require_command curl
  require_command grep
  require_command powershell.exe

  pid="$(read_lazy_gravity_pid)"
  if lazy_gravity_is_running; then
    log_success "LazyGravity is running with PID $pid."
  else
    log_warning "LazyGravity is not running."
    exit_code=1
  fi

  if cdp_endpoint_is_ready; then
    log_success "CDP endpoint is responding on port $DEBUGGING_PORT."
  else
    log_warning "CDP endpoint is not responding on port $DEBUGGING_PORT."
    exit_code=1
  fi

  if cdp_has_workbench_target; then
    log_success "An Antigravity IDE workbench target is available."
  else
    log_warning "No Antigravity IDE workbench target is available."
    exit_code=1
  fi

  return "$exit_code"
}

repair_sessions() {
  local backup_file='antigravity.db.backup'

  require_command python
  log_info "Backing up antigravity.db to $backup_file..."
  python -c "import shutil; shutil.copy2('antigravity.db', r'$backup_file')"

  python -c "import sqlite3
db=sqlite3.connect('antigravity.db')
rows=db.execute(\"select channel_id, display_name from chat_sessions where is_renamed=1 and conversation_id is null\").fetchall()
db.execute(\"update chat_sessions set display_name=null, is_renamed=0 where is_renamed=1 and conversation_id is null\")
db.commit()
print(len(rows))
for channel_id, title in rows:
    print(f'{channel_id}: {title}')"

  log_success "Reset stale renamed session bindings. Restart the bot before sending a new prompt."
}

build_lazy_gravity() {
  require_command npm
  if [[ ! -d "$LAZY_GRAVITY_DIR" ]]; then
    log_error "LazyGravity submodule is missing. Run: git submodule update --init --recursive"
    return 1
  fi

  log_info "Building local LazyGravity submodule..."
  (
    cd "$LAZY_GRAVITY_DIR"
    [[ -d node_modules ]] || npm ci
    npm run build
  )
  log_success "Local LazyGravity build completed."
}

start_stack() {
  require_command curl
  require_command grep
  require_command node
  require_command powershell.exe
  build_lazy_gravity

  if cdp_is_ready; then
    log_success "Using the existing Antigravity CDP workbench on port $DEBUGGING_PORT."
  else
    if cdp_endpoint_is_ready; then
      log_warning "CDP responds, but it has no usable Antigravity IDE workbench target."
    fi
    start_antigravity
    wait_for_cdp
  fi

  start_lazy_gravity
}

main() {
  parse_arguments "$@"

  case "$ACTION" in
    help) show_help ;;
    version) printf 'run.sh %s\n' "$SCRIPT_VERSION" ;;
    start) start_stack ;;
    stop) stop_managed_processes ;;
    status) show_status ;;
    repair-sessions) repair_sessions ;;
    build-lazygravity) build_lazy_gravity ;;
    doctor)
      require_command lazy-gravity
      exec lazy-gravity doctor
      ;;
    cdp-status) show_cdp_status ;;
  esac
}

main "$@"
