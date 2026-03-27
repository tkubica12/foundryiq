# Azure AI Search - Standard tier required for shared private links
resource "azurerm_search_service" "main" {
  name                          = "srch-foundryiq-${local.suffix}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  sku                           = "standard"
  replica_count                 = 1
  partition_count               = 1
  semantic_search_sku           = "standard"
  public_network_access_enabled = false
  local_authentication_enabled  = false

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

# Shared private link: AI Search -> Storage Account (blob)
resource "azurerm_search_shared_private_link_service" "storage" {
  name               = "spl-storage"
  search_service_id  = azurerm_search_service.main.id
  subresource_name   = "blob"
  target_resource_id = azurerm_storage_account.data.id
  request_message    = "AI Search shared private link to storage"
}

# Shared private link: AI Search -> AI Services/Foundry (openai_account)
resource "azurerm_search_shared_private_link_service" "foundry" {
  name               = "spl-foundry"
  search_service_id  = azurerm_search_service.main.id
  subresource_name   = "openai_account"
  target_resource_id = local.foundry_id
  request_message    = "AI Search shared private link to Foundry"

  depends_on = [
    azurerm_search_shared_private_link_service.storage,
    azurerm_cognitive_deployment.gpt41,
    azapi_resource.ai_foundry_project,
  ]
}

# Approve shared private link connections on target resources
resource "null_resource" "approve_search_spl_storage" {
  depends_on = [azurerm_search_shared_private_link_service.storage]

  provisioner "local-exec" {
    command     = <<-EOT
      for ($i = 0; $i -lt 12; $i++) {
        $conns = az network private-endpoint-connection list --id "${azurerm_storage_account.data.id}" --query "[?properties.privateLinkServiceConnectionState.status=='Pending'].id" -o tsv 2>$null
        if ($conns) {
          foreach ($conn in $conns -split "`n") {
            $conn = $conn.Trim()
            if ($conn) {
              az network private-endpoint-connection approve --id $conn --description "Approved by Terraform" 2>$null
              Write-Host "Approved: $conn"
              exit 0
            }
          }
        }
        Start-Sleep -Seconds 10
      }
    EOT
    interpreter = ["pwsh", "-Command"]
  }
}

resource "null_resource" "approve_search_spl_foundry" {
  depends_on = [azurerm_search_shared_private_link_service.foundry]

  provisioner "local-exec" {
    command     = <<-EOT
      for ($i = 0; $i -lt 12; $i++) {
        $conns = az network private-endpoint-connection list --id "${local.foundry_id}" --query "[?properties.privateLinkServiceConnectionState.status=='Pending'].id" -o tsv 2>$null
        if ($conns) {
          foreach ($conn in $conns -split "`n") {
            $conn = $conn.Trim()
            if ($conn) {
              az network private-endpoint-connection approve --id $conn --description "Approved by Terraform" 2>$null
              Write-Host "Approved: $conn"
              exit 0
            }
          }
        }
        Start-Sleep -Seconds 10
      }
    EOT
    interpreter = ["pwsh", "-Command"]
  }
}
