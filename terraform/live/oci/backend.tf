# Local state for now. To migrate to a remote backend later (e.g. OCI Object
# Storage), replace this block and run `terraform init -migrate-state`.
terraform {
  backend "local" {}
}
