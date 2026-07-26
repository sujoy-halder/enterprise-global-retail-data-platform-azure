locals {
  clean_prefix = replace(lower(var.name_prefix), "-", "")
  name_seed    = substr("${local.clean_prefix}${var.environment}${random_string.suffix.result}", 0, 18)

  storage_account_name = substr("st${replace(local.name_seed, "-", "")}", 0, 24)
  acr_name             = substr("acr${replace(local.name_seed, "-", "")}", 0, 50)
  key_vault_name       = substr("kv-${var.name_prefix}-${var.environment}-${random_string.suffix.result}", 0, 24)

  event_hubs = toset([
    "pos-transactions",
    "online-orders",
    "inventory",
    "supply-chain",
    "warehouse",
    "delivery-tracking",
    "customer-behavior",
    "product-catalog",
    "marketing-campaigns",
    "iot-warehouse-sensors",
  ])

  consumer_groups = {
    for pair in setproduct(local.event_hubs, ["adf", "databricks", "snowflake-loader"]) :
    "${pair[0]}-${pair[1]}" => {
      event_hub = pair[0]
      name      = pair[1]
    }
  }

  diagnostics = {
    eventhub    = azurerm_eventhub_namespace.this.id
    keyvault    = azurerm_key_vault.this.id
    acr         = azurerm_container_registry.this.id
    datafactory = azurerm_data_factory.this.id
    databricks  = azurerm_databricks_workspace.this.id
    synapse     = azurerm_synapse_workspace.this.id
    aks         = azurerm_kubernetes_cluster.this.id
  }

  common_tags = merge(
    var.tags,
    {
      environment = var.environment
      workload    = "enterprise-global-retail-data-platform"
      managed_by  = "terraform"
    }
  )

  synapse_sql_admin_password = (
    var.synapse_sql_admin_password != null
    ? var.synapse_sql_admin_password
    : random_password.synapse_sql_admin[0].result
  )
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "random_password" "synapse_sql_admin" {
  count   = var.synapse_sql_admin_password == null ? 1 : 0
  length  = 32
  special = true
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name_prefix}-${var.environment}-${random_string.suffix.result}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name_prefix}-${var.environment}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  tags                = local.common_tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.aks_subnet_prefixes
}

resource "azurerm_subnet" "private_endpoints" {
  name                              = "snet-private-endpoints"
  resource_group_name               = azurerm_resource_group.this.name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = var.private_endpoint_subnet_prefixes
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_prefix}-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${var.name_prefix}-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = local.common_tags
}

resource "azurerm_storage_account" "lake" {
  name                              = local.storage_account_name
  resource_group_name               = azurerm_resource_group.this.name
  location                          = azurerm_resource_group.this.location
  account_tier                      = "Standard"
  account_replication_type          = var.environment == "prod" ? "ZRS" : "LRS"
  account_kind                      = "StorageV2"
  is_hns_enabled                    = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  public_network_access_enabled     = var.enable_public_network_access
  infrastructure_encryption_enabled = true

  blob_properties {
    versioning_enabled       = true
    last_access_time_enabled = true
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action = "Deny"
    ip_rules       = var.allowed_ip_ranges
    bypass         = ["AzureServices"]
  }

  tags = local.common_tags
}

resource "azurerm_storage_data_lake_gen2_filesystem" "zones" {
  for_each           = toset(["bronze", "silver", "gold", "checkpoints", "quarantine"])
  name               = each.key
  storage_account_id = azurerm_storage_account.lake.id
}

resource "azurerm_eventhub_namespace" "this" {
  name                          = "evhns-${var.name_prefix}-${var.environment}-${random_string.suffix.result}"
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  sku                           = "Standard"
  capacity                      = var.environment == "prod" ? 4 : 1
  public_network_access_enabled = var.enable_public_network_access
  minimum_tls_version           = "1.2"
  auto_inflate_enabled          = true
  maximum_throughput_units      = var.environment == "prod" ? 20 : 4
  tags                          = local.common_tags
}

resource "azurerm_eventhub" "streams" {
  for_each            = local.event_hubs
  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = azurerm_resource_group.this.name
  partition_count     = var.eventhub_partition_count
  message_retention   = var.eventhub_message_retention
}

resource "azurerm_eventhub_consumer_group" "consumers" {
  for_each            = local.consumer_groups
  name                = each.value.name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.streams[each.value.event_hub].name
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_key_vault" "this" {
  name                          = local.key_vault_name
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  enabled_for_disk_encryption   = true
  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = var.enable_public_network_access

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ip_ranges
  }

  tags = local.common_tags
}

