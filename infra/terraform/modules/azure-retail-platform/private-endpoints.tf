resource "azurerm_private_dns_zone" "blob" {
  count               = var.enable_public_network_access ? 0 : 1
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "dfs" {
  count               = var.enable_public_network_access ? 0 : 1
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "vault" {
  count               = var.enable_public_network_access ? 0 : 1
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "acr" {
  count               = var.enable_public_network_access ? 0 : 1
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "eventhub" {
  count               = var.enable_public_network_access ? 0 : 1
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count                 = var.enable_public_network_access ? 0 : 1
  name                  = "blob-${var.environment}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "dfs" {
  count                 = var.enable_public_network_access ? 0 : 1
  name                  = "dfs-${var.environment}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.dfs[0].name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "vault" {
  count                 = var.enable_public_network_access ? 0 : 1
  name                  = "vault-${var.environment}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.vault[0].name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  count                 = var.enable_public_network_access ? 0 : 1
  name                  = "acr-${var.environment}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "eventhub" {
  count                 = var.enable_public_network_access ? 0 : 1
  name                  = "eventhub-${var.environment}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.eventhub[0].name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.common_tags
}

resource "azurerm_private_endpoint" "storage_blob" {
  count               = var.enable_public_network_access ? 0 : 1
  name                = "pe-${var.name_prefix}-${var.environment}-blob"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.lake.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob[0].id]
  }
}

resource "azurerm_private_endpoint" "storage_dfs" {
  count               = var.enable_public_network_access ? 0 : 1
  name                = "pe-${var.name_prefix}-${var.environment}-dfs"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-dfs"
    private_connection_resource_id = azurerm_storage_account.lake.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dfs"
    private_dns_zone_ids = [azurerm_private_dns_zone.dfs[0].id]
  }
}

resource "azurerm_private_endpoint" "keyvault" {
  count               = var.enable_public_network_access ? 0 : 1
  name                = "pe-${var.name_prefix}-${var.environment}-kv"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-kv"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "vault"
    private_dns_zone_ids = [azurerm_private_dns_zone.vault[0].id]
  }
}

resource "azurerm_private_endpoint" "acr" {
  count               = var.enable_public_network_access ? 0 : 1
  name                = "pe-${var.name_prefix}-${var.environment}-acr"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = azurerm_container_registry.this.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr[0].id]
  }
}

resource "azurerm_private_endpoint" "eventhub" {
  count               = var.enable_public_network_access ? 0 : 1
  name                = "pe-${var.name_prefix}-${var.environment}-eventhub"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-eventhub"
    private_connection_resource_id = azurerm_eventhub_namespace.this.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "eventhub"
    private_dns_zone_ids = [azurerm_private_dns_zone.eventhub[0].id]
  }
}
