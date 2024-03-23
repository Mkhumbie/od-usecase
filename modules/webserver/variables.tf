variable rg_name {}
variable location {}
variable os_publisher {
    description = "The organization that created the image. Examples: Canonical, MicrosoftWindowsServer"
    default = "Canonical"
}
variable os_offer {
    description = "The name of a group of related images created by a publisher. Examples: UbuntuServer, WindowsServer"
    default = "0001-com-ubuntu-server-jammy"
}
variable os_sku {
    description = "An instance of an offer, such as a major release of a distribution. Examples: 18.04-LTS, 2019-Datacenter"
    default = "22_04-lts-gen2"  
}
variable os_version {
    description = "The version number of an image SKU."
    default = "latest"
}
variable app_service_name {
    description = "Service/VM name being provisioned or deployed"
}
variable env_prefix {
    description = "Environment being deployed/provisioned on. eg dev, stag, prod" 
}
variable subnet_id {
  description = "Subnet ID of webserver"
}
variable vm_password {}
variable vm1_size {
    default = "Standard_B1s"
}
variable vm1_admin_username{
    default = "adminuser"
}
variable vm2_size {
    default = "Standard_B1s"
}
variable vm2_admin_user{
    default = "adminuser"
}
variable pubkey_location {
    default = "~/.ssh/id_rsa.pub"
}
variable storage_account_type{
    default = "Standard_LRS"
}
variable "filename" {
  default = ""
}
