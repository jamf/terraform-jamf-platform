## Root provider requirements
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = ">= 0.2.0"
    }
    jsc = {
      source  = "danjamf/jsctfprovider"
      version = ">= 0.0.15"
    }
  }
}

## Jamf Pro provider root configuration
provider "jamfpro" {
  jamfpro_instance_fqdn                = var.jamfpro_instance_url
  auth_method                          = var.jamfpro_auth_method
  basic_auth_username                  = var.jamfpro_username
  basic_auth_password                  = var.jamfpro_password
  client_id                            = var.jamfpro_client_id
  client_secret                        = var.jamfpro_client_secret
  enable_client_sdk_logs               = false
  hide_sensitive_data                  = true # Hides sensititve data in logs
  token_refresh_buffer_period_seconds  = 5    # minutes
  jamfpro_load_balancer_lock           = true
  mandatory_request_delay_milliseconds = 100
}

## JSC provider root configuration
provider "jsc" {
  username = var.jsc_username
  password = var.jsc_password
}


## Initialize common modules
module "jamfpro_prerequisites" {
  count  = var.include_jamfpro_prerequisites == true ? 1 : 0
  source = "./modules/jamfpro_prerequisites/"
}

module "jamfpro_demo_config" {
  count  = var.include_jamfpro_demo_config == true ? 1 : 0
  source = "./modules/jamfpro_demo_config/"
}

## Initialize Protect (for macOS) module

module "jamf_protect_for_macOS" {
  count                       = var.include_jamf_protect_for_macOS == true ? 1 : 0
  source                      = "./modules/jamf_protect_for_macOS/"
  jamfpro_instance_url        = var.jamfpro_instance_url
  jamfpro_client_id           = var.jamfpro_client_id
  jamfpro_client_secret       = var.jamfpro_client_secret
  jamfprotect_url             = var.jamfprotect_url
  jamfprotect_clientID        = var.jamfprotect_clientID
  jamfprotect_client_password = var.jamfprotect_client_password
}

module "google_chrome" {
  count  = var.include_google_chrome == true ? 1 : 0
  source = "./modules/app_installers/google_chrome/"
}

module "mozilla_firefox" {
  count  = var.include_mozilla_firefox == true ? 1 : 0
  source = "./modules/app_installers/mozilla_firefox/"
}

module "microsoft_teams" {
  count  = var.include_microsoft_teams == true ? 1 : 0
  source = "./modules/app_installers/microsoft_teams"
}

module "slack" {
  count  = var.include_slack == true ? 1 : 0
  source = "./modules/app_installers/slack"
}

module "swift_dialog" {
  count  = var.include_swift_dialog == true ? 1 : 0
  source = "./modules/app_installers/swift_dialog"
}

module "okta_verify" {
  count  = var.include_swift_dialog == true ? 1 : 0
  source = "./modules/app_installers/okta_verify"
}

module "dropbox" {
  count  = var.include_dropbox == true ? 1 : 0
  source = "./modules/app_installers/dropbox"
}

module "google_drive" {
  count  = var.include_google_drive == true ? 1 : 0
  source = "./modules/app_installers/google_drive"
}

module "jamf_composer" {
  count  = var.include_jamf_composer == true ? 1 : 0
  source = "./modules/app_installers/jamf_composer"
}

module "jamf_connect" {
  count  = var.include_jamf_connect == true ? 1 : 0
  source = "./modules/app_installers/dropbox"
}

module "pppc_utility" {
  count  = var.include_pppc_utility == true ? 1 : 0
  source = "./modules/app_installers/pppc_utility"
}

module "jamfcheck" {
  count  = var.include_jamfcheck == true ? 1 : 0
  source = "./modules/app_installers/jamfcheck"
}

module "nudge" {
  count  = var.include_nudge == true ? 1 : 0
  source = "./modules/app_installers/nudge"
}

module "utm" {
  count  = var.include_utm == true ? 1 : 0
  source = "./modules/app_installers/utm"
}

module "zoom" {
  count  = var.include_zoom == true ? 1 : 0
  source = "./modules/app_installers/zoom"
}

## Initialize Experience Jamf vignette modules
module "ej_base" {
  count  = var.include_ej_base == true ? 1 : 0
  source = "./modules/experience_jamf_vignettes/ej_base"
}

# SaaS tenancy moved to saastenconfig.tf.bak

module "ej_incident_response" {
  count                     = var.include_ej_incident_response == true ? 1 : 0
  source                    = "./modules/experience_jamf_vignettes/ej_incident_response"
  support_files_path_prefix = "modules/experience_jamf_vignettes/ej_incident_response/"
}

module "ej_mac_cis_benchmark" {
  count                     = var.include_ej_mac_cis_benchmark == true ? 1 : 0
  source                    = "./modules/experience_jamf_vignettes/ej_mac_cis_benchmark"
  support_files_path_prefix = "modules/experience_jamf_vignettes/ej_mac_cis_benchmark/"
}

module "ej_mobile_cis_benchmark" {
  count  = var.include_ej_mobile_cis_benchmark == true ? 1 : 0
  source = "./modules/experience_jamf_vignettes/ej_mobile_cis_benchmark"
}

module "ej_secure_remote_access" {
  count  = var.include_ej_secure_remote_access == true ? 1 : 0
  source = "./modules/experience_jamf_vignettes/ej_secure_remote_access"
}

