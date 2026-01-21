# 🚀 SRE Self-Healing Kubernetes Baseline

[![n8n Health](https://argocd.sikiru.co.uk/api/badge?name=n8n-automation-hub)](https://argocd.sikiru.co.uk/applications/n8n-automation-hub)
[![Networking Health](https://argocd.sikiru.co.uk/api/badge?name=ingress-nginx)](https://argocd.sikiru.co.uk/applications/ingress-nginx)
[![Storage Health](https://argocd.sikiru.co.uk/api/badge?name=longhorn-system)](https://argocd.sikiru.co.uk/applications/longhorn-system)

This repository serves as the **Single Source of Truth** for a production-grade, GitOps-managed Kubernetes cluster.

## 🏗 System Architecture
The cluster is built with a layered defense and connectivity strategy.

| Layer | Component | Purpose |
| :--- | :--- | :--- |
| **0: Network** | Calico | Pod-to-Pod connectivity (CNI) |
| **1: Edge** | MetalLB / Nginx Ingress | External IPs and Traffic Routing |
| **2: Storage** | Longhorn | Persistent Block Storage |
| **3: Security** | Cloudflare Tunnel / Cert-Manager | Internet Bridge & SSL Management |
| **4: Persistence** | PostgreSQL | Application Database |
| **5: Apps** | n8n / RAID Exporter | Automation & Hardware Monitoring |

---

## 📂 Repository Structure
We use the **App-of-Apps** pattern to separate logic from configuration.

* **`argocd/`**: Contains "App Launchers" (The Brain).
* **`k8s/`**: Contains actual Kubernetes Manifests (The Body).
* **`src/`**: Custom application source code (RAID Exporter).

---

## 📈 Monitoring Stack & RAID Observation
The observability pipeline is fully automated:
1.  **Custom Exporter:** Python script (in `/src`) simulates RAID health.
2.  **Prometheus:** Discovers the exporter via `ServiceMonitor` and scrapes metrics.
3.  **Grafana:** Provides the primary dashboard for real-time status.

## 🌊 Sync Wave Logic
We use **Sync Waves** to ensure a stable "Boot Sequence" during a rebuild:
1.  **Wave 1:** Networking (MetalLB/Ingress)
2.  **Wave 2:** Security (Cloudflare/Cert-Manager)
3.  **Wave 3:** SSL (ClusterIssuers)
4.  **Wave 4:** Data (Postgres)
5.  **Wave 5:** Applications (n8n, Monitoring)

---

## 🛠 Disaster Recovery
If the cluster is lost:
1. Re-install Argo CD.
2. Add this Repo to Argo CD.
3. Apply the launchers: `kubectl apply -f argocd/ -n argocd`.

## 🛠 SRE Adoption & Management
To transition from manual `kubectl` management to full GitOps, we "claimed" existing resources using the Argo CD adoption ritual. This ensured zero downtime for live services like `argocd.sikiru.co.uk`.

### **The Adoption Ritual (CLI Commands)**
Run these to link existing resources to their respective GitOps applications:

```bash
# Adopting the Ingress Controller
kubectl label deployment ingress-nginx-controller -n ingress-nginx app.kubernetes.io/instance=ingress-nginx --overwrite

# Adopting the SSL Cluster Issuers
kubectl label clusterissuer letsencrypt-cloudflare app.kubernetes.io/instance=cert-manager-config --overwrite

# Adopting existing Ingress Rules
kubectl label ingress n8n -n n8n app.kubernetes.io/instance=n8n-automation-hub --overwrite
kubectl label ingress longhorn-dashboard -n longhorn-system app.kubernetes.io/instance=longhorn-system --overwrite

Self-Healing Mechanics
Drift Detection: Argo CD monitors the cluster 24/7. If a human manually edits a service from LoadBalancer to NodePort, Argo CD will detect the "Drift" and instantly revert it to the LoadBalancer state defined in Git.

Orphan Protection: We use the --cascade=orphan flag when deleting foundational applications (like Calico). This ensures the dashboard entry is removed without destroying the underlying pods, maintaining cluster stability.

🔐 Security & Maintenance
Secrets Management: This repository contains the Logic for the ClusterIssuer but NOT the raw Cloudflare API Token. Sensitive tokens are stored as manual Kubernetes Secrets in the cert-manager namespace to prevent exposure.

Argo CD Self-Management: The argocd-config application manages its own ingress and values, creating a "Circular Logic" that makes the management platform itself disaster-resilient.
