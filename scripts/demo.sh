#!/usr/bin/env bash
# Drive a short demo: surface Grafana, then trip an alert by knocking the sample
# app's target offline. Leaves port-forwards running until you Ctrl-C.
#   ./scripts/demo.sh aws
#   ./scripts/demo.sh azure
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_cloud "${1:-}"
need kubectl

PIDS=()
cleanup() {
  echo
  echo "==> Cleaning up port-forwards"
  for pid in "${PIDS[@]:-}"; do
    kill "$pid" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

echo "==> Waiting for the stack to become ready"
kubectl -n "${MONITORING_NS}" rollout status deploy/${HELM_RELEASE}-grafana --timeout=300s

GRAFANA_PW="$(kubectl -n "${MONITORING_NS}" get secret ${HELM_RELEASE}-grafana \
  -o jsonpath='{.data.admin-password}' | base64 --decode)"

echo "==> Port-forwarding Grafana to http://localhost:3000  (admin / ${GRAFANA_PW})"
kubectl -n "${MONITORING_NS}" port-forward svc/${HELM_RELEASE}-grafana 3000:80 >/dev/null 2>&1 &
PIDS+=($!)

echo "==> Port-forwarding Prometheus to http://localhost:9090"
kubectl -n "${MONITORING_NS}" port-forward svc/${HELM_RELEASE}-prometheus 9090:9090 >/dev/null 2>&1 &
PIDS+=($!)

echo "==> Port-forwarding AlertManager to http://localhost:9093"
kubectl -n "${MONITORING_NS}" port-forward svc/${HELM_RELEASE}-alertmanager 9093:9093 >/dev/null 2>&1 &
PIDS+=($!)

echo
echo "==> Tripping the SampleAppTargetDown alert: scaling the sample app to zero"
echo "    (watch the AlertManager UI at http://localhost:9093 fire within ~1-2 min)"
kubectl -n demo-app scale deploy/sample-app --replicas=0

cat <<EOF

Demo is live. Open these in your browser and capture screenshots into docs/:
  Grafana       http://localhost:3000   (admin / ${GRAFANA_PW})
  Prometheus    http://localhost:9090   (try: up{job="sample-app"})
  AlertManager  http://localhost:9093   (SampleAppTargetDown will fire)

To restore the app:  kubectl -n demo-app scale deploy/sample-app --replicas=2
Press Ctrl-C to stop the port-forwards.
EOF

# Hold the foreground so port-forwards stay alive.
wait
