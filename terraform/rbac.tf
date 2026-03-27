# --- Current user RBAC ---

# Storage Blob Data Contributor - current user
resource "azurerm_role_assignment" "current_user_storage_blob" {
  scope                = azurerm_storage_account.data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Cognitive Services OpenAI Contributor - current user
resource "azurerm_role_assignment" "current_user_openai" {
  scope                = local.foundry_id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Cognitive Services Contributor - current user (for management)
resource "azurerm_role_assignment" "current_user_cognitive" {
  scope                = local.foundry_id
  role_definition_name = "Cognitive Services Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Search Service Contributor - current user
resource "azurerm_role_assignment" "current_user_search_contrib" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Service Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Search Index Data Contributor - current user
resource "azurerm_role_assignment" "current_user_search_data" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# --- AI Search managed identity RBAC ---

# Storage Blob Data Reader - AI Search identity (for indexing)
resource "azurerm_role_assignment" "search_storage_reader" {
  scope                = azurerm_storage_account.data.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_search_service.main.identity[0].principal_id
}

# Cognitive Services OpenAI User - AI Search identity (for AI enrichment)
resource "azurerm_role_assignment" "search_openai_user" {
  scope                = local.foundry_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_search_service.main.identity[0].principal_id
}

# --- Foundry resource managed identity RBAC ---

# Storage Blob Data Contributor - Foundry identity (on document storage)
resource "azurerm_role_assignment" "foundry_storage_blob" {
  scope                = azurerm_storage_account.data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.foundry_principal_id
}

# Storage Blob Data Contributor - Foundry identity (on agent storage)
resource "azurerm_role_assignment" "foundry_agent_storage_blob" {
  scope                = azurerm_storage_account.agent.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.foundry_principal_id
}

# Search Index Data Reader - Foundry identity
resource "azurerm_role_assignment" "foundry_search_reader" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = local.foundry_principal_id
}

# Search Service Contributor - Foundry identity
resource "azurerm_role_assignment" "foundry_search_contrib" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Service Contributor"
  principal_id         = local.foundry_principal_id
}

# --- Foundry project managed identity RBAC ---

# Cognitive Services OpenAI User - Project identity
resource "azurerm_role_assignment" "project_openai_user" {
  scope                = local.foundry_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = local.project_principal_id
}

# Storage Blob Data Contributor - Project identity (on document storage)
resource "azurerm_role_assignment" "project_storage_blob" {
  scope                = azurerm_storage_account.data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.project_principal_id
}

# Storage Blob Data Contributor - Project identity (on agent storage)
resource "azurerm_role_assignment" "project_agent_storage_blob" {
  scope                = azurerm_storage_account.agent.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.project_principal_id
}

# Search Index Data Reader - Project identity
resource "azurerm_role_assignment" "project_search_reader" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = local.project_principal_id
}

# --- Jump VM managed identity RBAC ---

# Owner on resource group - VM identity (for full management from jump host)
resource "azurerm_role_assignment" "vm_rg_owner" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Owner"
  principal_id         = azurerm_linux_virtual_machine.jump.identity[0].principal_id
}

# Cognitive Services OpenAI User - VM identity
resource "azurerm_role_assignment" "vm_openai_user" {
  scope                = local.foundry_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_linux_virtual_machine.jump.identity[0].principal_id
}

# Cognitive Services User - VM identity (broader, for agents)
resource "azurerm_role_assignment" "vm_cognitive_user" {
  scope                = local.foundry_id
  role_definition_name = "Cognitive Services User"
  principal_id         = azurerm_linux_virtual_machine.jump.identity[0].principal_id
}

# Storage Blob Data Contributor - VM identity (read+write)
resource "azurerm_role_assignment" "vm_storage_contributor" {
  scope                = azurerm_storage_account.data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.jump.identity[0].principal_id
}

# Search Index Data Contributor - VM identity (create/manage indexes)
resource "azurerm_role_assignment" "vm_search_data_contrib" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.jump.identity[0].principal_id
}

# Search Service Contributor - VM identity (manage service objects)
resource "azurerm_role_assignment" "vm_search_svc_contrib" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Service Contributor"
  principal_id         = azurerm_linux_virtual_machine.jump.identity[0].principal_id
}

# Search Index Data Reader - VM identity
resource "azurerm_role_assignment" "vm_search_reader" {
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = azurerm_linux_virtual_machine.jump.identity[0].principal_id
}

# Cognitive Services Contributor - VM identity (for agent management)
resource "azurerm_role_assignment" "vm_cognitive_contrib" {
  scope                = local.foundry_id
  role_definition_name = "Cognitive Services Contributor"
  principal_id         = azurerm_linux_virtual_machine.jump.identity[0].principal_id
}

# --- Cross-service RBAC for agentic retrieval ---

# Cognitive Services User - Search identity (knowledge base needs LLM for query planning)
resource "azurerm_role_assignment" "search_cognitive_user" {
  scope                = local.foundry_id
  role_definition_name = "Cognitive Services User"
  principal_id         = azurerm_search_service.main.identity[0].principal_id
}
