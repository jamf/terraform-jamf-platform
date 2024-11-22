# Copyright 2024, Jamf
## Call Terraform provider
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = ">= 0.1.11"
    }
  }
}

resource "random_integer" "entropy" {
  min = 10
  max = 999
}

## Create categories
resource "jamfpro_category" "category_sonoma_cis_lvl1_benchmarks" {
  name     = "Sonoma - CIS Level 1 Benchmarks [${random_integer.entropy.result}]"
  priority = 9
}

resource "jamfpro_category" "category_sequoia_cis_lvl1_benchmarks" {
  name     = "Sequoia - CIS Level 1 Benchmarks [${random_integer.entropy.result}]"
  priority = 9
}

## Create scripts
resource "jamfpro_script" "script_sonoma_cis_lvl1_compliance" {
  name            = "Sonoma - CIS Level 1 Compliance [${random_integer.entropy.result}]"
  priority        = "AFTER"
  script_contents = file("${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_scripts/sonoma_cis_lvl1_compliance.sh")
  category_id     = jamfpro_category.category_sonoma_cis_lvl1_benchmarks.id
  info            = "This script will apply a set of rules related to the CIS Level 1 benchmark for macOS Sonoma"
}

resource "jamfpro_script" "script_sequoia_cis_lvl1_compliance" {
  name            = "Sequoia - CIS Level 1 Compliance [${random_integer.entropy.result}]"
  priority        = "AFTER"
  script_contents = file("${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_scripts/sequoia_cis_lvl1_compliance.sh")
  category_id     = jamfpro_category.category_sequoia_cis_lvl1_benchmarks.id
  info            = "This script will apply a set of rules related to the CIS Level 1 benchmark for macOS Sequoia"
}

## Create computer extension attributes
resource "jamfpro_computer_extension_attribute" "ea_cis_lvl1_failed_count" {
  name                   = "CIS Level 1 - Failed Results Count [${random_integer.entropy.result}]"
  input_type             = "SCRIPT"
  enabled                = true
  data_type              = "INTEGER"
  inventory_display_type = "EXTENSION_ATTRIBUTES"
  script_contents        = file("${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_extension_attributes/compliance-FailedResultsCount.sh")
}

resource "jamfpro_computer_extension_attribute" "ea_cis_lvl1_failed_list" {
  name                   = "CIS Level 1 - Failed Results List [${random_integer.entropy.result}]"
  input_type             = "SCRIPT"
  enabled                = true
  data_type              = "STRING"
  inventory_display_type = "EXTENSION_ATTRIBUTES"
  script_contents        = file("${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_extension_attributes/compliance-FailedResultsList.sh")
}

resource "jamfpro_computer_extension_attribute" "ea_cis_lvl1_version" {
  name                   = "Compliance Version [${random_integer.entropy.result}]"
  input_type             = "SCRIPT"
  enabled                = true
  data_type              = "STRING"
  inventory_display_type = "EXTENSION_ATTRIBUTES"
  script_contents        = file("${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_extension_attributes/compliance-version.sh")
}

## Create Smart Computer Groups
resource "jamfpro_smart_computer_group" "group_sonoma_computers" {
  name = "CIS Level 1 - Sonoma Computers [${random_integer.entropy.result}]"
  criteria {
    name        = "Operating System Version"
    search_type = "like"
    value       = "14."
    and_or      = "and"
    priority    = 0
  }
  criteria {
    name        = "Serial Number"
    search_type = "like"
    value       = "111222333444555"
    and_or      = "and"
    priority    = 1
  }
}

resource "jamfpro_smart_computer_group" "group_sonoma_cis_lvl1_non_compliant" {
  name = "CIS Level 1 - Sonoma - Non Compliant Computers [${random_integer.entropy.result}]"
  criteria {
    name        = "Operating System Version"
    search_type = "like"
    value       = "14."
    and_or      = "and"
    priority    = 0
  }
  criteria {
    name        = jamfpro_computer_extension_attribute.ea_cis_lvl1_failed_count.name
    search_type = "more than"
    value       = "0"
    and_or      = "and"
    priority    = 1
  }
}

resource "jamfpro_smart_computer_group" "group_sequoia_computers" {
  name = "CIS Level 1 - Sequoia Computers [${random_integer.entropy.result}]"
  criteria {
    name        = "Operating System Version"
    search_type = "like"
    value       = "15."
    and_or      = "and"
    priority    = 0
  }
  criteria {
    name        = "Serial Number"
    search_type = "like"
    value       = "111222333444555"
    and_or      = "and"
    priority    = 1
  }
}

resource "jamfpro_smart_computer_group" "group_sequoia_cis_lvl1_non_compliant" {
  name = "CIS Level 1 - Sequoia - Non Compliant Computers [${random_integer.entropy.result}]"
  criteria {
    name        = "Operating System Version"
    search_type = "like"
    value       = "15."
    and_or      = "and"
    priority    = 0
  }
  criteria {
    name        = jamfpro_computer_extension_attribute.ea_cis_lvl1_failed_count.name
    search_type = "more than"
    value       = "0"
    and_or      = "and"
    priority    = 1
  }
}

## Create policies
resource "jamfpro_policy" "policy_sonoma_cis_lvl1_audit" {
  name            = "CIS Level 1 - Audit (Sonoma) [${random_integer.entropy.result}]"
  enabled         = true
  trigger_checkin = true
  frequency       = "Ongoing"
  category_id     = jamfpro_category.category_sonoma_cis_lvl1_benchmarks.id

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_sonoma_computers.id]
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
  name            = "CIS Level 1 - Remediation (Sonoma) [${random_integer.entropy.result}]"
  enabled         = true
  trigger_checkin = true
  frequency       = "Ongoing"
  category_id     = jamfpro_category.category_sonoma_cis_lvl1_benchmarks.id

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_sonoma_cis_lvl1_non_compliant.id]
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

