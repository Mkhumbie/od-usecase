#Azure Bastion subnet creation
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.rg_name
  virtual_network_name = var.vnet_name
  address_prefixes     = var.subnet_address_prefixes_bastion

}

#Azure Bastion PIP
resource "azurerm_public_ip" "bastion_ip" {
  name                = "pip-bastion-${var.env_prefix}"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}
# Bastion host
resource "azurerm_bastion_host" "bastion_host" {
  name                = "bas-vnet${var.env_prefix}-${var.location}"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                 = "bastion-configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}