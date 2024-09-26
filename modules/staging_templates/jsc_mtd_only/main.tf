## Call Terraform provider
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = ">= 0.1.5"
    }
    jsc = {
      source  = "danjamf/jsctfprovider"
      version = ">= 0.0.15"
    }
  }
}

resource "jsc_ap" "mtd_only" {
  name             = "Mobile Threat Defense"
  oktaconnectionid = var.jsc_provided_idp_client_child
  privateaccess    = false
  threatdefence    = true
  datapolicy       = false
}
