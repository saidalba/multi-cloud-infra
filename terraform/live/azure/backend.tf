# Local state for now. To migrate to a remote backend later (e.g. an Azure
# Storage Account container), replace this block and run
# `terraform init -migrate-state`.
terraform {
  backend "local" {}
}
