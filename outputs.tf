output "subnet_prefix" {
  value = data.azurerm_subnet.subnetID-001.address_prefixes
}
output "subnet_id" {
  value = data.azurerm_subnet.subnetID-001.id
}
/*output "subnet_id" {
  value = data.azurerm_subnet.subnetID-001.id
}*/
output "vm_pip" {
  value = azurerm_linux_virtual_machine.app_vm.public_ip_address
}