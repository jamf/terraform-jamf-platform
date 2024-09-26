/*
The resources in this file will install any browser selected browser during onboarding processes.
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
  chrome_dict           = var.install_chrome ? { "Google Chrome" = "https://dl.google.com/dl/chrome/mac/universal/stable/gcem/GoogleChrome.pkg" } : {}
  firefox_dict          = var.install_firefox ? { "Mozilla Firefox" = "https://download.mozilla.org/?product=firefox-pkg-latest-ssl&os=osx" } : {}
  browser_packages_dict = merge(local.chrome_dict, local.firefox_dict)

  any_browser_selected = var.install_chrome || var.install_firefox
}

## Create category
resource "jamfpro_category" "category_browsers" {
  count    = local.any_browser_selected ? 1 : 0
  name     = "Browsers"
  priority = 9
}

## Upload packages
resource "jamfpro_package" "browser_apps" {
  for_each              = local.browser_packages_dict
  package_name          = "${var.prefix}${each.key}"
  info                  = ""
  category_id           = jamfpro_category.category_browsers[0].id
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

## Create policies
resource "jamfpro_policy" "browser_installs" {
  for_each                    = local.browser_packages_dict
  name                        = "${var.prefix}${each.key}"
  category_id                 = jamfpro_category.category_browsers[0].id
  enabled                     = true
  trigger_checkin             = true
  trigger_other               = "" // "USER_INITIATED" for self service trigger , "EVENT" for an event trigger
  frequency                   = "Once per computer"
  retry_event                 = "check-in"
  retry_attempts              = 3
  notify_on_each_failed_retry = false


  scope {
    all_computers      = false
    computer_group_ids = [1]
  }

  payloads {
    packages {
      distribution_point = "default" // Set the appropriate distribution point
      package {
        id                          = jamfpro_package.browser_apps[each.key].id
        action                      = "Install" // The action to perform with the package (e.g., Install, Cache, etc.)
        fill_user_template          = false     // Whether to fill the user template
        fill_existing_user_template = false     // Whether to fill existing user templates
      }
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