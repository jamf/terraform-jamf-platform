# Copyright 2024, Jamf
/*
This terraform blueprint will build the Aftermath vignette from Experience Jamf.
It will do the following:
 - Create 1 category
 - Create 2 computer extension attributes
 - Create 2 smart computer groups
 - Upload 1 package
 - Import 2 scripts
 - Create 3 policies
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

## Create category
resource "jamfpro_category" "category_threat_response" {
  name     = "${var.prefix}Threat and Incident Response"
  priority = 9
}

## Create extension attributes
resource "jamfpro_computer_extension_attribute" "ea_aftermath_analyze_trigger" {
  name                   = "${var.prefix}Aftermath Analyze Trigger"
  input_type             = "SCRIPT"
  enabled                = true
  data_type              = "STRING"
  inventory_display_type = "EXTENSION_ATTRIBUTES"
  script_contents        = file("${var.support_files_path_prefix}support_files/computer_extension_attributes/aftermath_analyze_trigger.sh")
}

resource "jamfpro_computer_extension_attribute" "ea_aftermath_trigger" {
  name                   = "${var.prefix}Aftermath Trigger"
  input_type             = "SCRIPT"
  enabled                = true
  data_type              = "STRING"
  inventory_display_type = "EXTENSION_ATTRIBUTES"
  script_contents        = file("${var.support_files_path_prefix}support_files/computer_extension_attributes/aftermath_trigger.sh")
}

## Create smart groups
resource "jamfpro_smart_computer_group" "group_aftermath_analyze_trigger" {
  name = "${var.prefix}Aftermath Analyze Trigger"
  criteria {
    name        = jamfpro_computer_extension_attribute.ea_aftermath_analyze_trigger.name
    search_type = "is"
    value       = "analyze"
  }
}

resource "jamfpro_smart_computer_group" "group_aftermath_collection_trigger" {
  name = "${var.prefix}Aftermath Collection Trigger"
  criteria {
    name        = jamfpro_computer_extension_attribute.ea_aftermath_trigger.name
    search_type = "is"
    value       = "aftermath"
  }
}

## Upload packages
resource "jamfpro_package" "package_aftermath" {
  package_name          = "Aftermath.pkg"
  info                  = "Version 2.2.1 - March 8 2024"
  package_file_source   = "https://github.com/jamf/aftermath/releases/download/v2.2.1/Aftermath.pkg"
  os_install            = false
  fill_user_template    = false
  priority              = 10
  reboot_required       = false
  suppress_eula         = false
  suppress_from_dock    = false
  suppress_registration = false
  suppress_updates      = false
}

## Import scripts
resource "jamfpro_script" "script_aftermath_analyze" {
  name            = "${var.prefix}Vignette.Behavioral.IR-Aftermath-Analyze.sh"
  priority        = "AFTER"
  script_contents = file("${var.support_files_path_prefix}support_files/computer_scripts/aftermath_analyze.sh")
  category_id     = jamfpro_category.category_threat_response.id
  info            = "This script will run Aftermath on a system, analyze the output, and open the storyline.csv file after analysis is complete. Messages are presented throughout the process to communicate what is happening."
}

resource "jamfpro_script" "script_aftermath_collection" {
  name            = "${var.prefix}Vignette.Behavioral.IR-Aftermath-Collection.sh"
  priority        = "AFTER"
  script_contents = file("${var.support_files_path_prefix}support_files/computer_scripts/aftermath_collection.sh")
  category_id     = jamfpro_category.category_threat_response.id
}

## Create policies
resource "jamfpro_policy" "policy_install_aftermath" {
  name                        = "Install Aftermath.pkg"
  enabled                     = true
  trigger_enrollment_complete = true
  trigger_other               = "@installAftermath" // "USER_INITIATED" for self service trigger , "EVENT" for an event trigger
  frequency                   = "Once per computer"
  retry_event                 = "check-in"
  retry_attempts              = 3
  notify_on_each_failed_retry = false
  target_drive                = "/"


  scope {
    all_computers      = false
    computer_group_ids = [1]
  }

  payloads {
    packages {
      distribution_point = "default" // Set the appropriate distribution point
      package {
        id                          = jamfpro_package.package_aftermath.id
        action                      = "Install" // The action to perform with the package (e.g., Install, Cache, etc.)
        fill_user_template          = false     // Whether to fill the user template
        fill_existing_user_template = false     // Whether to fill existing user templates
      }
    }
    maintenance {
      recon = true
    }
  }
}

resource "jamfpro_policy" "policy_aftermath_analysis" {
  name          = "${var.prefix}Vignette.Behavioral.IR-Aftermath-Analysis"
  enabled       = true
  trigger_other = "@aftermathAnalysis"
  frequency     = "Ongoing"
  target_drive  = "/"
  category_id   = jamfpro_category.category_threat_response.id

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_aftermath_analyze_trigger.id]
  }

  self_service {
    use_for_self_service            = true
    self_service_display_name       = "Aftermath Analysis"
    install_button_text             = "Analyze"
    self_service_description        = file("${var.support_files_path_prefix}support_files/computer_policies/aftermath_analyze_self_service_desc.txt")
    force_users_to_view_description = false
    feature_on_main_page            = false
  }

  payloads {
    scripts {
      id = jamfpro_script.script_aftermath_analyze.id
    }
  }
}

resource "jamfpro_policy" "policy_aftermath_collection" {
  name          = "${var.prefix}Vignette.Behavioral.IR-Aftermath-Collection"
  enabled       = true
  trigger_other = "@aftermathCollection"
  frequency     = "Ongoing"
  target_drive  = "/"
  category_id   = jamfpro_category.category_threat_response.id

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_aftermath_collection_trigger.id]
  }

  self_service {
    use_for_self_service            = true
    self_service_display_name       = "Aftermath Incident Response Log Collection"
    install_button_text             = "Collect"
    self_service_description        = file("${var.support_files_path_prefix}support_files/computer_policies/aftermath_collection_self_service_desc.txt")
    force_users_to_view_description = false
    feature_on_main_page            = false
  }

  payloads {
    scripts {
      id = jamfpro_script.script_aftermath_collection.id
    }
  }
}
