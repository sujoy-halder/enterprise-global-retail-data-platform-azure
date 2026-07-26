variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}

variable "deployment_principal_object_id" {
  description = "Object ID of the deployment principal."
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
  default     = "retail"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "aks_admin_group_object_ids" {
  description = "AKS admin Microsoft Entra group object IDs."
  type        = list(string)
}

variable "allowed_ip_ranges" {
  description = "Allowed public IP CIDR ranges."
  type        = list(string)
}

variable "enable_public_network_access" {
  description = "Enable public network access for dev convenience."
  type        = bool
  default     = false
}

variable "aks_node_vm_size" {
  description = "AKS node VM size."
  type        = string
  default     = "Standard_D4ds_v5"
}

variable "synapse_sql_admin_password" {
  description = "Synapse admin password. Use Key Vault or CI secret injection."
  type        = string
  sensitive   = true
  default     = null
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default = {
    cost_center = "retail-data"
    owner       = "data-platform"
  }
}
