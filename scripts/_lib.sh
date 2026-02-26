#!/usr/bin/env bash
# _lib.sh — shared helpers for EVC Mesh OpenClaw skill scripts.
# Source this file from other scripts:
#   source "$(dirname "$0")/_lib.sh"

# mesh_curl <curl-args...>
#   Performs an HTTP request.
#   - On success (HTTP < 400): prints response body to stdout.
#   - On failure (HTTP >= 400): prints "Error: HTTP {code}" and response body
#     to stderr, then returns 1.
#   - On curl transport error (DNS, connection refused, etc.): curl's own
#     error message is printed to stderr (via -S) and returns 1.
mesh_curl() {
  local response http_code body
  response=$(curl -sS -w '\n%{http_code}' "$@")
  http_code=$(tail -n1 <<< "$response")
  body=$(sed '$d' <<< "$response")

  if [[ "$http_code" -ge 400 ]]; then
    echo "Error: HTTP ${http_code}" >&2
    echo "$body" >&2
    return 1
  fi

  echo "$body"
}

# mesh_curl_status <curl-args...>
#   Like mesh_curl, but for requests that return no body on success (e.g. DELETE → 204).
#   - On success (HTTP < 400): prints the HTTP status code to stdout.
#   - On failure (HTTP >= 400): prints "Error: HTTP {code}" and response body
#     to stderr, then returns 1.
mesh_curl_status() {
  local response http_code body
  response=$(curl -sS -w '\n%{http_code}' "$@")
  http_code=$(tail -n1 <<< "$response")
  body=$(sed '$d' <<< "$response")

  if [[ "$http_code" -ge 400 ]]; then
    echo "Error: HTTP ${http_code}" >&2
    echo "$body" >&2
    return 1
  fi

  echo "$http_code"
}
