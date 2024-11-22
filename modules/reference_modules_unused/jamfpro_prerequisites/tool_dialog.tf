# Copyright 2024, Jamf
/*
This terraform blueprint will install the Dialog tool as part of its prerequisites.
It will do the following:
 - Upload 1 package
 - Create 1 policy
*/

## Upload packages
resource "jamfpro_package" "package_dialog" {
  package_name          = "${var.prefix}Dialog.pkg"
  info                  = "Version 2.5.0 - June 11 2024"
  category_id           = jamfpro_category.category_prerequisites.id
  package_file_source   = "https://github.com/swiftDialog/swiftDialog/releases/download/v2.5.0/dialog-2.5.0-4768.pkg"
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
resource "jamfpro_policy" "policy_install_dialog" {
  name                        = "${var.prefix}Install Dialog Tool"
  category_id                 = jamfpro_category.category_prerequisites.id
  enabled                     = true
  trigger_enrollment_complete = true
  trigger_checkin             = true
  trigger_other               = "@installDialog" // "USER_INITIATED" for self service trigger , "EVENT" for an event trigger
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
        id                          = jamfpro_package.package_dialog.id
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