## Call Terraform provider
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = ">= 0.1.11"
    }
  }
}

module "microsoft_365" {
  source = "../management-app-installers-microsoft-365"
}

module "google_chrome" {
  source = "../management-app-installers-google-chrome"
}

module "mozilla_firefox" {
  source = "../management-app-installers-mozilla-firefox"
}

module "slack" {
  source = "../management-app-installers-slack"
}

module "dropbox" {
  source = "../management-app-installers-dropbox"
}

module "google_drive" {
  source = "../management-app-installers-google-drive"
}

module "jamf_composer" {
  source = "../management-app-installers-jamf-composer"
}

module "pppc_utility" {
  source = "../management-app-installers-pppc-utility"
}

module "jamfcheck" {
  source = "../management-app-installers-jamfcheck"
}

module "zoom" {
  source = "../management-app-installers-zoom"
}

module "include_microsoft_edge" {
  source = "../management-app-installers-microsoft-edge"
}

module "box_drive" {
  source = "../management-app-installers-box-drive"
}

module "nudge" {
  source = "../management-app-installers-nudge"
}

module "adobe_creative_cloud" {
  source = "../management-app-installers-adobe-creative-cloud"
}

module "text_expander" {
  source = "../management-app-installers-text-expander"
}
