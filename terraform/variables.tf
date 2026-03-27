variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "vm_admin_username" {
  description = "Admin username for the jump VM"
  type        = string
  default     = "azureuser"
}

variable "vm_admin_password" {
  description = "Admin password for xRDP access on the jump VM"
  type        = string
  sensitive   = true
}
