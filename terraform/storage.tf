## Document storage - fully private, no bypass, no public access
resource "azurerm_storage_account" "data" {
  name                          = "stfoundryiq${local.suffix}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  shared_access_key_enabled     = false
  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_storage_container" "knowledge" {
  name                 = "knowledge-base"
  storage_account_id   = azurerm_storage_account.data.id
}

## Agent data storage - bypass AzureServices required for Agent Service platform provisioning
resource "azurerm_storage_account" "agent" {
  name                      = "stagent${local.suffix}"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  shared_access_key_enabled = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

# Private endpoint for agent storage
resource "azurerm_private_endpoint" "storage_agent" {
  name                = "pe-st-agent-foundryiq"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-st-agent-foundryiq"
    private_connection_resource_id = azurerm_storage_account.agent.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.zones["privatelink.blob.core.windows.net"].id,
    ]
  }
}
