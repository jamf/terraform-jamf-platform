# Copyright 2024, Jamf
/*
This terraform module will install any required prerequisites for Experience Jamf vignettes.
In main.tf will do the following:
 - Upload 1 category
*/

## Call Terraform provider
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = ">= 0.1.5"
    }
  }
}

## Create categories
resource "jamfpro_category" "category_prerequisites" {
  name     = "Prerequisites"
  priority = 9
}
