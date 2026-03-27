# Azure AI Foundry resource (new generation - Cognitive Account with project management)
resource "azurerm_cognitive_account" "foundry" {
  name                       = "ais-foundryiq-${local.suffix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  kind                       = "AIServices"
  sku_name                   = "S0"
  custom_subdomain_name      = "ais-foundryiq-${local.suffix}"
  project_management_enabled = true

  identity {
    type = "SystemAssigned"
  }

  network_acls {
    default_action = "Deny"
  }

  tags = local.tags
}

# Foundry Project
resource "azurerm_cognitive_account_project" "main" {
  name                 = "prj-foundryiq-demo"
  cognitive_account_id = azurerm_cognitive_account.foundry.id
  location             = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}
