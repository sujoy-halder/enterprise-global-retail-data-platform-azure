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
  default     = "eastus2"
}

variable "aks_admin_group_object_ids" {
  description = "AKS admin Microsoft Entra group object IDs."
  type        = list(string)
}

variable "allowed_ip_ranges" {
  description = "Allowed break-glass public IP CIDR ranges."
  type        = list(string)
}

variable "aks_node_vm_size" {
  description = "AKS node VM size."
  type        = string
  default     = "Standard_D8ds_v5"
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
    criticality = "tier-1"
  }
}
