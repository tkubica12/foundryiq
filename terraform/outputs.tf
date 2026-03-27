output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "foundry_endpoint" {
  value = "https://${azurerm_cognitive_account.foundry.custom_subdomain_name}.cognitiveservices.azure.com"
}

output "foundry_name" {
  value = azurerm_cognitive_account.foundry.name
}

output "project_name" {
  value = azurerm_cognitive_account_project.main.name
}

output "search_endpoint" {
  value = "https://${azurerm_search_service.main.name}.search.windows.net"
}

output "search_name" {
  value = azurerm_search_service.main.name
}

output "storage_account_name" {
  value = azurerm_storage_account.data.name
}

output "storage_endpoint" {
  value = azurerm_storage_account.data.primary_blob_endpoint
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.jump.name
}

output "vm_private_ip" {
  value = azurerm_network_interface.jump.private_ip_address
}

output "bastion_name" {
  value = azurerm_bastion_host.main.name
}

output "ssh_private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}

output "gpt41_deployment" {
  value = azurerm_cognitive_deployment.gpt41.name
}

output "gpt54_deployment" {
  value = azurerm_cognitive_deployment.gpt54.name
}

output "embedding_deployment" {
  value = azurerm_cognitive_deployment.embedding.name
}

output "project_resource_id" {
  value = azurerm_cognitive_account_project.main.id
}

output "project_endpoint" {
  value = "https://${azurerm_cognitive_account.foundry.custom_subdomain_name}.services.ai.azure.com/api/projects/${azurerm_cognitive_account_project.main.name}"
}

output "suffix" {
  value = local.suffix
}

output "subscription_id" {
  value = var.subscription_id
}
