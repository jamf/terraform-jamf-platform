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
      version = ">= 0.1.5"
    }
  }
}

## Create categories
resource "jamfpro_category" "category_cis_benchmarks" {
  name     = "${var.prefix}Mac CIS Benchmarks"
  priority = 9
}

## Create scripts
resource "jamfpro_script" "script_cis_apply" {
  name            = "${var.prefix}Apply CIS"
  priority        = "AFTER"
  script_contents = file("${var.support_files_path_prefix}support_files/computer_scripts/cis_apply.sh")
  category_id     = jamfpro_category.category_cis_benchmarks.id
  info            = "This script will create a witness file on computers to trigger a CIS Benchmark deployment"
}

resource "jamfpro_script" "script_cis_remove" {
  name            = "${var.prefix}Remove CIS"
  priority        = "AFTER"
  script_contents = file("${var.support_files_path_prefix}support_files/computer_scripts/cis_remove.sh")
  category_id     = jamfpro_category.category_cis_benchmarks.id
  info            = "This script will create a witness file on computers to trigger a CIS Benchmark removal"
}

resource "jamfpro_script" "script_sonoma_cis_lvl1_compliance" {
  name            = "${var.prefix}Sonoma CIS Level 1 Compliance"
  priority        = "AFTER"
  script_contents = file("${var.support_files_path_prefix}support_files/computer_scripts/sonoma_cis_lvl1_compliance.sh")
  category_id     = jamfpro_category.category_cis_benchmarks.id
  info            = "This script will apply a set of rules related to the CIS Level 1 benchmark for macOS Sonoma"
}

## Create computer extension attributes
resource "jamfpro_computer_extension_attribute" "ea_sonoma_cis_apply" {
  name              = "${var.prefix}Apply CIS Flag"
  input_type        = "script"
  enabled           = true
  data_type         = "string"
  inventory_display = "Extension Attributes"
  input_script      = file("${var.support_files_path_prefix}support_files/computer_extension_attributes/sonoma_cis_apply.sh")
}

resource "jamfpro_computer_extension_attribute" "ea_sonoma_cis_remove" {
  name              = "${var.prefix}Remove CIS Flag"
  input_type        = "script"
  enabled           = true
  data_type         = "string"
  inventory_display = "Extension Attributes"
  input_script      = file("${var.support_files_path_prefix}support_files/computer_extension_attributes/sonoma_cis_remove.sh")
}

resource "jamfpro_computer_extension_attribute" "ea_cis_failed_count" {
  name              = "${var.prefix}CIS - Compliance Failed Results Count"
  input_type        = "script"
  enabled           = true
  data_type         = "integer"
  inventory_display = "Extension Attributes"
  input_script      = file("${var.support_files_path_prefix}support_files/computer_extension_attributes/cis_compliance_failed_count.sh")
}

## Create Smart Computer Groups
resource "jamfpro_smart_computer_group" "group_sonoma_computers" {
  name = "${var.prefix}CIS - Sonoma Computers"
  criteria {
    name        = "Operating System Version"
    search_type = "like"
    value       = "14."
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_sonoma_cis_lvl1_apply" {
  name = "${var.prefix}CIS Level 1 - Sonoma - Apply"
  criteria {
    name        = "Operating System Version"
    search_type = "like"
    value       = "14."
    and_or      = "and"
    priority    = 0
  }
  criteria {
    name        = jamfpro_computer_extension_attribute.ea_sonoma_cis_apply.name
    search_type = "like"
    value       = "apply_cis"
    and_or      = "and"
    priority    = 1
  }
}

resource "jamfpro_smart_computer_group" "group_sonoma_cis_lvl1_remove" {
  name = "${var.prefix}CIS Level 1 - Sonoma - Remove"
  criteria {
    name        = "Operating System Version"
    search_type = "like"
    value       = "14."
    and_or      = "and"
    priority    = 0
  }
  criteria {
    name        = jamfpro_computer_extension_attribute.ea_sonoma_cis_remove.name
    search_type = "like"
    value       = "remove_cis"
    and_or      = "and"
    priority    = 1
  }
}

resource "jamfpro_smart_computer_group" "group_sonoma_cis_lvl1_non_compliant" {
  name = "${var.prefix}CIS Level 1 - Sonoma - Non Compliant Computers"
  criteria {
    name        = "Operating System Version"
    search_type = "like"
    value       = "14."
    and_or      = "and"
    priority    = 0
  }
  criteria {
    name        = jamfpro_computer_extension_attribute.ea_cis_failed_count.name
    search_type = "more than"
    value       = "0"
    and_or      = "and"
    priority    = 1
  }
}

resource "jamfpro_smart_computer_group" "group_sonoma_cis_lvl1_profiles_present" {
  name = "${var.prefix}CIS Level 1 - Sonoma - Profiles Present"
  criteria {
    name        = "Profile Name"
    search_type = "has"
    value       = "Sonoma_cis"
    and_or      = "and"
    priority    = 0
  }
}

## Create policies
resource "jamfpro_policy" "policy_cis_apply" {
  name          = "${var.prefix}CIS Level 1 - Apply (Sonoma)"
  enabled       = true
  trigger_other = "sonomacis"
  frequency     = "Ongoing"
  category_id   = jamfpro_category.category_cis_benchmarks.id
  depends_on    = [jamfpro_smart_computer_group.group_sonoma_computers]

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_sonoma_computers.id]
  }

  self_service {
    use_for_self_service            = true
    self_service_display_name       = "CIS Level 1 - Apply (Sonoma)"
    install_button_text             = "Apply"
    self_service_description        = file("${var.support_files_path_prefix}support_files/computer_policies/sonoma_cis_lvl1_apply_self_service_desc.txt")
    force_users_to_view_description = false
    feature_on_main_page            = false
  }

  payloads {
    scripts {
      id = jamfpro_script.script_cis_apply.id
    }

    reboot {
      file_vault_2_reboot            = false
      message                        = "This computer will restart in 5 minutes. Please save anything you are working on and log out by choosing Log Out from the bottom of the Apple menu."
      minutes_until_reboot           = 5
      no_user_logged_in              = "Do not restart"
      start_reboot_timer_immediately = false
      startup_disk                   = "Current Startup Disk"
      user_logged_in                 = "Do not restart"
    }
  }
}

