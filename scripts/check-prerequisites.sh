#!/usr/bin/env bash
set -euo pipefail

missing=0

for tool_name in docker kubectl helm curl; do
  if command -v "$tool_name" >/dev/null 2>&1; then
    printf '%-12s %s\n' "$tool_name" "OK ($(command -v "$tool_name"))"
  else
    printf '%-12s %s\n' "$tool_name" "MISSING"
    missing=1
  fi
done

if command -v terraform >/dev/null 2>&1; then
  printf '%-12s %s\n' terraform "OK ($(command -v terraform))"
else
  printf '%-12s %s\n' terraform "OPTIONAL until the cloud phase"
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
  printf '%s\n' "Kubernetes cluster: UNREACHABLE"
  missing=1
else
  printf '%s\n' "Kubernetes cluster: OK"
fi

exit "$missing"

