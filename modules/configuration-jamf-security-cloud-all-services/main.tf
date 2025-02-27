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

resource "random_integer" "entropy" {
  min = 10
  max = 999
}

resource "jsc_oktaidp" "okta_idp_base" {
  clientid  = var.tje_okta_clientid
  name      = "Okta IDP Integration"
  orgdomain = var.tje_okta_orgdomain
}

resource "jsc_ap" "all_services" {
  name             = "Jamf Connect ZTNA and Protect [${random_integer.entropy.result}]"
  idptype          = "OKTA"
  oktaconnectionid = jsc_oktaidp.okta_idp_base.id
  privateaccess    = true
  threatdefence    = true
  datapolicy       = true
}

resource "jamfpro_category" "jsc_all_services_profiles" {
  name     = "Jamf Security Cloud - Activation Profiles [${random_integer.entropy.result}]"
  priority = 9
}

resource "jamfpro_macos_configuration_profile_plist" "all_services_macos" {
  name                = "Jamf Connect ZTNA + Jamf Protect Threat and Content Control - macOS (Supervised) [${random_integer.entropy.result}]"
  distribution_method = "Install Automatically"
  redeploy_on_update  = "Newly Assigned"
  level               = "System"
  category_id         = jamfpro_category.jsc_all_services_profiles.id

  payloads         = jsc_ap.all_services.macosplist
  payload_validate = false

  scope {
    all_computers = false
  }
}

output "supervisedplist_output" {
  value = jsc_ap.all_services.supervisedplist
}

output "jsc_ap_category" {
  value = jamfpro_category.jsc_all_services_profiles.id
}

# module "jsc_mobile" {
#   source             = "../configuration-jamf-security-cloud-all-services_mobile"
#   category_id_output = jamfpro_category.jsc_all_services_profiles.id
#   jsc_mobile_plist   = module.jsc_all_services.supervisedplist_output
# }

# resource "jamfpro_mobile_device_configuration_profile_plist" "all_services_mobile" {
#   name               = "Jamf Connect ZTNA + Jamf Protect Threat and Content Control - mobile (Supervised) [${random_integer.entropy.result}]"
#   deployment_method  = "Install Automatically"
#   level              = "Device Level"
#   redeploy_on_update = "Newly Assigned"
#   category_id        = var.category_id_output

#   payloads         = module.jsc_all_services.supervisedplist_output
#   payload_validate = false

#   scope {
#     all_mobile_devices = false
#     all_jss_users      = false
#   }

#   lifecycle {
#     ignore_changes = [payloads]
#   }
# }
