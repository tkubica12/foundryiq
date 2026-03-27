# Azure AI Foundry resource (AzAPI for networkInjections at creation time)
resource "azapi_resource" "ai_foundry" {
  type                      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name                      = "ais-foundryiq-${local.suffix}"
  parent_id                 = azurerm_resource_group.main.id
  location                  = local.location
  schema_validation_enabled = false

  body = {
    kind = "AIServices"
    sku  = { name = "S0" }
    identity = { type = "SystemAssigned" }
    tags = local.tags
    properties = {
      allowProjectManagement = true
      customSubDomainName    = "ais-foundryiq-${local.suffix}"
      publicNetworkAccess    = "Disabled"
      networkAcls            = { defaultAction = "Allow" }
      networkInjections = [{
        scenario                   = "agent"
        subnetArmId                = azurerm_subnet.agent.id
        useMicrosoftManagedNetwork = false
      }]
    }
  }

  response_export_values = ["identity.principalId", "properties.endpoint"]
}

# Foundry Project (AzAPI for consistency)
resource "azapi_resource" "ai_foundry_project" {
  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name                      = "prj-foundryiq-demo"
  parent_id                 = azapi_resource.ai_foundry.id
  location                  = local.location
  schema_validation_enabled = false

  body = {
    sku      = { name = "S0" }
    identity = { type = "SystemAssigned" }
    tags     = local.tags
    properties = {
      displayName = "FoundryIQ Demo Project"
    }
  }

  response_export_values = ["identity.principalId", "properties.internalId"]

  depends_on = [
    azurerm_private_endpoint.foundry,
    azurerm_private_endpoint.storage,
    azurerm_private_endpoint.storage_agent,
    azurerm_private_endpoint.cosmosdb,
    azurerm_private_endpoint.search,
  ]
}

locals {
  foundry_id           = azapi_resource.ai_foundry.id
  foundry_principal_id = azapi_resource.ai_foundry.output.identity.principalId
  foundry_subdomain    = "ais-foundryiq-${local.suffix}"
  project_id           = azapi_resource.ai_foundry_project.id
  project_principal_id = azapi_resource.ai_foundry_project.output.identity.principalId
}
