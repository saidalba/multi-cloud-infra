output "public_ip" {
  value       = aws_instance.this.public_ip
  description = "Public IP address of the instance"
}

output "instance_id" {
  value       = aws_instance.this.id
  description = "ID of the instance"
}

output "ssh_user" {
  value       = "ubuntu"
  description = "Default SSH user for the Canonical Ubuntu AMI"
}
