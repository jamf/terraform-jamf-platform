## Root provider requirements
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = ">= 0.2.0"
    }
    jsc = {
      source  = "danjamf/jsctfprovider"
      version = ">= 0.0.23"
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
  enable_client_sdk_logs               = var.enable_client_sdk_logs
  hide_sensitive_data                  = true # Hides sensititve data in logs
  token_refresh_buffer_period_seconds  = 5    # minutes
  jamfpro_load_balancer_lock           = true
  mandatory_request_delay_milliseconds = 100
}

# JSC provider root configuration
provider "jsc" {
  username          = var.jsc_username
  password          = var.jsc_password
  applicationid     = var.jsc_applicationid
  applicationsecret = var.jsc_applicationsecret
}

## Initialize common modules

## Initialize Protect (for macOS) module

module "jamf_protect_trial_kickstart" {
  count                       = var.include_jamf_protect_trial_kickstart == true ? 1 : 0
  source                      = "./modules/configuration_jamf_pro_jamf_protect"
  jamfpro_instance_url        = var.jamfpro_instance_url
  jamfpro_client_id           = var.jamfpro_client_id
  jamfpro_client_secret       = var.jamfpro_client_secret
  jamfprotect_url             = var.jamfprotect_url
  jamfprotect_clientID        = var.jamfprotect_clientID
  jamfprotect_client_password = var.jamfprotect_client_password
}

module "mac_cis_lvl1_benchmark" {
  count                     = var.include_mac_cis_lvl1_benchmark == true ? 1 : 0
  source                    = "./modules/compliance_macOS_cis_level_1"
  support_files_path_prefix = var.support_files_path_prefix
}

module "mobile_cis_lvl1_benchmark" {
  count                     = var.include_mobile_cis_lvl1_benchmark == true ? 1 : 0
  source                    = "./modules/compliance_iOS_cis_level_1"
  support_files_path_prefix = var.support_files_path_prefix
}

module "mac_stig_benchmark" {
  count                     = var.include_mac_stig_benchmark == true ? 1 : 0
  source                    = "./modules/compliance_macOS_disa_stig"
  support_files_path_prefix = var.support_files_path_prefix
}

module "mobile_stig_benchmark" {
  count                     = var.include_mobile_stig_benchmark == true ? 1 : 0
  source                    = "./modules/compliance_iOS_disa_stig"
  support_files_path_prefix = var.support_files_path_prefix
}

module "mac_800_171_benchmark" {
  count                     = var.include_mac_800_171_benchmark == true ? 1 : 0
  source                    = "./modules/compliance_macOS_nist_800-171"
  support_files_path_prefix = var.support_files_path_prefix
}

module "mac_cmmc_lvl1_benchmark" {
  count                     = var.include_mac_cmmc_lvl1_benchmark == true ? 1 : 0
  source                    = "./modules/compliance_macOS_cmmc_level_1"
  support_files_path_prefix = var.support_files_path_prefix
}

module "qol_smart_groups" {
  count  = var.include_qol_smart_groups == true ? 1 : 0
  source = "./modules/configuration_jamf_pro_smart_groups"
}

module "microsoft_365" {
  count  = var.include_microsoft_365 == true ? 1 : 0
  source = "./modules/management_app_installers_microsoft_365"
}

module "categories" {
  count  = var.include_categories == true ? 1 : 0
  source = "./modules/configuration_jamf_pro_categories"
}

module "mobile_device_kickstart" {
  count  = var.include_mobile_device_kickstart == true ? 1 : 0
  source = "./modules/management_iOS_configuration_profiles"
}

module "computer_management_settings" {
  count  = var.include_computer_management_settings == true ? 1 : 0
  source = "./modules/configuration_jamf_pro_computer_management_settings"
}

module "filevault" {
  count  = var.include_filevault == true ? 1 : 0
  source = "./modules/endpoint_security_macOS_filevault"
}

module "msft_defender" {
  count  = var.include_defender == true ? 1 : 0
  source = "./modules/endpoint_security_macOS_microsoft_defender"
}

module "passwordless_sso" {
  count                     = var.include_passwordless_ssoe == true ? 1 : 0
  source                    = "./modules/management_macOS_passwordless_sso"
  support_files_path_prefix = var.support_files_path_prefix
}

module "crowdstrike" {
  count  = var.include_crowdstrike == true ? 1 : 0
  source = "./modules/endpoint_security_macOS_crowdstrike"
}


module "rosetta" {
  count  = var.include_rosetta == true ? 1 : 0
  source = "./modules/management_macOS_rosetta"
}

module "google_chrome" {
  count  = var.include_google_chrome == true ? 1 : 0
  source = "./modules/management_app_installers_google_chrome"
}

