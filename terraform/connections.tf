# Foundry connections to AI Search and Storage via AzAPI
resource "azapi_resource" "connection_search" {
  type                      = "Microsoft.CognitiveServices/accounts/connections@2025-06-01"
  name                      = "aisearch-connection"
  parent_id                 = azurerm_cognitive_account.foundry.id
  schema_validation_enabled = false

  body = {
    properties = {
      category      = "CognitiveSearch"
      target        = "https://${azurerm_search_service.main.name}.search.windows.net"
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiVersion = "2024-05-01-preview"
        ResourceId = azurerm_search_service.main.id
      }
    }
  }

  depends_on = [azurerm_search_service.main]
}

resource "azapi_resource" "connection_storage" {
  type                      = "Microsoft.CognitiveServices/accounts/connections@2025-06-01"
  name                      = "blob-storage-connection"
  parent_id                 = azurerm_cognitive_account.foundry.id
  schema_validation_enabled = false

  body = {
    properties = {
      category      = "AzureBlob"
      target        = azurerm_storage_account.data.primary_blob_endpoint
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ResourceId    = azurerm_storage_account.data.id
        ContainerName = azurerm_storage_container.knowledge.name
        AccountName   = azurerm_storage_account.data.name
      }
    }
  }

  depends_on = [azurerm_storage_account.data]
}
