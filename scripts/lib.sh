#!/usr/bin/env bash
# Shared helpers for the deploy/demo/destroy scripts.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELM_RELEASE="kube-prometheus-stack"
MONITORING_NS="monitoring"

usage() {
  echo "Usage: $0 <aws|azure>"
  exit 1
}

require_cloud() {
  CLOUD="${1:-}"
  case "$CLOUD" in
    aws | azure) ;;
    *) usage ;;
  esac
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: required tool '$1' not found on PATH" >&2
    exit 1
  }
}

tf_dir() {
  echo "${REPO_ROOT}/${CLOUD}/terraform"
}

# Point kubectl at the cluster terraform just created.
configure_kubectl() {
  pushd "$(tf_dir)" >/dev/null
  eval "$(terraform output -raw configure_kubectl)"
  popd >/dev/null
}
