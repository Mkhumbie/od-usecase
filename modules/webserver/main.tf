#Availability set for VMs
resource "azurerm_availability_set" "app_availset" {
  name = "availset-${var.app_service_name}-${var.env_prefix}"
  location = var.location
  resource_group_name = var.rg_name
  platform_fault_domain_count = 3
  platform_update_domain_count = 3
}

#VM creation###########################
resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "vm1-${var.app_service_name}-${var.env_prefix}"
  resource_group_name = var.rg_name
  location            = var.location
  size                = var.vm1_size
  admin_username      = "adminuser"
  availability_set_id = azurerm_availability_set.app_availset.id
  network_interface_ids = [
    azurerm_network_interface.app-nic.id,
  ]

  admin_ssh_key {
    username   = var.vm1_admin_username
    public_key = file(var.pubkey_location)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }
  user_data = base64encode(file(var.filename))           
}

locals {
  server_dev_trucated = substr(var.app_service_name, -6, -1) # vm-******-dev, retain 6 *'s to make 15 char server name, where starts will be 1st 6 letters of given server name 'app_service_name'
  server_dev = "vm2-${local.server_dev_trucated}-${var.env_prefix}"

  server_prod_trucated = substr(var.app_service_name, -5, -1) # vm-******-prod retain 5 *'s to make 15 char server name
  server_prod = "vm2-${local.server_prod_trucated}-${var.env_prefix}"

  server_staging_trucated = substr(var.app_service_name, -6, -1) # vm-*****-stag retain 5 *'s to make 15 char server name 
  server_staging = "vm2-${local.server_staging_trucated}-${var.env_prefix}"

  dev        = var.env_prefix == "dev" ? local.server_dev : ""
  staging 	 = var.env_prefix == "stag" ? local.server_staging : ""
  prod 	     = var.env_prefix != "prod" && var.env_prefix != "stag" ? local.server_prod : ""
  server_name     = coalesce(local.dev, local.staging, local.prod)
}
# VM2
resource "azurerm_windows_virtual_machine" "app_vm" {
  name                = local.server_name
  resource_group_name = var.rg_name
  location            = var.location
  size                = var.vm2_size
  admin_username      = var.vm2_admin_user
  admin_password      = var.vm_password
  availability_set_id = azurerm_availability_set.app_availset.id
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
}
# NIC-2 creation
resource "azurerm_network_interface" "app-nic-2" {
  name                = "nic-${var.app_service_name}-${var.env_prefix}-2"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_network_security_group" "nsg_subnet" {
  name                = "nsg-${var.app_service_name}-${var.env_prefix}-01"
  location            = var.location
  resource_group_name = var.rg_name

  security_rule {
    name                       = "allow_SSH_inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "*"
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
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_3389_inbound"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_all_outbound"
    priority                   = 103
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
#NSG subnet association
resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.nsg_subnet.id
}

# NIC creation
resource "azurerm_network_interface" "app-nic" {
  name                = "nic-${var.app_service_name}-${var.env_prefix}-1"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip_vm.id
  }
}
resource "azurerm_public_ip" "pip_vm" {
  name                = "pip-app-vm"
  resource_group_name = var.rg_name
  location            = var.location
  allocation_method   = "Static"
  sku = "Standard"
}