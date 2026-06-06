# Dynamically retrieve the execution context for Entra ID tenant alignment
data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "secure_aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "sre-cilium-mesh"

  # CORE ZERO-TRUST: Eradicating legacy administrative backdoors
  local_account_disabled = true

  # DATA PLANE ZERO-TRUST: Enabling modern pod-to-Azure authentication
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # CONFIDENTIAL COMPUTING ZERO-TRUST: Forcing Hardware-level Trusted Execution Environments
  default_node_pool {
    name       = "systempool"
    node_count = 2
    vm_size    = "Standard_DC2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }

  # NETWORK MESH: Cilium eBPF Integration
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
  }

  # CONTROL PLANE ZERO-TRUST: Forcing Microsoft Entra ID Authentication & Bootstrapping Access
  azure_active_directory_role_based_access_control {
    tenant_id              = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled     = true
    admin_group_object_ids = ["b7f54214-fd0c-4eaa-b3d2-4ea6012672d9"]
  }

  tags = {
    Environment   = "Ephemeral-10-Day-Lab"
    SecurityModel = "Zero-Trust"
    ManagedBy     = "Terraform"
  }
}

# INFRASTRUCTURE AS CODE: Formalizing the Role-Based Access Control Binding
resource "azurerm_role_assignment" "aks_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.secure_aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = "b7f54214-fd0c-4eaa-b3d2-4ea6012672d9"
}
