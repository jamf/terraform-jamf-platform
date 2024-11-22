# Copyright 2024, Jamf
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

# resource "jsc_ap" "networkrelay" {
#   name    = "Network Relay"
#   idptype = "NetworkRelay"
# }

# resource "jsc_oktaidp" "okta_idp_base" {
#   clientid  = "0oa71hsl3q3umwKZz5d7"
#   name      = "Okta IDP Integration"
#   orgdomain = var.tje_okta_orgdomain
# }

resource "jsc_ap" "networkrelay" {
  name    = "Network Relay - Testing"
  idptype = "none"
  # oktaconnectionid = jsc_oktaidp.okta_idp_base.id
  # networkrelay     = true
}

resource "jamfpro_macos_configuration_profile_plist" "network_relay_macos" {
  name                = "Network Relay - macOS (Supervised)"
  distribution_method = "Install Automatically"
  redeploy_on_update  = "Newly Assigned"
  level               = "System"

  payloads         = jsc_ap.networkrelay.macosplist
  payload_validate = false

  scope {
    all_computers = false
  }
  # depends_on = [jsc_ap.networkrelay]
}

output "enable_jsc_uemc_output" {
  value = "yes"
}