# Enable the Kubernetes Login Method
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

# Configure Vault to trust your Kubernetes Cluster
resource "vault_kubernetes_auth_backend_config" "config" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://kubernetes.default.svc"
  disable_iss_validation = true
}

# Create the Role for the External Secrets Operator
resource "vault_kubernetes_auth_backend_role" "eso_role" {
  backend                     = vault_auth_backend.kubernetes.path
  role_name                   = "external-secrets-role"
  bound_service_account_names = ["external-secrets"]

  # SECURITY UPDATE: Added application namespaces so Vault trusts ESO when it 
  # synchronizes secrets into the namespaces where your workloads run (e.g., n8n) [1].
  bound_service_account_namespaces = ["external-secrets", "n8n", "default"]

  # SECURITY UPDATE: Appended the new gridops_public_site_policy to the array
  token_policies = [
    vault_policy.eso_robot.name,
    vault_policy.gridops_public_site_policy.name
  ]

  token_ttl = 3600 # Token expires in 1 hour
}