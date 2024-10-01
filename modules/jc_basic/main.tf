/*
This terraform blueprint will build the macOS CIS Benchmark vignette from Experience Jamf.
It will do the following:
 - Create 1 category
 - Create 3 scripts
 - Create 3 extension attributes
 - Create 5 smart computer groups
 - Create 4 policies
 - Create 8 configuration profiles

 Prerequisites:
  - the Dialog tool must be installed
*/

## Call Terraform provider
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = ">= 0.3.1"
    }
  }
}

## Create categories
resource "jamfpro_category" "category_jc_basic" {
  name     = "Jamf Connect"
  priority = 9
}

## Create scripts
resource "jamfpro_script" "script_jc_basic_install" {
  name            = "${var.prefix}jamf Connect Download and Install"
  priority        = "AFTER"
  script_contents = file("${var.support_files_path_prefix}support_files/scripts/jcscript.zsh")
  category_id     = jamfpro_category.category_jc_basic.id
  info            = "Source: https://gist.github.com/talkingmoose/94882adb69403a24794f6b84d4ae9de5"
}


## Create Smart Computer Groups
resource "jamfpro_smart_computer_group" "group_jc_basic_profile_installed" {
  name = "Jamf Connect Settings Installed"
  criteria {
    name        = "Profile Name"
    search_type = "has"
    value       = "Jamf Connect PreConfigured Trial Settings - Okta"
    and_or      = "and"
    priority    = 0
  }
}

## Create policies
resource "jamfpro_policy" "policy_jc_basic_install" {
  name          = "Jamf Connect Application Install"
  enabled       = true
  trigger_other = ""
  frequency     = "Ongoing"
  category_id   = jamfpro_category.category_jc_basic.id
  

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_jc_basic_profile_installed.id]
  }

  self_service {
    use_for_self_service            = true
    self_service_display_name       = "Jamf Connect Installer"
    install_button_text             = "Install Now"
    self_service_description        = "DON'T INSTALL THE JAMF CONNECT APPLICATION UNTIL YOU'VE RECEIVED THE IDP CREDENTIALS FROM YOUR JAMF SALES TEAM"
    force_users_to_view_description = true
    feature_on_main_page            = false
  }

  payloads {
    scripts {
      id = jamfpro_script.script_jc_basic_install.id
      priority    = "After"
    }

   maintenance {
      recon                       = true
      reset_name                  = false
      install_all_cached_packages = false
      heal                        = false
      prebindings                 = false
      permissions                 = false
      byhost                      = false
      system_cache                = false
      user_cache                  = false
      verify                      = false
    }
  }
}

## Create configuration profiles
resource "jamfpro_macos_configuration_profile_plist" "jamfpro_jc_okta_profile" {
  name                = "Jamf Connect PreConfigured Trial Settings - Okta"
  description         = "This Configuration Profile contains the Jamf Connect Preconfigured Trial IDP Settings for Jamf Connect Login and Menu Bar Application"
  level               = "System"
  category_id         = jamfpro_category.category_jc_basic.id
  redeploy_on_update  = "Newly Assigned"
  distribution_method = "Install Automatically"
  payloads            = file("${var.support_files_path_prefix}support_files/config_profiles/jc_basic_okta.mobileconfig")
  payload_validate    = false
  user_removable      = false

  scope {
    all_computers = true
    all_jss_users = false
  }
}