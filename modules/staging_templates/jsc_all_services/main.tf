## Call Terraform provider
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = "~> 0.1.5"
    }
    jsc = {
      source  = "danjamf/jsctfprovider"
      version = ">= 0.0.15"
    }
  }
}

resource "jsc_ap" "all_services" {
  name             = "Jamf Connect ZTNA and Protect"
  oktaconnectionid = var.jsc_provided_idp_client_child
  privateaccess    = true
  threatdefence    = true
  datapolicy       = true
}
