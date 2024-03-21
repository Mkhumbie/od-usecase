#Data source to access the configuration of the AzureRM provider
data "azurerm_client_config" "current" {}

#Random id creation
resource "random_id" "kv_random_id" {
  byte_length = 3
}

#Key vault creation
resource "azurerm_key_vault" "key_vault" {
  name                        = "kv-${var.app_service_name}-${random_id.kv_random_id.hex}"
  location                    = var.location
  resource_group_name         = var.rg_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge",
    ]

    storage_permissions = [
      "Get",
    ]
  }
  #depends_on = [ azurerm_resource_group.app_grp ]
}
#Key secret creation and storing in vault
resource "azurerm_key_vault_secret" "app-secret" {
  name         = "secret"
  value        = var.secret
  key_vault_id = azurerm_key_vault.key_vault.id
 # depends_on = [ azurerm_key_vault.key_vault ]
}