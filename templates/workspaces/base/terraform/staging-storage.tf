data "azuread_client_config" "current" {}

resource "azurerm_storage_account" "staging_stg" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.ws.name
  location                 = azurerm_resource_group.ws.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  lifecycle { ignore_changes = [tags] }
}

resource "azurerm_storage_share" "staging_ingress" {
  name                 = "ingress"
  storage_account_name = azurerm_storage_account.staging_stg.name
  quota                = 5

  depends_on = [
    azurerm_private_endpoint.staging_stgfilepe
  ]
}

resource "azurerm_storage_share" "staging_egress" {
  name                 = "ingress"
  storage_account_name = azurerm_storage_account.staging_stg.name
  quota                = 5

  depends_on = [
    azurerm_private_endpoint.staging_stgfilepe
  ]
}

resource "azurerm_role_assignment" "ws_pi_group" {
  scope                = azurerm_storage_account.staging_stg.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = data.azuread_client_config.current.object_id
  depends_on = [
    azurerm_subnet.services
  ]
}

resource "azuread_group" "workspace_pis" {
  display_name     = "TRE_ws${short_workspace_id}_PIs"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true
}


resource "azurerm_private_endpoint" "staging_stgfilepe" {
  name                = "stgfilepe-${local.workspace_resource_name_suffix}"
  location            = azurerm_resource_group.ws.location
  resource_group_name = azurerm_resource_group.ws.name
  subnet_id           = azurerm_subnet.services.id

  depends_on = [
    azurerm_subnet.services
  ]

  lifecycle { ignore_changes = [tags] }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.filecore.id]
  }

  private_service_connection {
    name                           = "stgfilepesc-${local.workspace_resource_name_suffix}"
    private_connection_resource_id = azurerm_storage_account.staging_stg.id
    is_manual_connection           = false
    subresource_names              = ["File"]
  }
}
