output "public_ip" {
  value       = oci_core_instance.this.public_ip
  description = "Public IP address of the instance"
}

output "instance_id" {
  value       = oci_core_instance.this.id
  description = "OCID of the instance"
}

output "ssh_user" {
  value       = "ubuntu"
  description = "Default SSH user for the Canonical Ubuntu cloud image"
}