module "ej_mac_LMAM" {
  count                     = var.include_ej_mac_LMAM == true ? 1 : 0
  source                    = "./modules/experience_jamf_vignettes/ej_mac_LMAM"
  support_files_path_prefix = "modules/experience_jamf_vignettes/ej_mac_LMAM/"
}



## Begin Jamf Security Cloud Configuration

## Create UEMC and Okta integrations
module "jsc_base" {
  count                = var.include_jsc_base == true ? 1 : 0
  source               = "./modules/staging_templates/jsc_base"
  tje_okta_clientid    = var.tje_okta_clientid
  tje_okta_orgdomain   = var.tje_okta_orgdomain
  jamfpro_instance_url = var.jamfpro_instance_url
  clientid             = var.jamfpro_client_id
  clientsecret         = var.jamfpro_client_secret
}

module "jsc_block_pages" {
  count           = var.include_jsc_block_pages == true ? 1 : 0
  source          = "./modules/staging_templates/jsc_block_pages"
  block_page_logo = var.block_page_logo
}

## Create Jamf Security Cloud Activation Profile containing ONLY Category Based Content Filtering
module "jsc_dp_only" {
  count                         = var.include_jsc_dp_only == true ? 1 : 0
  source                        = "./modules/staging_templates/jsc_dp_only"
  tje_okta_clientid             = var.tje_okta_clientid
  tje_okta_orgdomain            = var.tje_okta_orgdomain
  jsc_provided_idp_client_child = var.jsc_provided_idp_client
}

## Create Jamf Security Cloud Activation Profile containing ONLY Threat Response (MTD) 
module "jsc_mtd_only" {
  count                         = var.include_jsc_mtd_only == true ? 1 : 0
  source                        = "./modules/staging_templates/jsc_mtd_only"
  tje_okta_clientid             = var.tje_okta_clientid
  tje_okta_orgdomain            = var.tje_okta_orgdomain
  jsc_provided_idp_client_child = var.jsc_provided_idp_client
}

## Create Jamf Security Cloud Activation Profile containing ONLY Threat Response (MTD) 
module "jsc_mtd_dp_only" {
  count                         = var.include_jsc_mtd_dp_only == true ? 1 : 0
  source                        = "./modules/staging_templates/jsc_mtd_dp_only"
  tje_okta_clientid             = var.tje_okta_clientid
  tje_okta_orgdomain            = var.tje_okta_orgdomain
  jsc_provided_idp_client_child = var.jsc_provided_idp_client
}

## Create Jamf Security Cloud Activation Profile containing ONLY Connect ZTNA
module "jsc_ztna" {
  count                         = var.include_jsc_ztna == true ? 1 : 0
  source                        = "./modules/staging_templates/jsc_ztna"
  tje_okta_clientid             = var.tje_okta_clientid
  tje_okta_orgdomain            = var.tje_okta_orgdomain
  jsc_provided_idp_client_child = var.jsc_provided_idp_client
}

## Create Jamf Security Cloud Activation Profile containing ONLY Connect ZTNA
module "jsc_ztna_dp_only" {
  count                         = var.include_jsc_ztna_dp_only == true ? 1 : 0
  source                        = "./modules/staging_templates/jsc_ztna_dp_only"
  tje_okta_clientid             = var.tje_okta_clientid
  tje_okta_orgdomain            = var.tje_okta_orgdomain
  jsc_provided_idp_client_child = var.jsc_provided_idp_client
}

## Create Jamf Security Cloud Activation Profile containing ONLY Connect ZTNA
module "jsc_ztna_mtd_only" {
  count                         = var.include_jsc_ztna_mtd_only == true ? 1 : 0
  source                        = "./modules/staging_templates/jsc_ztna_mtd_only"
  tje_okta_clientid             = var.tje_okta_clientid
  tje_okta_orgdomain            = var.tje_okta_orgdomain
  jsc_provided_idp_client_child = var.jsc_provided_idp_client
}

## Create Jamf Security Cloud Activation Profile containing ONLY Connect Network Relay
module "jsc_network_relay" {
  count  = var.include_jsc_network_relay == true ? 1 : 0
  source = "./modules/staging_templates/jsc_network_relay"
}

## Create Jamf Security Cloud Activation Profile containing ALL JSC Services
module "jsc_all_services" {
  count                         = var.include_jsc_all_services == true ? 1 : 0
  source                        = "./modules/staging_templates/jsc_all_services"
  tje_okta_clientid             = var.tje_okta_clientid
  tje_okta_orgdomain            = var.tje_okta_orgdomain
  jsc_provided_idp_client_child = var.jsc_provided_idp_client
}


## Initialiaze JSC child modules
module "ej_jsc_config" {
  count                     = var.include_ej_jsc_config == true ? 1 : 0
  source                    = "./modules/experience_jamf_vignettes/ej_jsc_config"
  jamfpro_instance_url      = var.jamfpro_instance_url
  tje_okta_clientid         = var.tje_okta_clientid
  tje_okta_orgdomain        = var.tje_okta_orgdomain
  block_page_logo           = var.block_page_logo
  support_files_path_prefix = var.support_files_path_prefix
  /* wizard_suffix         = var.wizard_suffix */
}

module "trial_baseline" {
  count                     = var.include_trial_baseline == true ? 1 : 0
  source                    = "./modules/trial_baseline"
  support_files_path_prefix = "modules/trial_baseline/"
}

module "jc_basic" {
  count                     = var.include_jc_basic == true ? 1 : 0
  source                    = "./modules/jc_basic"
  support_files_path_prefix = "modules/jc_basic/"
}