
# 2. Centralized Database Credentials (Required by n8n, Keycloak, Django)
resource "vault_kv_secret_v2" "postgres_credentials" {
  mount       = vault_mount.kvv2.path
  name        = "postgres-credentials"
  data_json   = jsonencode({
    "postgres-password" = var.postgres-credentials-password
    "password" = var.postgres-password
  })
}

resource "vault_kv_secret_v2" "keycloak_db_secret" {
  mount       = vault_mount.kvv2.path
  name        = "keycloak-db-secret"
  data_json   = jsonencode({
    "password" = var.keycloak-db-secret-password
  })
}

# 3. Django Portal & GitHub Integration
resource "vault_kv_secret_v2" "gridops_secrets" {
  mount       = vault_mount.kvv2.path
  name        = "gridops-secrets"
  data_json   = jsonencode({
    "django-secret-key" = var.gridops-secrets-django-secret-key
    "oidc-secret"       = var.gridops-secrets-oidc-secret
  })
}

resource "vault_kv_secret_v2" "github_token" {
  mount       = vault_mount.kvv2.path
  name        = "github-token"
  data_json   = jsonencode({
    "GITHUB_TOKEN"= var.github-token-passord
  })
}

# 4. n8n Automation Engine Cryptography
resource "vault_kv_secret_v2" "n8n_secrets" {
  mount       = vault_mount.kvv2.path
  name        = "n8n-secrets"
  data_json   = jsonencode({
    "N8N_ENCRYPTION_KEY"      = var.n8n-secrets-N8N_ENCRYPTION_KEY
    "N8N_BASIC_AUTH_ACTIVE"   = "true", 
    "N8N_BASIC_AUTH_USER"     = "admin", 
    "N8N_BASIC_AUTH_PASSWORD" = var.N8N_BASIC_AUTH_PASSWORD
  })
}

# 5. Keycloak Identity Master Control
resource "vault_kv_secret_v2" "keycloak_admin_secret" {
  mount       = vault_mount.kvv2.path
  name        = "keycloak-admin-secret"
  data_json   = jsonencode({
    "admin-password" = var.keycloak-admin-secret-admin-password
  })
}

# 6. OAuth2-Proxy Sovereign Gatekeeper
resource "vault_kv_secret_v2" "oauth2_proxy_creds" {
  mount       = vault_mount.kvv2.path
  name        = "oauth2-proxy-creds"
  data_json   = jsonencode({
    "client-id"     = "oauth2-proxy",
    "client-secret" = var.oauth2-proxy-creds-client-secret,
    "cookie-secret" = var.oauth2-proxy-creds-cookie-secret
  })
}

# 7. Jenkins CI Master Credentials
resource "vault_kv_secret_v2" "jenkins_admin_credentials" {
  mount       = vault_mount.kvv2.path
  name        = "jenkins-admin-credentials"
  data_json   = jsonencode({
    "jenkins-admin-user"     = "admin",
    "jenkins-admin-password" = var.jenkins-admin-credentials-password
  })
}

# 8. Grafana SRE Dashboard Credentials
resource "vault_kv_secret_v2" "grafana_admin_credentials" {
  mount       = vault_mount.kvv2.path
  name        = "grafana-admin-credentials"
  data_json   = jsonencode({
    "admin-user"     = "admin",
    "admin-password" = var.grafana-admin-credentials
  })
}

# 9. Cloudflare Zero Trust Tunnel
resource "vault_kv_secret_v2" "cloudflare_tunnel_token" {
  mount       = vault_mount.kvv2.path
  name        = "cloudflare-tunnel-token"
  data_json   = jsonencode({
    "token" = var.cloudflare-tunnel-token
  })
}

# 10. GitOps Zero-Touch Pipeline Credentials
resource "vault_kv_secret_v2" "sre_repo_creds" {
  # This mathematically links to the mount in your secrets-engine.tf file
  mount       = vault_mount.kvv2.path 
  name        = "sre-repo-creds"
  data_json   = jsonencode({
    "url"           = "url: https://github.com/JimohAdebayo-DevOps/sre-self-healing-k8s.git",
    "password"      = var.sre-repo-creds-password,
    "username"      = "JimohAdebayo-DevOps",
    "type"          = "git"
  })
}

# 11. GitOps Master Control Plane Password
resource "vault_kv_secret_v2" "argocd_initial_admin" {
  mount       = vault_mount.kvv2.path
  name        = "argocd-initial-admin-secret"
  data_json   = jsonencode({
    "password" = var.argocd-initial-admin-secret-password
  })
}

# Jenkins Docker Hub Credentials for Kaniko
resource "vault_kv_secret_v2" "dockerhub_creds" {
  mount       = vault_mount.kvv2.path
  name        = "dockerhub-creds"
  data_json   = jsonencode({
    "username" = "jimoh1990",
    "password" = var.dockerhub-creds-password
  })
}

# Jenkins GitHub Credentials for GitOps Write-Back
resource "vault_kv_secret_v2" "jenkins_github_creds" {
  mount       = vault_mount.kvv2.path
  name        = "jenkins-github-creds"
  data_json   = jsonencode({
    "username" = "JimohAdebayo-DevOps",
    "token"    = var.jenkins-github-creds
  })
}

# ==============================================================
# SECRETS.TF: Jenkins Keycloak OIDC Client Secret
# ==============================================================
resource "vault_kv_secret_v2" "jenkins-keycloak-secret" {
  mount       = vault_mount.kvv2.path
  name        = "jenkins-keycloak-secret"
  data_json   = jsonencode({
    "client-secret" = var.jenkins-keycloak-secret-client-secret
  })
}

# 1. The Public Site Secret (Strictly Scoped)
resource "vault_kv_secret_v2" "gridops_public_site" {
  mount       = vault_mount.kvv2.path 
  name        = "gridops-public-site" 
  
  # Containing strictly the keys requested by the application Helm chart
  data_json   = jsonencode({
    "my_password" = var.gridops-public-site-my_password
  })
}