# Copyright 2024, Jamf
/*
This terraform blueprint will build the Local macOS Accoiunt Management (LMAM) vignette as exists in Experience Jamf.

It will do the following:
 - Create 2 categories
 - Create 2 scripts
 - Upload 3 packages
 - Create 1 extension attribute
 - Create 1 smart computer groups
 - Create 3 policies
 - Create/upload 2 configuration profiles

 Prerequisites:
  - the Dialog tool must be installed
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

## Create computer extension attributes
resource "jamfpro_computer_extension_attribute" "ea_LMAM-marker" {
  name                   = "${var.prefix}LMAM-marker"
  input_type             = "SCRIPT"
  enabled                = true
  data_type              = "STRING"
  inventory_display_type = "EXTENSION_ATTRIBUTES"
  script_contents        = file("${var.support_files_path_prefix}support_files/computer_extension_attributes/LMAM-marker.sh")
}

## Create categories
resource "jamfpro_category" "category_jamf_connect" {
  name     = "${var.prefix}Jamf Connect"
  priority = 9
}

resource "jamfpro_category" "category_experience_jamf" {
  name     = "${var.prefix}Experience Jamf"
  priority = 1
}

## Upload Packages (grab from repo project files, then upload to Jamf Pro) 

## Define the dictionary of packages with their paths
locals {
  lmam_packages_dict = {
    "JamfConnect_2.38.0"      = "${var.support_files_path_prefix}support_files/computer_packages/JamfConnect_2.38.0.pkg"
    "JamfConnectAssets_EJ_v2" = "${var.support_files_path_prefix}support_files/computer_packages/JamfConnectAssets-EJ_v2_Ward-20240724.pkg"
    "JamfConnectLaunchAgent"  = "${var.support_files_path_prefix}support_files/computer_packages/JamfConnectLaunchAgent.pkg"
  }
}

resource "jamfpro_package" "lmam_packages" {
  for_each              = local.lmam_packages_dict
  package_name          = "${var.prefix}${each.key}"
  info                  = ""
  category_id           = jamfpro_category.category_jamf_connect.id
  package_file_source   = each.value
  os_install            = false
  fill_user_template    = false
  priority              = 10
  reboot_required       = false
  suppress_eula         = false
  suppress_from_dock    = false
  suppress_registration = false
  suppress_updates      = false
}

## Create scripts
resource "jamfpro_script" "script_LMAM_vignette_first-run" {
  name            = "${var.prefix}LMAM_vignette_first-run"
  priority        = "BEFORE"
  script_contents = file("${var.support_files_path_prefix}support_files/computer_scripts/LMAM_vignette_first-run.zsh")
  category_id     = jamfpro_category.category_jamf_connect.id
  info            = "This script will places all components (LDs, scripts, etc) needed to run the vignette"
}

resource "jamfpro_script" "script_LMAM_vignette_clean_up" {
  name            = "${var.prefix}LMAM_vignette_clean_up"
  priority        = "BEFORE"
  script_contents = file("${var.support_files_path_prefix}support_files/computer_scripts/LMAM_vignette_cleanup-run.zsh")
  category_id     = jamfpro_category.category_jamf_connect.id
  info            = "This script will remove all components of the LMAM vigneete.."
}

## Create Smart Computer Groups
resource "jamfpro_smart_computer_group" "group_LMAM-vignette-enabled" {
  name = "${var.prefix}LMAM Run (Vignette Enabled)"

  criteria {
    name        = jamfpro_computer_extension_attribute.ea_LMAM-marker.name
    search_type = "is"
    value       = "lmamRUN"
    priority    = 0
  }

  depends_on = [
    jamfpro_computer_extension_attribute.ea_LMAM-marker
  ]
}

## Create policies
resource "jamfpro_policy" "install_JC_and_assets" {
  name          = "${var.prefix}Install Jamf Connect PKGs & LMAM Assets"
  enabled       = true
  trigger_other = "@installJC"
  frequency     = "Ongoing"
  category_id   = jamfpro_category.category_jamf_connect.id

  scope {
    all_computers = true
  }

  self_service {
    use_for_self_service = false
  }

  payloads {
    packages {
      distribution_point = "default" // Set the appropriate distribution point

      package {
        id     = jamfpro_package.lmam_packages["JamfConnect_2.38.0"].id
        action = "Install"
      }
      package {
        id     = jamfpro_package.lmam_packages["JamfConnectAssets_EJ_v2"].id
        action = "Install"
      }
      package {
        id     = jamfpro_package.lmam_packages["JamfConnectLaunchAgent"].id
        action = "Install"
      }
    }
  }
}

## Create policy for Vignette.LMAM-FirstRun
resource "jamfpro_policy" "Vignette_LMAM_FirstRun" {
  name          = "${var.prefix}Vignette.LMAM-FirstRun"
  enabled       = true
  trigger_other = "@LMAM"
  frequency     = "Ongoing"
  category_id   = jamfpro_category.category_jamf_connect.id

  depends_on = [
    jamfpro_category.category_jamf_connect
  ]

  scope {
    all_computers = true
  }

  self_service {
    use_for_self_service            = true
    self_service_display_name       = "Local macOS Account Mgmt"
    install_button_text             = "Run"
    self_service_description        = file("${var.support_files_path_prefix}support_files/computer_policies/LMAM_self_service_desc.txt")
    force_users_to_view_description = true
    feature_on_main_page            = false

    self_service_category {
      display_in = true
      feature_in = false
      id         = jamfpro_category.category_jamf_connect.id
    }
  }

  payloads {
    scripts {
      id = jamfpro_script.script_LMAM_vignette_first-run.id
    }
  }
}


resource "jamfpro_policy" "Vignette_LMAM_CleanUp" {
  name          = "${var.prefix}Vignette.LMAM-CleanUp"
  enabled       = true
  trigger_other = "@LMAM-CLEANUP"
  frequency     = "Ongoing"
  category_id   = jamfpro_category.category_jamf_connect.id

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_LMAM-vignette-enabled.id]
  }

  depends_on = [
    jamfpro_smart_computer_group.group_LMAM-vignette-enabled
  ]

  payloads {
    scripts {
      id = jamfpro_script.script_LMAM_vignette_clean_up.id
    }
  }
}

## Create Configuration Profiles

resource "jamfpro_macos_configuration_profile_plist" "LMAM_IDP_config" {
  name                = "${var.prefix}Local macOS Account Management | LMAM (JCL-JCMB-JCPE)"
  description         = "NA"
  level               = "System"
  distribution_method = "Install Automatically"
  category_id         = jamfpro_category.category_jamf_connect.id
  redeploy_on_update  = "Newly Assigned"
  payloads            = file("${var.support_files_path_prefix}support_files/computer_config_profiles/LMAM_IDP.mobileconfig")
  payload_validate    = false
  user_removable      = false

  depends_on = [
    jamfpro_smart_computer_group.group_LMAM-vignette-enabled, jamfpro_category.category_jamf_connect
  ]




  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_LMAM-vignette-enabled.id]
  }
}

resource "jamfpro_macos_configuration_profile_plist" "Experience_Jamf_Custom_Variables_config" {
  name                = "${var.prefix}Experience Jamf Custom Variables"
  description         = "NA"
  level               = "System"
  distribution_method = "Install Automatically"
  category_id         = jamfpro_category.category_experience_jamf.id

  depends_on = [
    jamfpro_category.category_experience_jamf
  ]

  redeploy_on_update = "Newly Assigned"
  payloads           = file("${var.support_files_path_prefix}support_files/computer_config_profiles/EJ_Custom_Variables.mobileconfig")
  payload_validate   = false
  user_removable     = false

  scope {
    all_computers = true
  }
}
