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

module "configuration-jamf-security-cloud-jamf-pro" {
  source = "../configuration-jamf-security-cloud-jamf-pro"
}

module "configuration-jamf-security-cloud-all-services" {
  source                    = "../configuration-jamf-security-cloud-all-services"
  support_files_path_prefix = var.support_files_path_prefix
}

module "configuration-jamf-pro-jamf-protect" {
  source                    = "../configuration-jamf-pro-jamf-protect"
  support_files_path_prefix = var.support_files_path_prefix
}

module "configuration-jamf-security-cloud-block-pages" {
  source = "../configuration-jamf-security-cloud-block-pages"
}

module "endpoint-security-macOS-filevault" {
  source                    = "../endpoint-security-macOS-filevault"
  support_files_path_prefix = var.support_files_path_prefix
}
