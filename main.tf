## Root provider requirements
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

module "jamfprotectformaco_config" {
  count                       = var.include_jamfprotectformacos_config == true ? 1 : 0
  source                      = "./modules/jamf_protect_for_macOS/"
  jamfpro_instance_url        = var.jamfpro_instance_url
  jamfpro_client_id           = var.jamfpro_client_id
  jamfpro_client_secret       = var.jamfpro_client_secret
  jamfprotect_url             = var.jamfprotect_url
  jamfprotect_clientID        = var.jamfprotect_clientID
  jamfprotect_client_password = var.jamfprotect_client_password


}

## Initialize Onboarding Wizard modules
module "ow_browsers" {
  count                     = var.include_onboarder_wizard == true ? 1 : 0
  source                    = "./modules/onboarder_wizard/ow_browsers"
  support_files_path_prefix = "modules/onboarder_wizard//ow_browsers/"
  install_chrome            = var.install_chrome
  install_firefox           = var.install_firefox
}

module "ow_profiles" {
  count                           = var.include_onboarder_wizard == true ? 1 : 0
  source                          = "./modules/onboarder_wizard/ow_profiles"
  support_files_path_prefix       = "modules/onboarder_wizard//ow_profiles/"
  block_beta_updates              = var.block_beta_updates
  enforce_firewall_and_gatekeeper = var.enforce_firewall_and_gatekeeper
}

## Initialize Experience Jamf vignette modules
module "ej_base" {
  count  = var.include_ej_base == true ? 1 : 0
  source = "./modules/experience_jamf_vignettes/ej_base"
}

/*
module "ej_saas_tenancy" {
  count                     = var.include_ej_saas_tenancy == true ? 1 : 0
  source                    = "./modules/experience_jamf_vignettes/ej_saas_tenancy"
  support_files_path_prefix = "modules/experience_jamf_vignettes/ej_saas_tenancy/"
  KeyName                   = var.KeyName
  jsc_password              = var.jsc_password
  jsc_username              = var.jsc_username
  VPCId                     = var.VPCId
  SubnetId                  = var.SubnetId
  CertificatePrivateKey     = var.CertificatePrivateKey
  CertificateBody           = var.CertificateBody
  aws_region                = var.aws_region
}
*/

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

module "ej_mac_LMAM" {
  count                     = var.include_ej_mac_LMAM == true ? 1 : 0
  source                    = "./modules/experience_jamf_vignettes/ej_mac_LMAM"
  support_files_path_prefix = "modules/experience_jamf_vignettes/ej_mac_LMAM/"
}

module "ej_mobile_cis_benchmark" {
  count  = var.include_ej_mobile_cis_benchmark == true ? 1 : 0
  source = "./modules/experience_jamf_vignettes/ej_mobile_cis_benchmark"
}

module "ej_secure_remote_access" {
  count  = var.include_ej_secure_remote_access == true ? 1 : 0
  source = "./modules/experience_jamf_vignettes/ej_secure_remote_access"
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
  jsc_provided_idp_client_child = var.jsc_provided_idp_client
}

## Create Jamf Security Cloud Activation Profile containing ONLY Threat Response (MTD) 
module "jsc_mtd_only" {
  count                         = var.include_jsc_mtd_only == true ? 1 : 0
  source                        = "./modules/staging_templates/jsc_mtd_only"
  jsc_provided_idp_client_child = var.jsc_provided_idp_client
}

## Create Jamf Security Cloud Activation Profile containing ONLY Connect ZTNA
module "jsc_ztna" {
  count                         = var.include_jsc_ztna == true ? 1 : 0
  source                        = "./modules/staging_templates/jsc_ztna"
  jsc_provided_idp_client_child = var.jsc_provided_idp_client
}

## Create Jamf Security Cloud Activation Profile containing ALL JSC Services
module "jsc_all_services" {
  count                         = var.include_jsc_all_services == true ? 1 : 0
  source                        = "./modules/staging_templates/jsc_all_services"
  jsc_provided_idp_client_child = var.jsc_provided_idp_client
}

## Initialize sandbox module
module "sandbox" {
  count  = var.include_sandbox == true ? 1 : 0
  source = "./modules/sandbox"
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

