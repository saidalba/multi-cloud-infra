terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Auth is read from the default AWS credential chain (env vars,
# ~/.aws/credentials, SSO, instance profile, etc). No secrets belong in tfvars.
provider "aws" {
  region = var.region
}

module "instance" {
  source = "../../modules/aws-instance"

  instance_name       = var.instance_name
  region              = var.region
  ssh_public_key_path = var.ssh_public_key_path
  instance_shape      = var.instance_shape
  tags                = var.tags
}

output "public_ip" {
  value = module.instance.public_ip
}

output "instance_id" {
  value = module.instance.instance_id
}

output "ssh_user" {
  value = module.instance.ssh_user
}
