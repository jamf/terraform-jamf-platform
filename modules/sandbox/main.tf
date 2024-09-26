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
resource "jamfpro_category" "test_category" {
  name     = "Sandbox"
  priority = 9
}

## Deploy demo policy
resource "jamfpro_policy" "test_policy" {
  name                        = "Test policy"
  enabled                     = true
  trigger_enrollment_complete = true
  frequency                   = "Once per computer"
  category_id                 = jamfpro_category.test_category.id

  scope {
    all_computers      = false
    computer_group_ids = [1]
  }

  payloads {
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