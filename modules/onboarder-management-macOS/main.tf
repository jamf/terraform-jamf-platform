## Call Terraform provider
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = ">= 0.1.11"
    }
  }
}

module "configuration-jamf-pro-smart-groups" {
  source = "../configuration-jamf-pro-smart-groups"
}

module "configuration-jamf-pro-categories" {
  source = "../configuration-jamf-pro-categories"
}

module "configuration-jamf-pro-computer-management-settings" {
  source = "../configuration-jamf-pro-computer-management-settings"
}

module "management-macOS-rosetta" {
  source = "../management-macOS-rosetta"
}
