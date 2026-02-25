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
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "external-secrets-role"
  bound_service_account_names      = ["external-secrets"]
  bound_service_account_namespaces = ["external-secrets"]
  token_policies                   = [vault_policy.eso_robot.name]
  token_ttl                        = 3600 # Token expires in 1 hour
}