module "mozilla_firefox" {
  count  = var.include_mozilla_firefox == true ? 1 : 0
  source = "./modules/management_app_installers_mozilla_firefox"
}

module "slack" {
  count  = var.include_slack == true ? 1 : 0
  source = "./modules/management_app_installers_slack"
}

module "dropbox" {
  count  = var.include_dropbox == true ? 1 : 0
  source = "./modules/management_app_installers_dropbox"
}

module "google_drive" {
  count  = var.include_google_drive == true ? 1 : 0
  source = "./modules/management_app_installers_google_drive"
}

module "jamf_composer" {
  count  = var.include_jamf_composer == true ? 1 : 0
  source = "./modules/management_app_installers_jamf_composer"
}

module "pppc_utility" {
  count  = var.include_pppc_utility == true ? 1 : 0
  source = "./modules/management_app_installers_pppc_utility"
}

module "jamfcheck" {
  count  = var.include_jamfcheck == true ? 1 : 0
  source = "./modules/management_app_installers_jamfcheck"
}

module "zoom" {
  count  = var.include_zoom == true ? 1 : 0
  source = "./modules/management_app_installers_zoom"
}

## Begin Jamf Security Cloud Configuration

## Create UEMC and Okta integrations
module "jsc_uemc" {
  count                = var.include_jsc_uemc == true ? 1 : 0
  source               = "./modules/configuration_jamf_security_cloud_jamf_pro"
  tje_okta_clientid    = var.tje_okta_clientid
  tje_okta_orgdomain   = var.tje_okta_orgdomain
  jamfpro_instance_url = var.jamfpro_instance_url
  clientid             = var.jamfpro_client_id
  clientsecret         = var.jamfpro_client_secret
}

## Create Jamf Security Cloud Activation Profile containing ALL JSC Services
module "jsc_all_services" {
  count              = var.include_jsc_all_services == true ? 1 : 0
  source             = "./modules/configuration_jamf_security_cloud_all_services"
  tje_okta_clientid  = var.tje_okta_clientid
  tje_okta_orgdomain = var.tje_okta_orgdomain
}

module "jsc_ap_adobe" {
  count  = var.include_jsc_ap_adobe == true ? 1 : 0
  source = "./modules/network_security_access_policy_adobe"
}

module "jsc_ap_atlassian" {
  count  = var.include_jsc_ap_atlassian == true ? 1 : 0
  source = "./modules/network_security_access_policy_atlassian"
}

module "jsc_ap_bluejeans" {
  count  = var.include_jsc_ap_bluejeans == true ? 1 : 0
  source = "./modules/network_security_access_policy_bluejeans"
}

module "jsc_ap_box" {
  count  = var.include_jsc_ap_box == true ? 1 : 0
  source = "./modules/network_security_access_policy_box"
}

module "jsc_ap_docusign" {
  count  = var.include_jsc_ap_docusign == true ? 1 : 0
  source = "./modules/network_security_access_policy_docusign"
}

module "jsc_ap_dropbox" {
  count  = var.include_jsc_ap_dropbox == true ? 1 : 0
  source = "./modules/network_security_access_policy_dropbox"
}

module "jsc_ap_github" {
  count  = var.include_jsc_ap_github == true ? 1 : 0
  source = "./modules/network_security_access_policy_github"
}

module "jsc_ap_google" {
  count  = var.include_jsc_ap_google == true ? 1 : 0
  source = "./modules/network_security_access_policy_google"
}

module "jsc_ap_hubspot" {
  count  = var.include_jsc_ap_hubspot == true ? 1 : 0
  source = "./modules/network_security_access_policy_hubspot"
}

module "jsc_ap_mailchimp" {
  count  = var.include_jsc_ap_mailchimp == true ? 1 : 0
  source = "./modules/network_security_access_policy_mailchimp"
}

module "jsc_ap_mathworks" {
  count  = var.include_jsc_ap_mathworks == true ? 1 : 0
  source = "./modules/network_security_access_policy_mathworks"
}

module "jsc_ap_microsoft" {
  count  = var.include_jsc_ap_microsoft == true ? 1 : 0
  source = "./modules/network_security_access_policy_microsoft"
}

module "jsc_ap_my_ip" {
  count  = var.include_jsc_ap_my_ip == true ? 1 : 0
  source = "./modules/network_security_access_policy_my_ip"
}

module "jsc_ap_okta" {
  count  = var.include_jsc_ap_okta == true ? 1 : 0
  source = "./modules/network_security_access_policy_okta"
}

module "jsc_ap_salesforce" {
  count  = var.include_jsc_ap_salesforce == true ? 1 : 0
  source = "./modules/network_security_access_policy_salesforce"
}

