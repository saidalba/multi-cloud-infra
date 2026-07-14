terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

# Auth is read from ~/.oci/config (DEFAULT profile) or OCI_CLI_* env vars.
# No secrets belong in tfvars.
provider "oci" {
  region = var.region
}

module "instance" {
  source = "../../modules/oci-instance"

  compartment_id      = var.compartment_id
  instance_name       = var.instance_name
  region              = var.region
  ssh_public_key_path = var.ssh_public_key_path
  instance_shape      = var.instance_shape
  shape_ocpus         = var.shape_ocpus
  shape_memory_gb     = var.shape_memory_gb
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
