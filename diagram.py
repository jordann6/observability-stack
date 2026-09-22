"""Architecture diagram for the multi-cloud Observability Stack.

The same kube-prometheus-stack runs on EKS and AKS; the only real difference is
cluster provisioning. Critical alerts hand off to the incident-responder runbook,
and OpenCost attributes cluster spend by the CostCenter tag the guardrails gate
requires, so observability is part of the platform loop, not a standalone tool.

Usage: pip install diagrams, then python3 diagram.py
Requires graphviz (brew install graphviz).
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EKS
from diagrams.azure.compute import AKS
from diagrams.onprem.monitoring import Prometheus, Grafana
from diagrams.onprem.client import Users
from diagrams.saas.chat import Slack
from diagrams.onprem.ci import GitlabCI
from diagrams.programming.flowchart import Decision

with Diagram(
    "Multi-Cloud Observability Stack",
    filename="docs/architecture",
    show=False,
    direction="LR",
):
    engineer = Users("Platform engineer\nTerraform + Helm")

    with Cluster("CI (guardrails gate)"):
        gate = GitlabCI("conftest gate\ntags + CostCenter\n+ cost budget")

    engineer >> Edge(label="PR") >> gate

    def monitoring(name, cloud_node):
        with Cluster(f"{name}: kube-prometheus-stack"):
            prom = Prometheus("Prometheus\nscrape + rules")
            graf = Grafana("Grafana\ndashboards")
            am = Decision("Alertmanager\nrouting")
            cloud_node >> prom
            prom >> graf
            prom >> Edge(label="alert rules") >> am
        return am

    with Cluster("AWS"):
        eks = EKS("EKS cluster")
        am_aws = monitoring("EKS", eks)

    with Cluster("Azure"):
        aks = AKS("AKS cluster")
        am_azks = monitoring("AKS", aks)

    gate >> Edge(label="apply", style="dashed") >> eks
    gate >> Edge(label="apply", style="dashed") >> aks

    with Cluster("Incident response loop"):
        responder = Decision("incident-responder\nrunbook (n8n)\nsummarize + remediate")
        slack = Slack("Slack\nescalate / verify")
        responder >> slack

    am_aws >> Edge(label="severity=critical\nwebhook") >> responder
    am_azks >> Edge(label="severity=critical\nwebhook") >> responder
