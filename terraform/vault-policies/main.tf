# 1. Configure the Provider (Connects to https://vault.sikiru.co.uk)
provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

# ==============================================================================
# AUTHENTICATION (Login Methods)
# ==============================================================================

# Enable "Username & Password" login
resource "vault_auth_backend" "userpass" {
  type = "userpass"

  # Production Security: Force users to log in again every 24 hours
  tune {
    default_lease_ttl = "1h"
    max_lease_ttl     = "24h"
    token_type        = "default-service"
  }
}

# ==============================================================================
# POLICIES (The Laws)
# ==============================================================================

# POLICY 1: Junior Developers
# They can edit config, but CANNOT see database passwords.
resource "vault_policy" "junior_dev" {
  name = "junior-dev-policy"

  policy = <<EOT
# Allow navigating the folder structure in the UI
path "secret/metadata/production-app-05/*" {
  capabilities = ["list"]
}

# Allow full access to the safe 'app-config' file
path "secret/data/production-app-05/app-config" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# EXPLICITLY DENY access to the database password
path "secret/data/production-app-05/database" {
  capabilities = ["deny"]
}
EOT
}

# POLICY 2: The Cluster Robot (External Secrets Operator)
# Grants the Kubernetes operator permission to read any application secret dynamically.
resource "vault_policy" "eso_robot" {
  name = "eso-robot-policy"

  policy = <<EOT
# 1. Allow reading ALL secret data payloads across the GridOps platform
path "secret/data/*" {
  capabilities = ["read"]
}

# 2. Allow reading ALL nested secret data
path "secret/data/*/*" {
  capabilities = ["read"]
}

# 3. Allow checking ALL secret metadata (ESO requires this to detect version changes)
path "secret/metadata/*" {
  capabilities = ["list", "read"]
}

# 4. Allow listing ALL nested metadata
path "secret/metadata/*/*" {
  capabilities = ["list", "read"]
}
EOT
}

 
# =====================================================================
# SECURE POLICY: GridOps Public Site
# Enforces Principle of Least Privilege for the ESO ServiceAccount
# =====================================================================
resource "vault_policy" "gridops_public_site_policy" {
  name = "gridops-public-site-policy"

  policy = <<EOT
# Grant read access to the specific secret data
path "secret/data/gridops-public-site" {
  capabilities = ["read"]
}

# Grant access to the metadata (Strictly required by Vault KV V2 engine)
path "secret/metadata/gridops-public-site" {
  capabilities = ["list", "read"]
}
EOT
}

# ==============================================================================
# USERS (Identity)
# ==============================================================================

# Create the 'junior-dev' user automatically
resource "vault_generic_endpoint" "user_junior" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/junior-dev"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "password": "production-password-change-me",
  "token_policies": ["junior-dev-policy"]
}
EOT
}