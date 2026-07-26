module "retail_platform" {
  source = "../../modules/azure-retail-platform"

  name_prefix                    = var.name_prefix
  environment                    = "dev"
  location                       = var.location
  tenant_id                      = var.tenant_id
  deployment_principal_object_id = var.deployment_principal_object_id
  aks_admin_group_object_ids     = var.aks_admin_group_object_ids
  allowed_ip_ranges              = var.allowed_ip_ranges
  enable_public_network_access   = var.enable_public_network_access
  eventhub_partition_count       = 4
  eventhub_message_retention     = 3
  aks_node_min_count             = 2
  aks_node_max_count             = 5
  aks_node_vm_size               = var.aks_node_vm_size
  enable_synapse_sql_pool        = false
  synapse_sql_admin_password     = var.synapse_sql_admin_password
  tags                           = var.tags
}
