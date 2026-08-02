# S3 backend to store Terraform state
terraform {
  backend "s3" {
    bucket       = "tko-armageddon-tfstate-bucket"
    key          = "armageddon/lab-12/prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true

    # Enables native S3 locking
    use_lockfile = true
  }
}





    # Documentation - https://developer.hashicorp.com/terraform/language/backend
    # https://developer.hashicorp.com/terraform/language/backend/s3
