#!/usr/bin/env bash
# Synthetic check for frontend availability and basic latency (SLO probe).
# Usage: ./scripts/slo-probe.sh [URL]
set -euo pipefail

URL="${1:-https://boutique.example.com}"
MAX_LATENCY_MS="${SLO_MAX_LATENCY_MS:-2000}"

echo "SLO probe: ${URL} (max latency ${MAX_LATENCY_MS}ms)"

start_ms=$(python3 -c 'import time; print(int(time.time() * 1000))')
http_code=$(curl -fsS -o /dev/null -w "%{http_code}" "${URL}" || echo "000")
end_ms=$(python3 -c 'import time; print(int(time.time() * 1000))')
latency_ms=$((end_ms - start_ms))

if [[ ! "${http_code}" =~ ^2 ]]; then
  echo "FAIL: HTTP ${http_code} (expected 2xx)"
  exit 1
fi

if [[ "${latency_ms}" -gt "${MAX_LATENCY_MS}" ]]; then
  echo "FAIL: latency ${latency_ms}ms exceeds budget ${MAX_LATENCY_MS}ms"
  exit 1
fi

echo "OK: HTTP ${http_code}, latency ${latency_ms}ms"
exit 0
