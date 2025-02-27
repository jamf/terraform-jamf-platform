## Call Terraform provider
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = ">= 0.1.11"
    }
    jsc = {
      source  = "danjamf/jsctfprovider"
      version = ">= 0.0.15"
    }
  }
}

module "onboarder-security" {
  source                    = "../onboarder-security"
  support_files_path_prefix = var.support_files_path_prefix
}

module "onboarder-management-macOS" {
  source                    = "../onboarder-management-macOS"
  support_files_path_prefix = var.support_files_path_prefix
}

module "onboarder-management-mobile" {
  source                    = "../onboarder-management-mobile"
  support_files_path_prefix = var.support_files_path_prefix
}

module "onboarder-app-installers" {
  source                    = "../onboarder-app-installers"
  support_files_path_prefix = var.support_files_path_prefix
}

module "compliance-macOS-cis-level-1" {
  source                    = "../compliance-macOS-cis-level-1"
  support_files_path_prefix = var.support_files_path_prefix
}

module "compliance-iOS-cis-level-1" {
  source                    = "../compliance-iOS-cis-level-1"
  support_files_path_prefix = var.support_files_path_prefix
}
