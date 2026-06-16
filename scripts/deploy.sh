#!/usr/bin/env bash
# Stand up the cluster for the chosen cloud and install the observability stack.
#   ./scripts/deploy.sh aws
#   ./scripts/deploy.sh azure
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_cloud "${1:-}"
need terraform
need kubectl
need helm

echo "==> [${CLOUD}] Provisioning cluster with Terraform"
pushd "$(tf_dir)" >/dev/null
terraform init -input=false
terraform apply -auto-approve
popd >/dev/null

echo "==> [${CLOUD}] Configuring kubectl"
configure_kubectl

echo "==> Adding the prometheus-community Helm repo"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update prometheus-community >/dev/null

echo "==> Installing kube-prometheus-stack into the '${MONITORING_NS}' namespace"
helm upgrade --install "${HELM_RELEASE}" prometheus-community/kube-prometheus-stack \
  --namespace "${MONITORING_NS}" --create-namespace \
  --values "${REPO_ROOT}/helm/values-kube-prometheus-stack.yaml" \
  --wait --timeout 15m

echo "==> Applying custom alert rules"
kubectl apply -f "${REPO_ROOT}/helm/alert-rules.yaml" -n "${MONITORING_NS}"

echo "==> Deploying the sample workload"
kubectl apply -f "${REPO_ROOT}/workload/sample-app.yaml"

echo
echo "Done. Stack is installed on ${CLOUD}."
echo "Next: ./scripts/demo.sh ${CLOUD}"