resource "azurerm_container_registry" "this" {
  name                          = local.acr_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = var.enable_public_network_access
  tags                          = local.common_tags
}

resource "azurerm_data_factory" "this" {
  name                   = "adf-${var.name_prefix}-${var.environment}-${random_string.suffix.result}"
  location               = azurerm_resource_group.this.location
  resource_group_name    = azurerm_resource_group.this.name
  public_network_enabled = false

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_databricks_workspace" "this" {
  name                          = "dbw-${var.name_prefix}-${var.environment}-${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  sku                           = var.databricks_sku
  managed_resource_group_name   = "rg-${var.name_prefix}-${var.environment}-databricks-${random_string.suffix.result}"
  public_network_access_enabled = var.enable_public_network_access
  tags                          = local.common_tags
}

resource "azurerm_databricks_access_connector" "this" {
  name                = "dbac-${var.name_prefix}-${var.environment}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_synapse_workspace" "this" {
  name                                 = "syn-${var.name_prefix}-${var.environment}-${random_string.suffix.result}"
  resource_group_name                  = azurerm_resource_group.this.name
  location                             = azurerm_resource_group.this.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.zones["gold"].id
  sql_administrator_login              = var.synapse_sql_admin_login
  sql_administrator_login_password     = local.synapse_sql_admin_password
  managed_virtual_network_enabled      = true
  public_network_access_enabled        = var.enable_public_network_access

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_synapse_sql_pool" "gold" {
  count                = var.enable_synapse_sql_pool ? 1 : 0
  name                 = "gold"
  synapse_workspace_id = azurerm_synapse_workspace.this.id
  sku_name             = var.environment == "prod" ? "DW500c" : "DW100c"
  create_mode          = "Default"
  storage_account_type = var.environment == "prod" ? "GRS" : "LRS"
  tags                 = local.common_tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                              = "aks-${var.name_prefix}-${var.environment}-${random_string.suffix.result}"
  location                          = azurerm_resource_group.this.location
  resource_group_name               = azurerm_resource_group.this.name
  dns_prefix                        = "aks-${var.name_prefix}-${var.environment}"
  sku_tier                          = var.environment == "prod" ? "Standard" : "Free"
  local_account_disabled            = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  azure_policy_enabled              = true
  role_based_access_control_enabled = true

  default_node_pool {
    name                 = "system"
    vm_size              = var.aks_node_vm_size
    vnet_subnet_id       = azurerm_subnet.aks.id
    auto_scaling_enabled = true
    min_count            = var.aks_node_min_count
    max_count            = var.aks_node_max_count
    os_disk_size_gb      = 128
    zones                = var.environment == "prod" ? ["1", "2", "3"] : null
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    tenant_id              = var.tenant_id
    azure_rbac_enabled     = true
    admin_group_object_ids = var.aks_admin_group_object_ids
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  api_server_access_profile {
    authorized_ip_ranges = var.allowed_ip_ranges
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  tags = local.common_tags
}

resource "azurerm_user_assigned_identity" "ingestion_api" {
  name                = "id-${var.name_prefix}-${var.environment}-ingestion-api"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_federated_identity_credential" "ingestion_api" {
  name                = "fic-${var.name_prefix}-${var.environment}-ingestion-api"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.ingestion_api.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.this.oidc_issuer_url
  subject             = "system:serviceaccount:retail-data-platform:retail-ingestion-api"
}

resource "azurerm_role_assignment" "deployment_keyvault_admin" {
  count                = var.deployment_principal_object_id == "" ? 0 : 1
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.deployment_principal_object_id
}

resource "azurerm_role_assignment" "adf_storage" {
  scope                = azurerm_storage_account.lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "synapse_storage" {
  scope                = azurerm_storage_account.lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "databricks_storage" {
  scope                = azurerm_storage_account.lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.this.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "ingestion_eventhub_sender" {
  scope                            = azurerm_eventhub_namespace.this.id
  role_definition_name             = "Azure Event Hubs Data Sender"
  principal_id                     = azurerm_user_assigned_identity.ingestion_api.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "ingestion_keyvault_reader" {
  scope                            = azurerm_key_vault.this.id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = azurerm_user_assigned_identity.ingestion_api.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_monitor_diagnostic_setting" "platform" {
  for_each                   = local.diagnostics
  name                       = "diag-${var.name_prefix}-${var.environment}"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  name                       = "diag-${var.name_prefix}-${var.environment}-blob"
  target_resource_id         = "${azurerm_storage_account.lake.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
