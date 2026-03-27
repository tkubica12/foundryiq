# Foundry project-level connections (must be at project scope for capability hosts)
resource "azapi_resource" "connection_search" {
  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name                      = "aisearch-connection"
  parent_id                 = local.project_id
  schema_validation_enabled = false

  body = {
    properties = {
      category = "CognitiveSearch"
      target   = "https://${azurerm_search_service.main.name}.search.windows.net"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ApiVersion = "2025-05-01-preview"
        ResourceId = azurerm_search_service.main.id
        location   = local.location
      }
    }
  }

  depends_on = [azurerm_search_service.main]
}

resource "azapi_resource" "connection_storage" {
  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name                      = "blob-storage-connection"
  parent_id                 = local.project_id
  schema_validation_enabled = false

  body = {
    properties = {
      category = "AzureBlob"
      target   = azurerm_storage_account.data.primary_blob_endpoint
      authType = "AAD"
      metadata = {
        ApiType       = "Azure"
        ResourceId    = azurerm_storage_account.data.id
        ContainerName = azurerm_storage_container.knowledge.name
        AccountName   = azurerm_storage_account.data.name
        location      = local.location
      }
    }
  }

  depends_on = [azurerm_storage_account.data]
}

# Storage connection for agent file storage (points to agent-specific storage with AzureServices bypass)
resource "azapi_resource" "connection_storage_agent" {
  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name                      = "agent-storage-connection"
  parent_id                 = local.project_id
  schema_validation_enabled = false

  body = {
    properties = {
      category = "AzureStorageAccount"
      target   = azurerm_storage_account.agent.primary_blob_endpoint
      authType = "AAD"
      metadata = {
        ApiType     = "Azure"
        ResourceId  = azurerm_storage_account.agent.id
        AccountName = azurerm_storage_account.agent.name
        location    = local.location
      }
    }
  }

  depends_on = [azurerm_storage_account.agent]
}

# Cosmos DB connection for agent thread storage
resource "azapi_resource" "connection_cosmosdb" {
  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name                      = "cosmosdb-connection"
  parent_id                 = local.project_id
  schema_validation_enabled = false

  body = {
    properties = {
      category = "CosmosDb"
      target   = azurerm_cosmosdb_account.agent.endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_cosmosdb_account.agent.id
        location   = local.location
      }
    }
  }

  depends_on = [azurerm_cosmosdb_account.agent]
}
