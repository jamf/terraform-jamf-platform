/*
This terraform blueprint will build the Local macOS Accoiunt Management (LMAM) vignette from Experience Jamf.
It will do the following:
 - Create 1 category
 - Create 2 scripts
 - Upload 3 packages
 - Create 1 extension attribute
 - Create 1 smart computer groups
 - Create 3 policies
 - Create 2 configuration profiles

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

## Create categories
resource "jamfpro_category" "category_jamf_connect" {
  name     = "${var.prefix}Jamf Connect"
  priority = 9
}

## Upload Packages (grab from repo project files, then upload to Jamf Pro) 

## Define the dictionary of packages with their paths
locals {
  lmam_packages_dict = {
    "JamfConnect_2.38.0"         = "${var.support_files_path_prefix}support_files/computer_packages/JamfConnect_2.38.0.pkg"
    "JamfConnectAssets_EJ_v2"    = "${var.support_files_path_prefix}support_files/computer_packages/JamfConnectAssets-EJ_v2_Ward-20240724.pkg"
    "JamfConnectLaunchAgent"     = "${var.support_files_path_prefix}support_files/computer_packages/JamfConnectLaunchAgent.pkg"
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

## Create computer extension attributes
resource "jamfpro_computer_extension_attribute" "ea_LMAM-marker" {
  name              = "${var.prefix}LMAM-marker"
  input_type        = "script"
  enabled           = true
  data_type         = "string"
  inventory_display = "Extension Attributes"
  input_script      = file("${var.support_files_path_prefix}support_files/computer_extension_attributes/LMAM-marker.sh")
}

## Create Smart Computer Groups
resource "jamfpro_smart_computer_group" "group_LMAM-vignette-enabled" {
  name = "${var.prefix}LMAM Run (Vignette Enabled)"
  criteria {
    name        = jamfpro_computer_extension_attribute.ea_LMAM-marker.name
    search_type = "is"
    value       = "lmamRUN"
    and_or      = "and"
    priority    = 0
  }
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

# resource "jamfpro_policy" "policy_cis_remove" {
#   name          = "${var.prefix}CIS Level 1 - Remove (Sonoma)"
#   enabled       = true
#   trigger_other = "sonomacisremove"
#   frequency     = "Ongoing"
#   category_id   = jamfpro_category.category_cis_benchmarks.id
#   depends_on    = [jamfpro_smart_computer_group.group_sonoma_cis_lvl1_profiles_present]

#   scope {
#     all_computers      = false
#     computer_group_ids = [jamfpro_smart_computer_group.group_sonoma_cis_lvl1_profiles_present.id]
#   }

#   self_service {
#     use_for_self_service            = true
#     self_service_display_name       = "CIS Level 1 - Remove (Sonoma)"
#     install_button_text             = "Remove"
#     self_service_description        = file("${var.support_files_path_prefix}support_files/computer_policies/sonoma_cis_lvl1_remove_self_service_desc.txt")
#     force_users_to_view_description = false
#     feature_on_main_page            = false
#   }

#   payloads {
#     scripts {
#       id = jamfpro_script.script_cis_remove.id
#     }

#     reboot {
#       file_vault_2_reboot            = false
#       message                        = "This computer will restart in 5 minutes. Please save anything you are working on and log out by choosing Log Out from the bottom of the Apple menu."
#       minutes_until_reboot           = 5
#       no_user_logged_in              = "Do not restart"
#       start_reboot_timer_immediately = false
#       startup_disk                   = "Current Startup Disk"
#       user_logged_in                 = "Do not restart"
#     }
#   }
# }

# resource "jamfpro_policy" "policy_sonoma_cis_lvl1_audit" {
#   name          = "${var.prefix}CIS Level 1 - Audit (Sonoma)"
#   enabled       = true
#   trigger_other = "@CIS_audit"
#   frequency     = "Ongoing"
#   category_id   = jamfpro_category.category_cis_benchmarks.id

#   scope {
#     all_computers      = false
#     computer_group_ids = []
#   }

#   self_service {
#     use_for_self_service = false
#   }

#   payloads {
#     scripts {
#       id         = jamfpro_script.script_sonoma_cis_lvl1_compliance.id
#       parameter4 = "--check"
#     }

#     maintenance {
#       recon = true
#     }

#     reboot {
#       file_vault_2_reboot            = false
#       message                        = "This computer will restart in 5 minutes. Please save anything you are working on and log out by choosing Log Out from the bottom of the Apple menu."
#       minutes_until_reboot           = 5
#       no_user_logged_in              = "Do not restart"
#       start_reboot_timer_immediately = false
#       startup_disk                   = "Current Startup Disk"
#       user_logged_in                 = "Do not restart"
#     }
#   }
# }

# resource "jamfpro_policy" "policy_sonoma_cis_lvl1_remediation" {
#   name            = "${var.prefix}CIS Level 1 - Remediation (Sonoma)"
#   enabled         = true
#   trigger_checkin = true
#   frequency       = "Ongoing"
#   category_id     = jamfpro_category.category_cis_benchmarks.id

#   scope {
#     all_computers      = false
#     computer_group_ids = []
#   }

#   self_service {
#     use_for_self_service = false
#   }

#   payloads {
#     scripts {
#       id         = jamfpro_script.script_sonoma_cis_lvl1_compliance.id
#       parameter4 = "--check"
#       parameter5 = "--fix"
#       parameter6 = "--check"
#     }

#     maintenance {
#       recon = true
#     }

#     reboot {
#       file_vault_2_reboot            = false
#       message                        = "This computer will restart in 5 minutes. Please save anything you are working on and log out by choosing Log Out from the bottom of the Apple menu."
#       minutes_until_reboot           = 5
#       no_user_logged_in              = "Do not restart"
#       start_reboot_timer_immediately = false
#       startup_disk                   = "Current Startup Disk"
#       user_logged_in                 = "Do not restart"
#     }
#   }
# }

# ## Define configuration profile details
# locals {
#   cis_lvl1_macos_14_dict = {
#     "Application Access"    = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-applicationaccess.mobileconfig"
#     "Login Window"          = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-loginwindow.mobileconfig"
#     "Managed Client"        = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-timed.mobileconfig"
#     "MCX"                   = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-mcx.mobileconfig"
#     "Safari"                = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-safari.mobileconfig"
#     "Screen Saver"          = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-screensaver.mobileconfig"
#     "System Policy Control" = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-systempolicy.control.mobileconfig"
#     "Terminal"              = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-terminal.mobileconfig"
#   }
# }

# ## Create configuration profiles
# resource "jamfpro_macos_configuration_profile_plist" "sonoma_cis_lvl1" {
#   for_each            = local.cis_lvl1_macos_14_dict
#   name                = "${var.prefix}Sonoma_cis_lvl1 - ${each.key}"
#   distribution_method = "Install Automatically"
#   /*redeploy_on_update  = "Newly Assigned"*/
#   category_id = jamfpro_category.category_cis_benchmarks.id
#   level       = "System"

#   payloads = file("${each.value}")

#   scope {
#     all_computers      = false
#     computer_group_ids = [jamfpro_smart_computer_group.group_sonoma_cis_lvl1_apply.id]
#   }

#   depends_on = [jamfpro_smart_computer_group.group_sonoma_cis_lvl1_apply]
# }
