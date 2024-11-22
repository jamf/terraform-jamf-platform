# Copyright 2024, Jamf
/*
This terraform blueprint will build the Mobile CIS Benchmark vignette from Experience Jamf.
It will do the following:
 - 
 -
 -
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
resource "jamfpro_category" "category_cis1_mobile" {
  name     = "iOS17_cis_lvl1_enterprise"
  priority = 9
}

resource "jamfpro_category" "category_cis2_mobile" {
  name     = "iOS17_cis_lvl2_enterprise"
  priority = 9
}