resource "jamfpro_policy" "policy_sequoia_cis_lvl1_audit" {
  name            = "CIS Level 1 - Audit (Sequoia) [${random_integer.entropy.result}]"
  enabled         = true
  trigger_checkin = true
  frequency       = "Ongoing"
  category_id     = jamfpro_category.category_sequoia_cis_lvl1_benchmarks.id

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_sequoia_computers.id]
  }

  self_service {
    use_for_self_service = false
  }

  payloads {
    scripts {
      id         = jamfpro_script.script_sequoia_cis_lvl1_compliance.id
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

resource "jamfpro_policy" "policy_sequoia_cis_lvl1_remediation" {
  name            = "CIS Level 1 - Remediation (Sequoia) [${random_integer.entropy.result}]"
  enabled         = true
  trigger_checkin = true
  frequency       = "Ongoing"
  category_id     = jamfpro_category.category_sequoia_cis_lvl1_benchmarks.id

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_sequoia_cis_lvl1_non_compliant.id]
  }

  self_service {
    use_for_self_service = false
  }

  payloads {
    scripts {
      id         = jamfpro_script.script_sequoia_cis_lvl1_compliance.id
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

## Define configuration profile details for Sonoma
locals {
  sonoma_cis_lvl1_dict = {
    "Application Access"    = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sonoma_cis_lvl1-applicationaccess.mobileconfig"
    "Control Center"        = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sonoma_cis_lvl1-controlcenter.mobileconfig"
    "Login Window"          = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sonoma_cis_lvl1-loginwindow.mobileconfig"
    "MCX"                   = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sonoma_cis_lvl1-MCX.mobileconfig"
    "Password Policy"       = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sonoma_cis_lvl1-mobiledevice.passwordpolicy.mobileconfig"
    "Safari"                = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sonoma_cis_lvl1-Safari.mobileconfig"
    "Screen Saver"          = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sonoma_cis_lvl1-screensaver.mobileconfig"
    "Firewall"              = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sonoma_cis_lvl1-security.firewall.mobileconfig"
    "Siri"                  = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sonoma_cis_lvl1-Siri.mobileconfig"
    "Software Update"       = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sonoma_cis_lvl1-SoftwareUpdate.mobileconfig"
    "System Policy Control" = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sonoma_cis_lvl1-systempolicy.control.mobileconfig"
    "Terminal"              = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sonoma_cis_lvl1-Terminal.mobileconfig"
    "Managed Client"        = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sonoma_cis_lvl1-timed.mobileconfig"
  }
}

## Create configuration profiles for Sonoma
resource "jamfpro_macos_configuration_profile_plist" "sonoma_cis_lvl1" {
  for_each            = local.sonoma_cis_lvl1_dict
  name                = "Sonoma CIS Level 1 - ${each.key} [${random_integer.entropy.result}]"
  distribution_method = "Install Automatically"
  redeploy_on_update  = "Newly Assigned"
  category_id         = jamfpro_category.category_sonoma_cis_lvl1_benchmarks.id
  level               = "System"

  payloads         = file("${each.value}")
  payload_validate = false

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_sonoma_computers.id]
  }
}

## Define configuration profile details for Sequoia part 1
locals {
  sequoia_cis_lvl1_dict = {
    "Accessibility"          = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-Accessibility.mobileconfig"
    "Application Access"     = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-applicationaccess.mobileconfig"
    "Assistant"              = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-assistant.support.mobileconfig"
    "Control Center"         = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-controlcenter.mobileconfig"
    "Login Window"           = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-loginwindow.mobileconfig"
    "MCX"                    = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-MCX.mobileconfig"
    "Password Policy"        = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-mobiledevice.passwordpolicy.mobileconfig"
    "Safari"                 = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-Safari.mobileconfig"
    "Screen Saver"           = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-screensaver.mobileconfig"
    "Firewall"               = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-security.firewall.mobileconfig"
    "Siri"                   = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-Siri.mobileconfig"
    "Software Update"        = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-SoftwareUpdate.mobileconfig"
    "Submit Diagnostic Info" = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-SubmitDiagInfo.mobileconfig"
    "System Policy Control"  = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-systempolicy.control.mobileconfig"
    "Terminal"               = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-Terminal.mobileconfig"
    "Managed Client"         = "${var.support_files_path_prefix}modules/trusted_access_outcomes/endpoint_compliance/computers/mac_cis_lvl1_benchmark/support_files/computer_config_profiles/sequoia_cis_lvl1-timed.mobileconfig"

  }
}

## Create configuration profiles for Sequoia part 1
resource "jamfpro_macos_configuration_profile_plist" "sequoia_cis_lvl1" {
  for_each            = local.sequoia_cis_lvl1_dict
  name                = "Sequoia CIS Level 1 - ${each.key} [${random_integer.entropy.result}]"
  distribution_method = "Install Automatically"
  redeploy_on_update  = "Newly Assigned"
  category_id         = jamfpro_category.category_sequoia_cis_lvl1_benchmarks.id
  level               = "System"

  payloads         = file("${each.value}")
  payload_validate = false

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_sequoia_computers.id]
  }
  depends_on = [jamfpro_macos_configuration_profile_plist.sonoma_cis_lvl1]
}
