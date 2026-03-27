# SSH Key for jump VM
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Bastion Public IP
resource "azurerm_public_ip" "bastion" {
  name                = "pip-bas-foundryiq-demo-sc"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# Azure Bastion - Standard SKU for SSH tunneling and native client support
resource "azurerm_bastion_host" "main" {
  name                   = "bas-foundryiq-demo-sc"
  location               = azurerm_resource_group.main.location
  resource_group_name    = azurerm_resource_group.main.name
  sku                    = "Standard"
  tunneling_enabled      = true
  ip_connect_enabled     = true
  shareable_link_enabled = false

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = local.tags
}

# NIC for jump VM
resource "azurerm_network_interface" "jump" {
  name                = "nic-vm-foundryiq-jump"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.workload.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Jump VM - Ubuntu 24.04 with xrdp
resource "azurerm_linux_virtual_machine" "jump" {
  name                            = "vm-foundryiq-jump"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = "Standard_D2s_v5"
  admin_username                  = var.vm_admin_username
  disable_password_authentication = false
  admin_password                  = var.vm_admin_password
  network_interface_ids           = [azurerm_network_interface.jump.id]
  tags                            = local.tags

  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    admin_username    = var.vm_admin_username
    admin_password    = var.vm_admin_password
    foundry_endpoint  = "https://${local.foundry_subdomain}.cognitiveservices.azure.com"
    project_name      = "prj-foundryiq-demo"
    search_endpoint   = "https://${azurerm_search_service.main.name}.search.windows.net"
    storage_account   = azurerm_storage_account.data.name
    storage_endpoint  = azurerm_storage_account.data.primary_blob_endpoint
    gpt41_deployment  = azurerm_cognitive_deployment.gpt41.name
    gpt54_deployment  = azurerm_cognitive_deployment.gpt54.name
    subscription_id   = var.subscription_id
    resource_group    = azurerm_resource_group.main.name
    foundry_name      = "ais-foundryiq-${local.suffix}"
  }))

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
