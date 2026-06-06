data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "sre_rg" {
  name     = "rg-ephemeral-aks-lab"
  location = "eastus"
}

module "zero_trust_aks" {
  source              = "./modules/zero_trust_aks"
  cluster_name        = "aks-zerotrust-10day"
  location            = azurerm_resource_group.sre_rg.location
  resource_group_name = azurerm_resource_group.sre_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
}
