/*
This terraform blueprint will build the Experience Jamf base config.
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
resource "jamfpro_category" "category_end_tje" {
  name     = "End Jamf Experience"
  priority = 9
}

resource "jamfpro_category" "category_experience_jamf" {
  name     = "Experience Jamf"
  priority = 1
}