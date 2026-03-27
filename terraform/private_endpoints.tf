# Wait for Foundry account to fully provision before creating PE
resource "time_sleep" "wait_for_foundry" {
  depends_on      = [azurerm_cognitive_account.foundry]
  create_duration = "120s"
}

# Private Endpoint: AI Services / Foundry
resource "azurerm_private_endpoint" "foundry" {
  name                = "pe-ais-foundryiq"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-ais-foundryiq"
    private_connection_resource_id = azurerm_cognitive_account.foundry.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.zones["privatelink.cognitiveservices.azure.com"].id,
      azurerm_private_dns_zone.zones["privatelink.openai.azure.com"].id,
      azurerm_private_dns_zone.zones["privatelink.services.ai.azure.com"].id,
    ]
  }

  depends_on = [
    time_sleep.wait_for_foundry,
    azurerm_cognitive_deployment.gpt41,
    azurerm_cognitive_account_project.main,
  ]
}

# Private Endpoint: Storage Account (blob)
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-st-foundryiq"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-st-foundryiq"
    private_connection_resource_id = azurerm_storage_account.data.id
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

# Private Endpoint: AI Search
resource "azurerm_private_endpoint" "search" {
  name                = "pe-srch-foundryiq"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-srch-foundryiq"
    private_connection_resource_id = azurerm_search_service.main.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.zones["privatelink.search.windows.net"].id,
    ]
  }
}
