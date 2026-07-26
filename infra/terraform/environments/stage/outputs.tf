output "platform" {
  value = {
    resource_group_name                   = module.retail_platform.resource_group_name
    storage_account_name                  = module.retail_platform.storage_account_name
    eventhub_namespace_name               = module.retail_platform.eventhub_namespace_name
    acr_login_server                      = module.retail_platform.acr_login_server
    aks_cluster_name                      = module.retail_platform.aks_cluster_name
    key_vault_uri                         = module.retail_platform.key_vault_uri
    ingestion_workload_identity_client_id = module.retail_platform.ingestion_workload_identity_client_id
  }
}
