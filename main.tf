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

data "azurerm_subnet" "subnetID-001" {
  name                 = "snet-${var.env_prefix}-${var.location}-001"
  virtual_network_name = azurerm_virtual_network.vnet-mypapp.name
  resource_group_name  = azurerm_resource_group.rg-myapp.name
}

/*data "azurerm_subnet" "subnetID-002" {
  name                 = "snet-${var.env_prefix}-${var.location}-002"
  virtual_network_name = azurerm_virtual_network.vnet-mypapp.name
  resource_group_name  = local.rg_name
}*/


resource "azurerm_resource_group" "rg-myapp" {
  name     = "rg-${var.app_service}-${var.env_prefix}-001"
  location = var.location
}

resource "azurerm_virtual_network" "vnet-mypapp" {
  name                = "vnet-${var.env_prefix}-${var.location}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-myapp.name
  address_space       = var.vnet_address_space

  subnet {
    name           = "snet-${var.env_prefix}-${var.location}-001"
    address_prefix = var.subnet_address_prefix_01
    security_group = azurerm_network_security_group.nsg_subnet-001.id
  }

  tags = {
    environment = var.env_prefix
  }
}
#PIP creation 
resource "azurerm_public_ip" "myapp_pip_address-01" {
  name                = "pip-${var.app_service}-${var.env_prefix}-1"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-myapp.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
#PIP creation for VM address 
resource "azurerm_public_ip" "myapp_pip_address-02" {
  name                = "pip-${var.app_service}-${var.env_prefix}-2"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-myapp.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
# NAT Gateway creation
/*resource "azurerm_nat_gateway" "nat_gw_myapp" {
  name                    = "natgw-${var.app_service}-${var.env_prefix}"
  location                = var.location
  resource_group_name     = azurerm_resource_group.rg-myapp.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}*/
#NAT gateway PIP association
/*resource "azurerm_nat_gateway_public_ip_association" "natgw_pip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw_myapp.id
  public_ip_address_id = azurerm_public_ip.myapp_pip_address-01.id
}*/

# NIC creation
resource "azurerm_network_interface" "app-nic-1" {
  name                = "nic-${var.app_service}-${var.env_prefix}-1"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-myapp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnetID-001.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.myapp_pip_address-01.id
  }
}
# NIC-2 creation
resource "azurerm_network_interface" "app-nic-2" {
  name                = "nic-${var.app_service}-${var.env_prefix}-2"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-myapp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnetID-001.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.myapp_pip_address-02.id
  }
}
#NAT gateway subnet association
/*esource "azurerm_subnet_nat_gateway_association" "natgw-subnet001-assoc" {
  subnet_id      = data.azurerm_subnet.subnetID-001.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw_myapp.id
}*/

resource "azurerm_network_security_group" "nsg_subnet-001" {
  name                = "nsg-${var.app_service}-${var.env_prefix}-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-myapp.name

  security_rule {
    name                       = "allow_SSH_inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_8080_inbound"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 8080
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_3389_inbound"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_all_outbound"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    environment = var.env_prefix
  }
}
#VM creation###########################
resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "app-vm"
  resource_group_name = azurerm_resource_group.rg-myapp.name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.app-nic-1.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }
  user_data = base64encode(file("entry_script.sh"))           
}
/*resource "azurerm_windows_virtual_machine" "app_vm" {
  name                = "windServ1"
  resource_group_name = azurerm_resource_group.rg-myapp.name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.app-nic-2.id,
  ]
  

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-datacenter-gensecond"
    version   = "latest"
  }
  #depends_on = [ azurerm_network_interface.app_interface, azurerm_key_vault_secret.app-secret
   #]
}*/

#######################################
