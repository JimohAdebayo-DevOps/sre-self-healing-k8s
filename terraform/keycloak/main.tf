# 1. Connect to Keycloak
provider "keycloak" {
  client_id     = "admin-cli"
  username      = var.keycloak_user
  password      = var.keycloak_password
  url           = var.keycloak_url
}

# ==============================================================================
# REALMS
# ==============================================================================

# 2. Define the "Sikiru-Lab" Realm
# Since this exists, we will IMPORT it in the next step.
resource "keycloak_realm" "sikiru_lab" {
  realm        = "Sikiru-Lab"
  enabled      = true
  display_name = "Sikiru Lab IDP"

  # Production Settings
  # These ensure tokens last long enough for a work day but not forever
  sso_session_idle_timeout = "30m"
  sso_session_max_lifespan = "10h"
  
  # Login Settings
  registration_allowed     = false # Only admins create users
  reset_password_allowed   = true
  remember_me              = true
}


# ==============================================================================
# CLIENTS (The Apps)
# ==============================================================================

# 1. JENKINS CLIENT
resource "keycloak_openid_client" "jenkins" {
  realm_id                     = keycloak_realm.sikiru_lab.id
  client_id                    = "jenkins"
  name                         = "Jenkins CI"
  enabled                      = true
  client_secret                = var.jenkins_secret 

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  direct_access_grants_enabled = true # Needed for some plugins

  valid_redirect_uris = [
    "https://jenkins.sikiru.co.uk/*"
  ]
}

# 2. GRIDOPS PORTAL (Django)
resource "keycloak_openid_client" "gridops" {
  realm_id              = keycloak_realm.sikiru_lab.id
  client_id             = "gridops-portal"
  name                  = "GridOps IDP Portal"
  enabled               = true
  client_secret         = var.gridops_secret

  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true

  valid_redirect_uris = [
    "https://portal.sikiru.co.uk/*",
    "http://localhost:8000/*"
  ]
}

# 3. N8N (via OAuth2 Proxy)
resource "keycloak_openid_client" "n8n" {
  realm_id              = keycloak_realm.sikiru_lab.id
  client_id             = "n8n-proxy"
  name                  = "N8n Automation"
  enabled               = true
  client_secret         = var.n8n_secret

  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true

  valid_redirect_uris = [
    "https://oauth2.sikiru.co.uk/*",
    "https://n8n.sikiru.co.uk/*"
  ]
}


# ==============================================================================
# GROUPS & USERS
# ==============================================================================

# 1. Create a "Developers" Group
resource "keycloak_group" "developers" {
  realm_id = keycloak_realm.sikiru_lab.id
  name     = "Developers"
}

# 2. Create the Junior Dev User
resource "keycloak_user" "junior_dev" {
  realm_id = keycloak_realm.sikiru_lab.id
  username = "junior-dev"
  enabled  = true

  email      = "junior@sikiru.co.uk"
  first_name = "Junior"
  last_name  = "Developer"
  email_verified = true

  initial_password {
    value     = var.junior_initial_password
    temporary = true
  }
}

# 3. Add Junior Dev to the Group
resource "keycloak_user_groups" "junior_groups" {
  realm_id = keycloak_realm.sikiru_lab.id
  user_id  = keycloak_user.junior_dev.id

  group_ids = [
    keycloak_group.developers.id
  ]
}


# ==============================================================================
# EXISTING GROUPS & USERS (Imported)
# ==============================================================================

resource "keycloak_group" "jenkins_admin" {
  realm_id = keycloak_realm.sikiru_lab.id
  name     = "jenkins-admin"
}

resource "keycloak_user" "sikiru_dev" {
  realm_id = keycloak_realm.sikiru_lab.id
  username = "sikiru-dev"
  enabled  = true

  email      = "admin@sikiru.co.uk"
  first_name = "Sikiru"
  last_name  = "Jimoh"
  email_verified = true
}

resource "keycloak_user" "test_read_user" {
  realm_id = keycloak_realm.sikiru_lab.id
  username = "test-read-user"
  enabled  = true

  email      = "jimoh.chibek@gmail.com"
  first_name = "Abdullah"
  last_name  = "Jimoh"
  email_verified = true
}