resource "azurerm_storage_account" "data" {
  name                          = "stfoundryiq${local.suffix}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  shared_access_key_enabled     = false
  public_network_access_enabled = true # Will be managed after PE is created

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_storage_container" "knowledge" {
  name                 = "knowledge-base"
  storage_account_id   = azurerm_storage_account.data.id
}

# Lock down storage after private endpoints and containers are created
resource "azurerm_storage_account_network_rules" "data" {
  storage_account_id = azurerm_storage_account.data.id
  default_action     = "Deny"
  bypass             = ["AzureServices"]

  depends_on = [
    azurerm_storage_container.knowledge,
    azurerm_private_endpoint.storage,
    azurerm_role_assignment.current_user_storage_blob,
  ]
}
