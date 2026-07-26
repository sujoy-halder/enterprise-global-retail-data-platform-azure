variable "name_prefix" {
  description = "Short lowercase prefix used for Azure resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}

variable "deployment_principal_object_id" {
  description = "Object ID of the deployment principal that should administer Key Vault during bootstrap."
  type        = string
  default     = ""
}

variable "aks_admin_group_object_ids" {
  description = "Microsoft Entra group object IDs that can administer AKS."
  type        = list(string)
}

variable "allowed_ip_ranges" {
  description = "Public IP CIDR ranges allowed to reach restricted Azure services when public access is enabled."
  type        = list(string)
}

variable "enable_public_network_access" {
  description = "Allow public network access for services that support the flag. Use false with private endpoints in locked-down environments."
  type        = bool
  default     = false
}

variable "vnet_address_space" {
  description = "Address space for the platform virtual network."
  type        = list(string)
  default     = ["10.60.0.0/16"]
}

variable "aks_subnet_prefixes" {
  description = "Subnet prefixes for AKS nodes."
  type        = list(string)
  default     = ["10.60.1.0/24"]
}

variable "private_endpoint_subnet_prefixes" {
  description = "Subnet prefixes for private endpoints."
  type        = list(string)
  default     = ["10.60.2.0/24"]
}

variable "eventhub_partition_count" {
  description = "Partition count for each retail event hub."
  type        = number
  default     = 8
}

variable "eventhub_message_retention" {
  description = "Event Hub retention in days."
  type        = number
  default     = 7
}

variable "aks_node_min_count" {
  description = "Minimum AKS node count."
  type        = number
  default     = 3
}

variable "aks_node_max_count" {
  description = "Maximum AKS node count."
  type        = number
  default     = 12
}

variable "aks_node_vm_size" {
  description = "AKS node VM size."
  type        = string
  default     = "Standard_D4ds_v5"
}

variable "databricks_sku" {
  description = "Azure Databricks workspace SKU."
  type        = string
  default     = "premium"
}

variable "synapse_sql_admin_login" {
  description = "Synapse dedicated SQL administrator login."
  type        = string
  default     = "sqladminuser"
}

variable "synapse_sql_admin_password" {
  description = "Synapse SQL administrator password. If null, Terraform generates one and keeps it in state."
  type        = string
  sensitive   = true
  default     = null
}

variable "enable_synapse_sql_pool" {
  description = "Create a dedicated Synapse SQL pool. Keep false for low-cost dev environments."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Log Analytics retention in days."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
