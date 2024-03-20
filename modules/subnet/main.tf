resource "azurerm_subnet" "subnet" {
  name                 = "snet-${var.app_service_name}-${var.env_prefix}"
  resource_group_name  = var.rg_name
  virtual_network_name = var.vnet_name
  address_prefixes     = var.subnet_address_prefix    
}

#  NAT Gateway creation
resource "azurerm_nat_gateway" "nat_gw_myapp" {
  name                    = "natgw-${var.app_service_name}-${var.env_prefix}"
  location                = var.location
  resource_group_name     = var.rg_name
  sku_name                = var.sku_name
  idle_timeout_in_minutes = 10
}
#PIP creation for NatGW
resource "azurerm_public_ip" "myapp_pip_address-03" {
  name                = "pip-${var.app_service_name}-${var.env_prefix}-3"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = var.allocation_method
  sku                 = var.sku
}
#NAT gateway PIP association
resource "azurerm_nat_gateway_public_ip_association" "natgw_pip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw_myapp.id
  public_ip_address_id = azurerm_public_ip.myapp_pip_address-03.id
}
#Subnet NatGW association
resource "azurerm_subnet_nat_gateway_association" "subnet_natgw_assoc" {
  subnet_id = azurerm_subnet.subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw_myapp.id
}
