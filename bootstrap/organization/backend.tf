# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
terraform {
  backend "s3" {
    bucket         = "snp-mockup-bank-eu-central-1-deployment-terraform-state"
    dynamodb_table = "TerraformLock"
    encrypt        = true
    key            = "organization/terraform.tfstate"
    region         = "eu-central-1"
    role_arn       = "arn:aws:iam::566506590753:role/TerraformAdministrator"
  }
}
