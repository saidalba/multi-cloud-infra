# Local state for now. To migrate to a remote backend later (e.g. S3 + DynamoDB
# locking), replace this block and run `terraform init -migrate-state`.
terraform {
  backend "local" {}
}
