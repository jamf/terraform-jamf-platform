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

resource "jamfpro_app_installer" "jamfcheck" {
  name            = "JamfCheck"
  enabled         = true
  deployment_type = "INSTALL_AUTOMATICALLY"
  update_behavior = "AUTOMATIC"
  category_id     = "-1"
  site_id         = "-1"
  smart_group_id  = "1"

  install_predefined_config_profiles = true
  trigger_admin_notifications        = true

  self_service_settings {
    include_in_featured_category   = true
    include_in_compliance_category = false
    force_view_description         = false
    description                    = ""
  }
}