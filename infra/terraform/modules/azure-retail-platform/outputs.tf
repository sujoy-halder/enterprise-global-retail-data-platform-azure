output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "storage_account_name" {
  value = azurerm_storage_account.lake.name
}

output "adls_filesystems" {
  value = keys(azurerm_storage_data_lake_gen2_filesystem.zones)
}

output "eventhub_namespace_name" {
  value = azurerm_eventhub_namespace.this.name
}

output "eventhub_names" {
  value = keys(azurerm_eventhub.streams)
}

output "data_factory_name" {
  value = azurerm_data_factory.this.name
}

output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.this.workspace_url
}

output "synapse_workspace_name" {
  value = azurerm_synapse_workspace.this.name
}

output "acr_login_server" {
  value = azurerm_container_registry.this.login_server
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "aks_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "ingestion_workload_identity_client_id" {
  value = azurerm_user_assigned_identity.ingestion_api.client_id
}
