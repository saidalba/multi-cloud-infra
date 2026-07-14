variable "compartment_id" {
  type        = string
  description = "OCID of the compartment to provision resources in"
}

variable "instance_name" {
  type        = string
  description = "Name applied to the instance and its supporting network resources"
  default     = "oci-ubuntu-arm"
}

variable "region" {
  type        = string
  description = "OCI region identifier, e.g. us-ashburn-1"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to the local SSH public key injected into the instance"
}

variable "instance_shape" {
  type        = string
  description = "OCI compute shape (ARM64 Ampere by default)"
  default     = "VM.Standard.A1.Flex"
}

variable "shape_ocpus" {
  type        = number
  description = "OCPUs for the flexible shape"
  default     = 1
}

variable "shape_memory_gb" {
  type        = number
  description = "Memory in GB for the flexible shape"
  default     = 6
}

variable "tags" {
  type        = map(string)
  description = "Freeform tags applied to all resources"
  default = {
    environment = "dev"
    managed_by  = "terraform"
  }
}
