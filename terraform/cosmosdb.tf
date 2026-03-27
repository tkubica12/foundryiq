# Cosmos DB for Foundry Agent Service thread storage (required for standard agent setup)
resource "azurerm_cosmosdb_account" "agent" {
  name                          = "cosmos-foundryiq-${local.suffix}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  # Entra-only auth is the security control; public access needed for Foundry control plane
  public_network_access_enabled = true
  local_authentication_disabled = true

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

# Private Endpoint: Cosmos DB
resource "azurerm_private_endpoint" "cosmosdb" {
  name                = "pe-cosmos-foundryiq"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-cosmos-foundryiq"
    private_connection_resource_id = azurerm_cosmosdb_account.agent.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.zones["privatelink.documents.azure.com"].id,
    ]
  }
}

# RBAC: Foundry identity needs Cosmos DB access
resource "azurerm_cosmosdb_sql_role_assignment" "foundry_cosmos" {
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.agent.name
  role_definition_id  = "${azurerm_cosmosdb_account.agent.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = local.foundry_principal_id
  scope               = azurerm_cosmosdb_account.agent.id
}

resource "azurerm_cosmosdb_sql_role_assignment" "project_cosmos" {
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.agent.name
  role_definition_id  = "${azurerm_cosmosdb_account.agent.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = local.project_principal_id
  scope               = azurerm_cosmosdb_account.agent.id
}

# ARM-level Cosmos DB Contributor for capability host validation
resource "azurerm_role_assignment" "foundry_cosmos_contrib" {
  scope                = azurerm_cosmosdb_account.agent.id
  role_definition_name = "Cosmos DB Operator"
  principal_id         = local.foundry_principal_id
}

resource "azurerm_role_assignment" "project_cosmos_contrib" {
  scope                = azurerm_cosmosdb_account.agent.id
  role_definition_name = "Cosmos DB Operator"
  principal_id         = local.project_principal_id
}
