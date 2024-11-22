# Copyright 2024, Jamf
## Call Terraform provider
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = ">= 0.1.5"
    }
  }
}

resource "jamfpro_app_installer" "firefox" {
  name            = "Mozilla Firefox"
  enabled         = true
  deployment_type = "INSTALL_AUTOMATICALLY"
  update_behavior = "AUTOMATIC"
  category_id     = "-1"
  site_id         = "-1"
  smart_group_id  = "1"

  install_predefined_config_profiles = true
  trigger_admin_notifications        = true

  notification_settings {
    notification_message  = "A new Firefox update is available"
    notification_interval = 1
    deadline_message      = "Update deadline approaching"
    deadline              = 1
    quit_delay            = 1
    complete_message      = "Update completed successfully"
    relaunch              = true
    suppress              = false
  }

  self_service_settings {
    include_in_featured_category   = true
    include_in_compliance_category = false
    force_view_description         = false
    description                    = "Firefox is allowed in our organization as an alternate browser."
  }
}