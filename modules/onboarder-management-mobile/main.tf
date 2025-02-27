## Call Terraform provider
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = ">= 0.1.11"
    }
  }
}

module "management-iOS-configuration-profiles" {
  source                    = "../management-iOS-configuration-profiles"
  support_files_path_prefix = var.support_files_path_prefix
}
