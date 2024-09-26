/*
The resources in this file will install any workflow selected profiles during onboarding processes.
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




## Create dict based on selected items only
locals {
  config1_dict  = var.block_beta_updates ? { "Block macOS Beta" = file("${var.support_files_path_prefix}support_files/configuration_profiles/block_beta_updates.mobileconfig") } : {}
  config2_dict  = var.enforce_firewall_and_gatekeeper ? { "Enforce Firewall and Gatekeeper" = file("${var.support_files_path_prefix}support_files/configuration_profiles/enforce_firewall_and_gatekeeper.mobileconfig") } : {}
  profiles_dict = merge(local.config1_dict, local.config2_dict)

  any_item_selected = var.block_beta_updates || var.enforce_firewall_and_gatekeeper
}

## Create category
resource "jamfpro_category" "category_profiles" {
  count    = local.any_item_selected ? 1 : 0
  name     = "Profiles"
  priority = 9
}

## Create configuration profiles
resource "jamfpro_macos_configuration_profile_plist" "ow_profiles" {
  for_each            = local.profiles_dict
  name                = "${var.prefix}${each.key}"
  distribution_method = "Install Automatically"
  /*redeploy_on_update  = "Newly Assigned"*/
  category_id = jamfpro_category.category_profiles[0].id
  level       = "System"

  payloads = each.value

  scope {
    all_computers      = false
    computer_group_ids = [1]
  }
}
