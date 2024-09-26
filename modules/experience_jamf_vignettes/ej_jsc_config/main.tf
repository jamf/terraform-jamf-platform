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

resource "jamfpro_api_role" "jamfpro_api_role_sync" {
  display_name = "JSC API Role Device Sync"
  privileges   = ["Read Mac Applications", "Read Mobile Devices", "Read Mobile Device Applications", "Read Smart Mobile Device Groups", "Read Static Mobile Device Groups", "Read Computers", "Read Smart Computer Groups", "Read Static Computer Groups"]
}

resource "jamfpro_api_role" "jamfpro_api_role_signalling" {
  display_name = "JSC API Role Signalling"
  privileges   = ["Update Computer Extension Attributes", "Read Computer Extension Attributes", "Delete Computer Extension Attributes", "Create Computer Extension Attributes", "Read Mobile Device Extension Attributes", "Delete Mobile Device Extension Attributes", "Create Mobile Device Extension Attributes", "Update Mobile Devices", "Update Mobile Device Extension Attributes", "Update Computers", "Update User"]
}

resource "jamfpro_api_role" "jamfpro_api_role_deploy" {
  display_name = "JSC API Role Deploy"
  privileges   = ["Create iOS Configuration Profiles", "Create macOS Configuration Profiles"]
}

resource "jamfpro_api_integration" "jamfpro_api_integration_jsc" {
  display_name                  = "JSC API Client"
  enabled                       = true
  access_token_lifetime_seconds = 6000
  authorization_scopes          = [jamfpro_api_role.jamfpro_api_role_sync.display_name, jamfpro_api_role.jamfpro_api_role_signalling.display_name, jamfpro_api_role.jamfpro_api_role_deploy.display_name]
}

data "jamfpro_api_integration" "jamf_pro_api_integration_001_data" {
  id = jamfpro_api_integration.jamfpro_api_integration_jsc.id
}

locals {
  jamf_pro_client_id     = data.jamfpro_api_integration.jamf_pro_api_integration_001_data.client_id
  jamf_pro_client_secret = data.jamfpro_api_integration.jamf_pro_api_integration_001_data.client_secret
}

output "jp_client_id" {
  value = data.jamfpro_api_integration.jamf_pro_api_integration_001_data.client_id
}

output "jp_client_secret" {
  value = data.jamfpro_api_integration.jamf_pro_api_integration_001_data.client_secret
}

resource "jsc_uemc" "initial_uemc" {
  domain       = var.jamfpro_instance_url
  clientid     = local.jamf_pro_client_id
  clientsecret = local.jamf_pro_client_secret
  depends_on   = [jamfpro_api_integration.jamfpro_api_integration_jsc]
}

resource "jsc_oktaidp" "okta_idp_base" {
  clientid  = var.tje_okta_clientid
  name      = "Okta IDP Integration"
  orgdomain = var.tje_okta_orgdomain
}

resource "jsc_ap" "all_services" {
  name             = "Jamf Connect ZTNA and Protect"
  oktaconnectionid = jsc_oktaidp.okta_idp_base.id
  privateaccess    = true
  threatdefence    = true
  datapolicy       = true
}

output "profile" {
  value = trimspace(jsc_ap.all_services.macosplist)
}

resource "jsc_blockpage" "data_block" {
  title               = "Content Blocked"
  description         = "This site is blocked by an administrator-defined Internet content policy. You are able to customize this policy – and even this message – in your organization's Jamf Security Cloud console."
  logo                = var.block_page_logo
  type                = "block"
  show_requesturl     = true
  show_classification = true
}

resource "jsc_blockpage" "secure_block" {
  title               = "Security Risk"
  description         = "This site is blocked by an administrator-defined security policy. You are able to customize this policy – and even this message – in your organization's Jamf Security Cloud console."
  logo                = var.block_page_logo
  type                = "secureBlock"
  show_requesturl     = false
  show_classification = true
  depends_on          = [jsc_blockpage.data_block]
}

resource "jsc_blockpage" "cap" {
  title               = "Data Limit Reached"
  description         = "You have reached the data limit set by your organization. You'll still be allowed use work related applications on your cellular connection but all other use will need to be on Wi-Fi."
  logo                = var.block_page_logo
  type                = "cap"
  show_requesturl     = true
  show_classification = true
  depends_on          = [jsc_blockpage.secure_block]
}

resource "jsc_blockpage" "device_risk" {
  title               = "Access Blocked Due to Device Risk"
  description         = "You cannot access this site because the risk level of your device is too high. Please open the Jamf Trust app on your device to learn more."
  logo                = var.block_page_logo
  type                = "deviceRisk"
  show_requesturl     = true
  show_classification = true
  depends_on          = [jsc_blockpage.cap]
}

resource "jsc_blockpage" "mangement_block" {
  title               = "Un-Managed Device - Access Restricted"
  description         = "You cannot access this site because your device is not managed. If you are using an un-managed device, please switch to an organizationally managed device to access this resource."
  logo                = var.block_page_logo
  type                = "deviceManagement"
  show_requesturl     = true
  show_classification = true
  depends_on          = [jsc_blockpage.device_risk]
}

## Create categories
resource "jamfpro_category" "experience_jamf" {
  name     = "Experience Jamf"
  priority = 9
}

resource "jamfpro_smart_computer_group" "group_macOS_14" {
  name = "Macs Running macOS 14"
  criteria {
    name        = "Operating System Version"
    search_type = "like"
    value       = "14."
    and_or      = "and"
    priority    = 0
  }
}

locals {
  ej_jsc_config_profile = {
    "Experience Jamf Activation Profile" = "${var.support_files_path_prefix}modules/experience_jamf_vignettes/ej_jsc_config/support_files/jamftrust.plist"
  }
}

resource "jamfpro_macos_configuration_profile_plist" "ej_jsc_macos" {
  for_each            = local.ej_jsc_config_profile
  name                = "Experience Jamf Activation Profile - macOS"
  distribution_method = "Install Automatically"
  /*redeploy_on_update = "Newly Assigned"*/
  category_id = jamfpro_category.experience_jamf.id
  level       = "System"

  payloads         = jsc_ap.all_services.macosplist
  payload_validate = false

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_macOS_14.id]
  }

  depends_on = [jamfpro_smart_computer_group.group_macOS_14]
}
