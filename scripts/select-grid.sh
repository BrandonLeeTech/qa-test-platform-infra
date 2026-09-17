#!/usr/bin/env bash
set -euo pipefail

mode="${GRID_MODE:-auto}"
remote_grid_url="${REMOTE_GRID_URL:-}"
local_grid_url="${LOCAL_GRID_URL:-}"
grid_health_timeout="${GRID_HEALTH_TIMEOUT_SECONDS:-3}"

status_url() {
  local grid_url="${1%/}"
  grid_url="${grid_url%/wd/hub}"
  printf '%s/status' "$grid_url"
}

is_healthy() {
  local grid_url="$1"
  [[ -n "$grid_url" ]] || return 1
  curl \
    --fail \
    --silent \
    --show-error \
    --max-time "$grid_health_timeout" \
    "$(status_url "$grid_url")" >/dev/null
}

select_required_grid() {
  local label="$1"
  local grid_url="$2"
  if is_healthy "$grid_url"; then
    printf '%s\n' "$grid_url"
    return 0
  fi
  printf '%s Grid is unavailable: %s\n' "$label" "${grid_url:-not configured}" >&2
  return 1
}

case "$mode" in
  remote)
    select_required_grid "Remote" "$remote_grid_url"
    ;;
  local)
    select_required_grid "Local" "$local_grid_url"
    ;;
  auto)
    if is_healthy "$remote_grid_url"; then
      printf '%s\n' "Selected remote Grid: $remote_grid_url" >&2
      printf '%s\n' "$remote_grid_url"
    elif is_healthy "$local_grid_url"; then
      printf '%s\n' "Remote Grid unavailable; selected local Grid: $local_grid_url" >&2
      printf '%s\n' "$local_grid_url"
    else
      printf '%s\n' "No healthy Selenium Grid is available." >&2
      exit 1
    fi
    ;;
  *)
    printf '%s\n' "Unsupported GRID_MODE '$mode'; use remote, local, or auto." >&2
    exit 2
    ;;
esac

