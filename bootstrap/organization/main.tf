###############################################################################
# Default provider for the purpose of compatibility with the the aws provider 
# spec.  
# Choose your auth method. In case you have an OrganizationAccountAccessRole
# use assume_role, otherwise fallback to the profile
###############################################################################
provider "aws" {
  #alias = "root"

/*   assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.deployment.id}:role/OrganizationAccountAccessRole"
  } */
  profile = "root"
  region = "eu-central-1"
  #var.management_aws_region
}

###############################################################################
# Default backend type local.   
###############################################################################
#terraform {
#  backend "s3" {}
#}

#terraform {
#  backend "local" {}
#}
###############################################################################
# Gets the data object that represents the currently running identity context
###############################################################################
data "aws_caller_identity" "current" {}

###############################################################################
# Create a new organisation if use_existing_organization is false
###############################################################################
resource "aws_organizations_organization" "org" {
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
  feature_set          = "ALL"

  aws_service_access_principals = [
    "controltower.amazonaws.com",
    "member.org.stacksets.cloudformation.amazonaws.com",
    "sso.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
  ]

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Create OU for Security aspects
###############################################################################
resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.org.roots[0].id
}

###############################################################################
# Create OU for Infrastructure aspects
###############################################################################
resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infra"
  parent_id = aws_organizations_organization.org.roots[0].id
}

###############################################################################
# Create OU for Sandbox aspects
###############################################################################
resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = aws_organizations_organization.org.roots[0].id
}

###############################################################################
# Create OU for Deployment aspects
###############################################################################
/* resource "aws_organizations_organizational_unit" "deployment" {
  name      = "Deployment"
  parent_id = aws_organizations_organization.org.roots[0].id
} */

###############################################################################
# Create OU for Workload aspects
###############################################################################
/* resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.org.roots[0].id
}
 */
###############################################################################
# Create OU for Production Workload aspects
###############################################################################
resource "aws_organizations_organizational_unit" "workloads_prod" {
  name      = "Prod"
  #parent_id = aws_organizations_organizational_unit.workloads.id
  parent_id = aws_organizations_organization.org.roots[0].id
}

###############################################################################
# Create OU for Test Workload aspects
###############################################################################
/* resource "aws_organizations_organizational_unit" "workloads_test" {
  name      = "Test"
  parent_id = aws_organizations_organizational_unit.workloads.id
} */

###############################################################################
# Create a Security account
# -------------------------
# The security account hosts the tools used by the Security team.
###############################################################################
resource "aws_organizations_account" "security" {
  name  = "security" #"Core Security Account"
  email = var.security_account_email

  parent_id = aws_organizations_organizational_unit.security.id

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Create a Development account
# ----------------------------
# The development account is a development sandbox.
###############################################################################
resource "aws_organizations_account" "development" {
  name  = "mockup-dev" #"Core Development Account"
  email = var.development_account_email

  parent_id = aws_organizations_organizational_unit.sandbox.id

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Create a Shared Services account
# --------------------------------
# The shared services account is responsible for identity management
###############################################################################
/* resource "aws_organizations_account" "shared_services" {
  name  = "Core Shared Services Account"
  email = var.shared_services_account_email

  parent_id = aws_organizations_organizational_unit.infrastructure.id

  lifecycle {
    prevent_destroy = true
  }
}
 */
###############################################################################
# Create a Deployment account
# --------------------------------
# The deployment account holds the code repositorties and CI/CD pipelines.
###############################################################################
resource "aws_organizations_account" "deployment" {
  name  = "infra" #"Core Deployment Account"
  email = var.deployment_account_email

  parent_id = aws_organizations_organizational_unit.infrastructure.id

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Create a Logging account
# --------------------------------
# The logging account collects logs from all member accounts.
###############################################################################
resource "aws_organizations_account" "logging" {
  name  = "Log Archive" #"Core Logging Account"
  email = var.logging_account_email

  parent_id = aws_organizations_organizational_unit.security.id

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Create a Terraform deployment role based on the default AWS Administrator
# policy and allow it to be assumed by the Deployment account
###############################################################################
module "deployment_assume_management_terraform_deployment_role" {
  source = "../../modules/cross-account-role"

  assume_role_policy_json = data.aws_iam_policy_document.crossaccount_assume_from_deployment_account.json
  role_name               = var.terraform_deployment_role_name
  role_policy_arn         = var.administrator_default_arn

  tags = module.this.tags
}
