# Copyright 2024, Jamf
resource "jamfpro_site" "site_production" {
  name = "Production"
}

resource "jamfpro_site" "site_staging" {
  name = "Staging"
}

resource "jamfpro_site" "site_sandbox" {
  name = "Sandbox"
}