resource "jamfpro_policy" "policy_cis_remove" {
  name          = "${var.prefix}CIS Level 1 - Remove (Sonoma)"
  enabled       = true
  trigger_other = "sonomacisremove"
  frequency     = "Ongoing"
  category_id   = jamfpro_category.category_cis_benchmarks.id
  depends_on    = [jamfpro_smart_computer_group.group_sonoma_cis_lvl1_profiles_present]

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_sonoma_cis_lvl1_profiles_present.id]
  }

  self_service {
    use_for_self_service            = true
    self_service_display_name       = "CIS Level 1 - Remove (Sonoma)"
    install_button_text             = "Remove"
    self_service_description        = file("${var.support_files_path_prefix}support_files/computer_policies/sonoma_cis_lvl1_remove_self_service_desc.txt")
    force_users_to_view_description = false
    feature_on_main_page            = false
  }

  payloads {
    scripts {
      id = jamfpro_script.script_cis_remove.id
    }

    reboot {
      file_vault_2_reboot            = false
      message                        = "This computer will restart in 5 minutes. Please save anything you are working on and log out by choosing Log Out from the bottom of the Apple menu."
      minutes_until_reboot           = 5
      no_user_logged_in              = "Do not restart"
      start_reboot_timer_immediately = false
      startup_disk                   = "Current Startup Disk"
      user_logged_in                 = "Do not restart"
    }
  }
}

resource "jamfpro_policy" "policy_sonoma_cis_lvl1_audit" {
  name          = "${var.prefix}CIS Level 1 - Audit (Sonoma)"
  enabled       = true
  trigger_other = "@CIS_audit"
  frequency     = "Ongoing"
  category_id   = jamfpro_category.category_cis_benchmarks.id

  scope {
    all_computers      = false
    computer_group_ids = []
  }

  self_service {
    use_for_self_service = false
  }

  payloads {
    scripts {
      id         = jamfpro_script.script_sonoma_cis_lvl1_compliance.id
      parameter4 = "--check"
    }

    maintenance {
      recon = true
    }

    reboot {
      file_vault_2_reboot            = false
      message                        = "This computer will restart in 5 minutes. Please save anything you are working on and log out by choosing Log Out from the bottom of the Apple menu."
      minutes_until_reboot           = 5
      no_user_logged_in              = "Do not restart"
      start_reboot_timer_immediately = false
      startup_disk                   = "Current Startup Disk"
      user_logged_in                 = "Do not restart"
    }
  }
}

resource "jamfpro_policy" "policy_sonoma_cis_lvl1_remediation" {
  name            = "${var.prefix}CIS Level 1 - Remediation (Sonoma)"
  enabled         = true
  trigger_checkin = true
  frequency       = "Ongoing"
  category_id     = jamfpro_category.category_cis_benchmarks.id

  scope {
    all_computers      = false
    computer_group_ids = []
  }

  self_service {
    use_for_self_service = false
  }

  payloads {
    scripts {
      id         = jamfpro_script.script_sonoma_cis_lvl1_compliance.id
      parameter4 = "--check"
      parameter5 = "--fix"
      parameter6 = "--check"
    }

    maintenance {
      recon = true
    }

    reboot {
      file_vault_2_reboot            = false
      message                        = "This computer will restart in 5 minutes. Please save anything you are working on and log out by choosing Log Out from the bottom of the Apple menu."
      minutes_until_reboot           = 5
      no_user_logged_in              = "Do not restart"
      start_reboot_timer_immediately = false
      startup_disk                   = "Current Startup Disk"
      user_logged_in                 = "Do not restart"
    }
  }
}

## Define configuration profile details
locals {
  cis_lvl1_macos_14_dict = {
    "Application Access"    = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-applicationaccess.mobileconfig"
    "Login Window"          = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-loginwindow.mobileconfig"
    "Managed Client"        = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-timed.mobileconfig"
    "MCX"                   = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-mcx.mobileconfig"
    "Safari"                = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-safari.mobileconfig"
    "Screen Saver"          = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-screensaver.mobileconfig"
    "System Policy Control" = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-systempolicy.control.mobileconfig"
    "Terminal"              = "${var.support_files_path_prefix}support_files/computer_config_profiles/sonoma_cis_lvl1-terminal.mobileconfig"
  }
}

## Create configuration profiles
resource "jamfpro_macos_configuration_profile_plist" "sonoma_cis_lvl1" {
  for_each            = local.cis_lvl1_macos_14_dict
  name                = "${var.prefix}Sonoma_cis_lvl1 - ${each.key}"
  distribution_method = "Install Automatically"
  /*redeploy_on_update  = "Newly Assigned"*/
  category_id = jamfpro_category.category_cis_benchmarks.id
  level       = "System"

  payloads = file("${each.value}")

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_sonoma_cis_lvl1_apply.id]
  }

  depends_on = [jamfpro_smart_computer_group.group_sonoma_cis_lvl1_apply]
}
