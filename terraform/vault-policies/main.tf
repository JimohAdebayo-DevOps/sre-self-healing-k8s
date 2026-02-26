# 1. Configure the Provider (Connects to https://vault.sikiru.co.uk)
provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

# ==============================================================================
# AUTHENTICATION (Login Methods)
# ==============================================================================

# Enable "Username & Password" login
# Note: Since you enabled this in UI, we will 'import' it in the steps below.
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
# The cluster needs to read specific application secrets to run the apps.
resource "vault_policy" "eso_robot" {
  name = "eso-robot-policy"

  policy = <<EOT
# 1. Allow reading the exact secret data
path "secret/data/production-app-05" {
  capabilities = ["read"]
}

# 2. Allow reading secrets nested inside a folder (future-proofing)
path "secret/data/production-app-05/*" {
  capabilities = ["read"]
}

# 3. Allow checking the secret's metadata (ESO uses this to check if the secret changed)
path "secret/metadata/production-app-05" {
  capabilities = ["list", "read"]
}

# 4. Allow listing nested metadata
path "secret/metadata/production-app-05/*" {
  capabilities = ["list", "read"]
}
EOT
}
# ==============================================================================
# USERS (Identity)
# ==============================================================================

# Create the 'junior-dev' user automatically
# This ensures we know exactly who exists in our system.
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