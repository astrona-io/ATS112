#!/usr/bin/env bash
# Reference solution for ats-112-capstone-020, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

# --- shared helpers (generated, keep identical in every environment) ---
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
OPENBAO_URL="http://openbao.localtest.me:8200"

# Runs the bao CLI inside the OpenBao pod against its own listener on
# 127.0.0.1:8200. Set BAO_TOKEN before the call to send a token.
bao_pod() {
  kubectl -n openbao exec -i openbao-0 -- \
    env BAO_ADDR=http://127.0.0.1:8200 ${BAO_TOKEN:+BAO_TOKEN=$BAO_TOKEN} bao "$@"
}

# Runs a command in the tester pod (curl and jq) inside the cluster.
tester() { kubectl -n clients exec -i deploy/tester -- "$@"; }

# bao_api METHOD PATH [JSON]: calls the OpenBao HTTP API from the tester pod
# (PATH starts with /v1/). Sends $BAO_TOKEN when set. Prints the body.
bao_api() {
  local method="$1" path="$2" body="${3:-}"
  local token_header=""
  [ -n "${BAO_TOKEN:-}" ] && token_header="X-Vault-Token: ${BAO_TOKEN}"
  if [ -n "$body" ]; then
    printf '%s' "$body" | tester curl -sS -X "$method" -H "${token_header:-X-Ignore: 1}" \
      -H 'Content-Type: application/json' --data-binary @- "$OPENBAO_URL$path"
  else
    tester curl -sS -X "$method" -H "${token_header:-X-Ignore: 1}" "$OPENBAO_URL$path"
  fi
}

# bao_status_code METHOD PATH: prints only the HTTP status code.
bao_status_code() {
  local method="$1" path="$2"
  local token_header=""
  [ -n "${BAO_TOKEN:-}" ] && token_header="X-Vault-Token: ${BAO_TOKEN}"
  tester curl -s -o /dev/null -w '%{http_code}' -X "$method" -H "${token_header:-X-Ignore: 1}" "$OPENBAO_URL$path"
}

# jq_field FILTER: reads JSON on stdin and prints the jq result (jq runs in
# the tester pod, so the machine needs no jq).
jq_field() { tester jq -r "$1"; }

# secret_value SECRET KEY: prints one key of a Secret in the namespace openbao.
secret_value() {
  kubectl -n openbao get secret "$1" -o jsonpath="{.data.$2}" 2>/dev/null | base64 -d 2>/dev/null
}

# configmap_value CONFIGMAP KEY: prints one key of a ConfigMap in openbao.
configmap_value() {
  kubectl -n openbao get configmap "$1" -o jsonpath="{.data.$2}" 2>/dev/null
}

# wait_started: waits until the OpenBao container has started (a sealed or
# uninitialized OpenBao is never Ready, so readiness cannot be used).
wait_started() {
  local rc
  for _ in $(seq 1 120); do
    if [ "$(kubectl -n openbao get pod openbao-0 -o jsonpath='{.status.containerStatuses[0].started}' 2>/dev/null)" = "true" ]; then
      # bao status exits 0 (unsealed), 2 (sealed or not initialized) or 1 (error).
      bao_pod status >/dev/null 2>&1
      rc=$?
      if [ "$rc" = "0" ] || [ "$rc" = "2" ]; then return 0; fi
    fi
    sleep 5
  done
  return 1
}

# root_token: prints the lab-only root token, from the Secret openbao-root
# (environments initialized with key shares) or openbao-init (INIT_MODE=unsealed).
root_token() {
  local token
  token="$(secret_value openbao-root root-token)"
  [ -z "$token" ] && token="$(secret_value openbao-init root-token)"
  printf '%s' "$token"
}

# init_with_shares SHARES THRESHOLD: initializes OpenBao and keeps the lab-only
# key shares (share-1 to share-N) in the Secret openbao-shares and the root
# token in the Secret openbao-root. Does nothing if openbao-shares exists.
init_with_shares() {
  local shares="$1" threshold="$2" init_json number
  kubectl -n openbao get secret openbao-shares >/dev/null 2>&1 && return 0
  init_json="$(bao_pod operator init -key-shares="$shares" -key-threshold="$threshold" -format=json)"
  local share_args=()
  for number in $(seq 1 "$shares"); do
    share_args+=("--from-literal=share-${number}=$(printf '%s' "$init_json" | jq_field ".unseal_keys_b64[$((number - 1))]")")
  done
  kubectl -n openbao create secret generic openbao-shares "${share_args[@]}"
  kubectl -n openbao create secret generic openbao-root \
    --from-literal=root-token="$(printf '%s' "$init_json" | jq_field '.root_token')"
}

# unseal_with_shares NUMBER...: enters the given shares from openbao-shares.
unseal_with_shares() {
  local number
  for number in "$@"; do
    bao_pod operator unseal "$(secret_value openbao-shares "share-${number}")" >/dev/null
  done
}

# ensure_kv_v2: enables a KV version 2 secrets engine at secret/ if missing.
# Needs BAO_TOKEN.
ensure_kv_v2() {
  if [ "$(bao_api GET /v1/sys/mounts | jq_field 'has("secret/")')" != "true" ]; then
    bao_pod secrets enable -path=secret kv-v2 >/dev/null
  fi
}

# seal_field FIELD: prints one field of /v1/sys/seal-status.
seal_field() { bao_api GET /v1/sys/seal-status | jq_field ".$1"; }
# --- end of shared helpers ---

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
helm upgrade openbao openbao/openbao --version 0.30.4 --namespace openbao \
  --values "$SCRIPT_DIR/../manifests/answer-values.yaml"
kubectl -n openbao delete pod openbao-0 --wait=true
wait_started
INIT_JSON="$(bao_pod operator init -key-shares=3 -key-threshold=2 -format=json)"
for index in 0 1; do
  bao_pod operator unseal "$(printf '%s' "$INIT_JSON" | jq_field ".unseal_keys_b64[$index]")" >/dev/null
done
BAO_TOKEN="$(printf '%s' "$INIT_JSON" | jq_field '.root_token')"
ensure_kv_v2
bao_pod kv put secret/platform/owner team=platform >/dev/null
kubectl -n openbao create secret generic lab-answer --from-literal=token="$BAO_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -
