# Account-level capability host: enables Agent Service with BYO resources
resource "azapi_resource" "capability_host_account" {
  type                      = "Microsoft.CognitiveServices/accounts/capabilityHosts@2025-06-01"
  name                      = "default"
  parent_id                 = local.foundry_id
  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind = "Agents"
    }
  }

  depends_on = [
    azapi_resource.ai_foundry,
    azapi_resource.connection_search,
    azapi_resource.connection_storage,
    azapi_resource.connection_cosmosdb,
  ]
}

# Project-level capability host: configures agent data storage
resource "azapi_resource" "capability_host_project" {
  type                      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-06-01"
  name                      = "default"
  parent_id                 = local.project_id
  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind       = "Agents"
      threadStorageConnections = ["cosmosdb-connection"]
      vectorStoreConnections   = ["aisearch-connection"]
      storageConnections       = ["agent-storage-connection"]
    }
  }

  depends_on = [
    azapi_resource.capability_host_account,
    azapi_resource.connection_storage_agent,
    azapi_resource.connection_cosmosdb,
    azapi_resource.connection_search,
  ]
}
