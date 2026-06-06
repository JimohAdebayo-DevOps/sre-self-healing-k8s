# 1. Explicitly require the modern v3.x Helm provider
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.2.0"
    }
  }
}

# 2. Configure the Helm Provider via Strict Object Assignment
provider "helm" {
  # The compiler strictly demands an object assignment (=) rather than a block wrapper
  kubernetes = {
    host                   = azurerm_kubernetes_cluster.secure_aks.kube_config.0.host
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.secure_aks.kube_config.0.cluster_ca_certificate)

    # The exec plugin must also be assigned as a structured object
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args = [
        "get-token",
        "--environment",
        "AzurePublicCloud",
        "--server-id",
        "6dae42f8-4368-4678-94ff-3960e28e3630", # Entra ID Audience Claim for AKS Control Plane
        "-l",
        "azurecli"
      ]
    }
  }
}

# 3. Bootstrap the GitOps Control Plane deterministically 
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.51.6" # Pinning the version for immutable infrastructure

  # We set insecure to true here because Cloudflare/Nginx will handle SSL termination at the edge
  set = [
    {
      name  = "server.insecure"
      value = "true"
    }
  ]

  # Ensure the cluster and RBAC bindings exist before attempting to install Argo CD
  depends_on = [
    azurerm_kubernetes_cluster.secure_aks,
    azurerm_role_assignment.aks_cluster_admin
  ]
}
