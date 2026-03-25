variable "vault_token" {
  description = "The Vault Token used to authenticate (Root token or Admin token)"
  type        = string
  sensitive   = true # Terraform will hide this from logs
}

variable "vault_address" {
  description = "Public URL of the Vault server"
  type        = string
  default     = "https://vault.sikiru.co.uk"
}


# ==============================================================
# VARIABLES.TF: Cryptographic Inputs & Zero Trust Boundaries
# ==============================================================

# --------------------------------------------------------------
# 1. CI/CD & GitOps Master Credentials
# --------------------------------------------------------------
variable "jenkins-admin-credentials-password" {
  description = "The master admin password for the Jenkins CI pipeline controller."
  type        = string
  sensitive   = true
}

variable "jenkins-github-creds" {
  description = "The GitHub PAT used by Jenkins for GitOps write-back operations."
  type        = string
  sensitive   = true
}

variable "dockerhub-creds-password" {
  description = "The Docker Hub password/token for Kaniko image builds."
  type        = string
  sensitive   = true
}

variable "argocd-initial-admin-secret-password" {
  description = "The master admin password for the ArgoCD control plane UI."
  type        = string
  sensitive   = true
}

variable "sre-repo-creds-password" {
  description = "The GitHub PAT allowing ArgoCD to pull the cluster state."
  type        = string
  sensitive   = true
}

variable "github-token-passord" { 
  description = "The GitHub PAT used generally for repository operations."
  type        = string
  sensitive   = true
}

# --------------------------------------------------------------
# 2. Sovereign Identity (Keycloak & OAuth2-Proxy)
# --------------------------------------------------------------
variable "keycloak-admin-secret-admin-password" {
  description = "The master admin console password for Keycloak."
  type        = string
  sensitive   = true
}

variable "keycloak-db-secret-password" {
  description = "The database password specifically scoped for Keycloak."
  type        = string
  sensitive   = true
}

variable "jenkins-keycloak-secret-client-secret" {
  description = "The OIDC client secret for Jenkins to authenticate via Keycloak."
  type        = string
  sensitive   = true
}

variable "oauth2-proxy-creds-client-secret" {
  description = "The OIDC client secret shared between Keycloak and OAuth2-Proxy."
  type        = string
  sensitive   = true
}

variable "oauth2-proxy-creds-cookie-secret" {
  description = "The 32-byte base64 encoded string used to cryptographically sign proxy session cookies."
  type        = string
  sensitive   = true
}

# --------------------------------------------------------------
# 3. Core Databases
# --------------------------------------------------------------
variable "postgres-credentials-password" {
  description = "The highly secure master password for the PostgreSQL instance."
  type        = string
  sensitive   = true
}

variable "postgres-password" {
  description = "The application-level password for the n8n/GridOps database user."
  type        = string
  sensitive   = true
}

# --------------------------------------------------------------
# 4. Automation & Applications (n8n & GridOps)
# --------------------------------------------------------------
variable "n8n-secrets-N8N_ENCRYPTION_KEY" {
  description = "The 32-character hex key used by n8n to encrypt third-party API credentials."
  type        = string
  sensitive   = true
}

variable "N8N_BASIC_AUTH_PASSWORD" {
  description = "The basic authentication password for the n8n automation hub."
  type        = string
  sensitive   = true
}

variable "gridops-secrets-django-secret-key" {
  description = "The cryptographic signing key for the Django GridOps portal."
  type        = string
  sensitive   = true
}

variable "gridops-secrets-oidc-secret" {
  description = "The OIDC client secret for the Django portal."
  type        = string
  sensitive   = true
}

variable "gridops-public-site-my_password" {
  description = "The database/auth password for the public-facing GridOps site."
  type        = string
  sensitive   = true
}

# --------------------------------------------------------------
# 5. Observability & Networking
# --------------------------------------------------------------
variable "grafana-admin-credentials" {
  description = "The master admin password for the Grafana observability dashboard."
  type        = string
  sensitive   = true
}

variable "cloudflare-tunnel-token" {
  description = "The Cloudflare Tunnel token bridging the internal ingress to the public edge."
  type        = string
  sensitive   = true
}