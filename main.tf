terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.95.0"
    }
  }
}

provider "azurerm" {
    subscription_id = var.subscript_id
    client_id       = var.client_id
    tenant_id       = var.tenant_id
    client_secret   = var.client_secret
    features {}
}
# Resource Group for the resources to be deployed
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.app_service_name}-${var.env_prefix}"
  location = var.location
}
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.env_prefix}-${var.location}"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

module "od-app-snet" {
  source = "./modules/subnet"
  vnet_name = azurerm_virtual_network.vnet.name
  app_service_name = var.app_service_name
  vnet_address_space  = var.vnet_address_space
  subnet_address_prefix = var.subnet_address_prefix
  location = var.location
  env_prefix =var.env_prefix
  rg_name  = azurerm_resource_group.rg.name
  sku = var.sku
  sku_name = var.sku_name
  allocation_method = var.allocation_method
}
module "od-appOnUbuntu-server" {
  source = "./modules/webserver"
  rg_name = azurerm_resource_group.rg.name
  os_publisher = var.os_publisher
  os_offer = var.os_offer
  os_sku= var.os_sku
  os_version = var.os_version
  app_service_name = var.app_service_name
  env_prefix = var.env_prefix
  subnet_id = module.od-app-snet.subnet_object.id
  location = var.location
  vm_password = module.credentials_vault.vaulted_pwd.value
  filename = var.filename
}
module "azure_bastion" {
  source = "./modules/bastion"
  env_prefix = var.env_prefix
  location = var.location
  rg_name = azurerm_resource_group.rg.name
  vnet_name = azurerm_virtual_network.vnet.name
  subnet_address_prefixes_bastion = var.subnet_address_bastion
}
module "credentials_vault" {
  source = "./modules/keyvault"
  app_service_name = var.app_service_name
  env_prefix = var.env_prefix
  location = var.location
  rg_name = azurerm_resource_group.rg.name
  secret = var.secret
}




#######################################