module "jsc_ap_servicenow" {
  count  = var.include_jsc_ap_servicenow == true ? 1 : 0
  source = "./modules/network_security_access_policy_servicenow"
}

module "jsc_ap_slack" {
  count  = var.include_jsc_ap_slack == true ? 1 : 0
  source = "./modules/network_security_access_policy_slack"
}

module "jsc_ap_snowflake" {
  count  = var.include_jsc_ap_snowflake == true ? 1 : 0
  source = "./modules/network_security_access_policy_snowflake"
}

module "jsc_ap_splunk" {
  count  = var.include_jsc_ap_splunk == true ? 1 : 0
  source = "./modules/network_security_access_policy_splunk"
}

module "jsc_ap_square" {
  count  = var.include_jsc_ap_square == true ? 1 : 0
  source = "./modules/network_security_access_policy_square"
}

module "jsc_ap_twilio" {
  count  = var.include_jsc_ap_twilio == true ? 1 : 0
  source = "./modules/network_security_access_policy_twilio"
}

module "jsc_ap_webex" {
  count  = var.include_jsc_ap_webex == true ? 1 : 0
  source = "./modules/network_security_access_policy_webex"
}

module "jsc_ap_workday" {
  count  = var.include_jsc_ap_workday == true ? 1 : 0
  source = "./modules/network_security_access_policy_workday"
}

module "jsc_ap_zendesk" {
  count  = var.include_jsc_ap_zendesk == true ? 1 : 0
  source = "./modules/network_security_access_policy_zendesk"
}

module "jsc_ap_zoom" {
  count  = var.include_jsc_ap_zoom == true ? 1 : 0
  source = "./modules/network_security_access_policy_zoom"
}

module "jsc_block_pages" {
  count           = var.include_jsc_block_pages == true ? 1 : 0
  source          = "./modules/configuration_jamf_security_cloud_block_pages"
  block_page_logo = var.block_page_logo
}

## Create Jamf Security Cloud Activation Profile containing ONLY Category Based Content Filtering
module "jsc_dp_only" {
  count              = var.include_jsc_dp_only == true ? 1 : 0
  source             = "./modules/network_security_jamf_pro_content_filtering"
  tje_okta_clientid  = var.tje_okta_clientid
  tje_okta_orgdomain = var.tje_okta_orgdomain
}

## Create Jamf Security Cloud Activation Profile containing ONLY Threat Response (MTD) 
module "jsc_mtd_only" {
  count              = var.include_jsc_mtd_only == true ? 1 : 0
  source             = "./modules/network_security_jamf_pro_network_threat_defense"
  tje_okta_clientid  = var.tje_okta_clientid
  tje_okta_orgdomain = var.tje_okta_orgdomain
}

## Create Jamf Security Cloud Activation Profile containing ONLY Threat Response (MTD) 
module "jsc_mtd_dp_only" {
  count              = var.include_jsc_mtd_dp_only == true ? 1 : 0
  source             = "./modules/network_security_jamf_pro_content_filtering_and_network_threat_defense"
  tje_okta_clientid  = var.tje_okta_clientid
  tje_okta_orgdomain = var.tje_okta_orgdomain
}

## Create Jamf Security Cloud Activation Profile containing ONLY Connect ZTNA
module "jsc_ztna" {
  count              = var.include_jsc_ztna == true ? 1 : 0
  source             = "./modules/network_security_jamf_pro_zero_trust_network_access"
  tje_okta_clientid  = var.tje_okta_clientid
  tje_okta_orgdomain = var.tje_okta_orgdomain
}

## Create Jamf Security Cloud Activation Profile containing ONLY Connect ZTNA
module "jsc_ztna_dp_only" {
  count              = var.include_jsc_ztna_dp_only == true ? 1 : 0
  source             = "./modules/network_security_jamf_pro_zero_trust_network_access_and_content_filtering"
  tje_okta_clientid  = var.tje_okta_clientid
  tje_okta_orgdomain = var.tje_okta_orgdomain
}

## Create Jamf Security Cloud Activation Profile containing ONLY Connect ZTNA
module "jsc_ztna_mtd_only" {
  count              = var.include_jsc_ztna_mtd_only == true ? 1 : 0
  source             = "./modules/network_security_jamf_pro_zero_trust_network_access_and_network_threat_prevention"
  tje_okta_clientid  = var.tje_okta_clientid
  tje_okta_orgdomain = var.tje_okta_orgdomain
}

## Create Jamf Security Cloud Activation Profile containing ONLY Connect Network Relay
# module "jsc_network_relay" {
#   count  = var.include_jsc_network_relay == true ? 1 : 0
#   source = "./modules/network_security_jamf_pro_network_relay"
# }






