#!/usr/bin/env bash
# Tear everything down so the cluster stops costing money.
#   ./scripts/destroy.sh aws
#   ./scripts/destroy.sh azure
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_cloud "${1:-}"
need terraform

# Best-effort: remove Helm release and workloads first so cloud load balancers /
# PVCs created by the chart are cleaned up before terraform destroys the cluster.
if command -v kubectl >/dev/null 2>&1 && kubectl cluster-info >/dev/null 2>&1; then
  echo "==> Removing the sample workload and Helm release"
  kubectl delete -f "${REPO_ROOT}/workload/sample-app.yaml" --ignore-not-found
  helm uninstall "${HELM_RELEASE}" -n "${MONITORING_NS}" || true
else
  echo "==> No reachable cluster; skipping in-cluster cleanup"
fi

echo "==> [${CLOUD}] Destroying cluster with Terraform"
pushd "$(tf_dir)" >/dev/null
terraform destroy -auto-approve
popd >/dev/null

echo
echo "Done. ${CLOUD} resources destroyed."
