🚀 SRE Self-Healing Kubernetes Monitoring Stack
This project implements a fully automated, GitOps-driven monitoring and observability stack on Kubernetes. It features a custom Python-based RAID status exporter that simulates hardware health and integrates with a professional monitoring pipeline.

🏗 System Architecture
The project follows the GitOps philosophy using Argo CD as the primary orchestrator.

Custom Exporter: A Python application that exposes RAID health metrics at /metrics.

Prometheus: Automatically discovers the exporter using a ServiceMonitor and scrapes metrics.

Grafana: Provides high-visibility dashboards for real-time hardware status.

Argo CD: Ensures "Self-Healing" by automatically correcting any configuration drift in the cluster.

📂 Repository Structure
Plaintext

.
├── k8s/                        # Kubernetes Manifests (The "Source of Truth")
│   ├── deployment.yaml         # Python Exporter Pod & ReplicaSet
│   ├── service.yaml            # Internal load balancer for the exporter
│   └── service-monitor.yaml    # The "Bridge" connecting App to Prometheus
├── src/                        # Application Source Code
│   └── exporter.py             # Python script for RAID status simulation
├── monitoring-stack.yaml       # Argo CD Application for Prometheus/Grafana
├── raid-exporter-app.yaml      # Argo CD Application for our custom code
├── Dockerfile                  # Container blueprint
└── README.md                   # You are here!
🛠 Deployment Instructions
1. Prerequisites
A running Kubernetes cluster.

Argo CD installed in the argocd namespace.

A GitHub Personal Access Token (PAT) for private repo access.

2. Connect the Repository
Register your private repository in the Argo CD UI under Settings > Repositories.

3. Launch the Stack
Apply the "Launcher" YAMLs to your cluster:

Bash

# Deploy the Prometheus & Grafana Stack (Helm)
kubectl apply -f monitoring-stack.yaml -n argocd

# Deploy the Custom RAID Exporter (GitOps)
kubectl apply -f raid-exporter-app.yaml -n argocd
📊 Observability & Self-Healing
Key Metrics
node_raid_status: 1 (Healthy), 0 (Failing).

up{job="raid-exporter-service"}: Status of the exporter's availability.

Self-Healing Mechanics
Infrastructure Level: Argo CD monitors GitHub. If someone manually deletes the ServiceMonitor or modifies the Deployment, Argo CD will automatically revert the changes to match the Git state.

Application Level: Kubernetes' ReplicaSet ensures that if the Python pod crashes, a new one is instantly provisioned.

📈 Dashboard Access
Grafana: http://grafana.sikiru.co.uk

Argo CD: http://argocd.sikiru.co.uk

Note: Default credentials for Grafana are managed via the grafana-admin-credentials secret.
