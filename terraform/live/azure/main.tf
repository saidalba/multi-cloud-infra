terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Auth is read from ARM_CLIENT_ID / ARM_CLIENT_SECRET / ARM_SUBSCRIPTION_ID /
# ARM_TENANT_ID env vars, or an `az login` session. No secrets belong in tfvars.
provider "azurerm" {
  features {}
}

module "instance" {
  source = "../../modules/azure-instance"

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
