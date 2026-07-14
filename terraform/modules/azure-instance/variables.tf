variable "instance_name" {
  type        = string
  description = "Name applied to the instance and its supporting network resources"
}

variable "region" {
  type        = string
  description = "Azure region, e.g. eastus"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to the local SSH public key injected into the instance"
}

variable "instance_shape" {
  type        = string
  description = "Azure VM size (Ampere Altra ARM64 by default)"
  default     = "Standard_D2ps_v5"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}
