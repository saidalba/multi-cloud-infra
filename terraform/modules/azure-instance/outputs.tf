output "public_ip" {
  value       = azurerm_public_ip.this.ip_address
  description = "Public IP address of the instance"
}

output "instance_id" {
  value       = azurerm_linux_virtual_machine.this.id
  description = "Resource ID of the instance"
}

output "ssh_user" {
  value       = "ubuntu"
  description = "SSH admin username configured on the VM"
}
