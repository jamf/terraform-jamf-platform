/*
This terraform blueprint will build automated Filevault 2 enforcement and reissuing recovery key Self Service Policy
It will do the following:
 - Create 1 category
 - Create 1 scripts
 - Create 2 smart computer groups
 - Create 1 policies
 - Create 1 configuration profiles

 Prerequisites:
  - the Dialog tool must be installed
*/

## Call Terraform provider
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = "~> 0.3.1"
    }
  }
}

## Create Admin Facing Categories
resource "jamfpro_category" "category_disk_encrpytion" {
  name     = "${var.prefix}Disk Encryption"
  priority = 9
}

resource "jamfpro_category" "category_admin_tools" {
  name     = "${var.prefix}Sysadmin Tools"
  priority = 9
}

## Create End User Facing Categories
resource "jamfpro_category" "category_microsoft_365" {
  name     = "${var.prefix}Microsoft 365 Apps"
  priority = 9
}

resource "jamfpro_category" "category_browsers" {
  name     = "${var.prefix}Browsers"
  priority = 9
}

resource "jamfpro_category" "category_collaboration" {
  name     = "${var.prefix}Collaboration"
  priority = 9
}

##Computer Inventory Collection Settings
resource "jamfpro_computer_inventory_collection" "example" {
  local_user_accounts               = true
  home_directory_sizes              = true
  hidden_accounts                   = true
  printers                          = true
  active_services                   = true
  mobile_device_app_purchasing_info = true
  computer_location_information     = true
  package_receipts                  = true
  available_software_updates        = true
  include_applications              = true
  include_fonts                     = true
  include_plugins                   = true
  
  applications {
    path     = "/Applications/ExampleApp.app"
    platform = "macOS"
  }

  applications {
    path     = "/Applications/AnotherApp.app"
    platform = "macOS"
  }

  fonts {
    path     = "/Library/Fonts/ExampleFont.ttf"
    platform = "macOS"
  }

  fonts {
    path     = "/Library/Fonts/AnotherFont.ttf"
    platform = "macOS"
  }

  plugins {
    path     = "/Library/Internet Plug-Ins/ExamplePlugin.plugin"
    platform = "macOS"
  }

  plugins {
    path     = "/Library/Internet Plug-Ins/AnotherPlugin.plugin"
    platform = "macOS"
  }
}

##Computer Check-in Settings
resource "jamfpro_computer_checkin" "jamfpro_computer_checkin" {
   check_in_frequency                 = 15
   create_startup_script              = true   
   log_startup_event                  = true 
   ensure_ssh_is_enabled              = false 
   check_for_policies_at_startup      = true 
   create_login_logout_hooks          = true  
   log_username                       = true 
   check_for_policies_at_login_logout = true
}

## Create scripts
resource "jamfpro_script" "script_reissuekey" {
  name            = "${var.prefix}Reissue Filevault 2 Key"
  priority        = "AFTER"
  script_contents = file("${var.support_files_path_prefix}support_files/computer_scripts/reissuekey.sh")
  category_id     = jamfpro_category.category_disk_encrpytion.id
  info            = "Source: https://github.com/jamf/FileVault2_Scripts/blob/master/reissueKey.sh"
}

resource "jamfpro_script" "script_rename_mac_current_user" {
  name            = "${var.prefix}Rename Computer - Current User"
  priority        = "AFTER"
  script_contents = file("${var.support_files_path_prefix}support_files/computer_scripts/rename_computer_loggedin_user.sh")
  category_id     = jamfpro_category.category_admin_tools.id
  info            = "Source: https://community.jamf.com/t5/jamf-pro/trying-to-find-the-best-way-to-rename-computers-after-enrollment/m-p/246823"
}

## Create Smart Computer Groups - Quality Of Life
resource "jamfpro_smart_computer_group" "group_sonoma_computers" {
  name = "${var.prefix}CIS - Sonoma Macs"
  criteria {
    name        = "Operating System Version"
    search_type = "like"
    value       = "14."
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_sequoia_computers" {
  name = "${var.prefix}CIS - Sequoia Macs"
  criteria {
    name        = "Operating System Version"
    search_type = "like"
    value       = "15."
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_last_checkin" {
  name = "${var.prefix}30+ Days Since Last Check-In"
  criteria {
    name        = "Last Check-in"
    search_type = "more than x days ago"
    value       = "30"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_disk_encrypted" {
  name = "${var.prefix}FileVault 2 Enabled"
  criteria {
    name        = "FileVault 2 Partition Encryption State"
    search_type = "is"
    value       = "Encrypted"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_available_swu" {
  name = "${var.prefix}Available Software Updates"
  criteria {
    name        = "Number of Available Updates"
    search_type = "more than"
    value       = "0"
    and_or      = "and"
    priority    = 0
  }
}

## Create Smart Computer Groups - Scoping
resource "jamfpro_smart_computer_group" "group_invalid_recovery_key" {
  name = "${var.prefix}Invalid Filevault 2 Recovery Key"
  criteria {
    name        = "FileVault 2 Partition Encryption State"
    search_type = "is"
    value       = "Encrypted"
    and_or      = "and"
    priority    = 0
  }
  criteria {
    name        = "FileVault 2 Individual Key Validation"
    search_type = "is not"
    value       = "valid"
    and_or      = "and"
    priority    = 1
  }
  criteria {
    name        = "Last Check-in"
    search_type = "more than x days ago"
    value       = "30"
    and_or      = "and"
    priority    = 2
  }
}

resource "jamfpro_smart_computer_group" "group_msft_word" {
  name = "${var.prefix}Auto Update Microsoft Word"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Microsoft Word"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_msft_excel" {
  name = "${var.prefix}Auto Update Microsoft Excel"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Microsoft Excel"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_msft_onedrive" {
  name = "${var.prefix}Auto Update Microsoft OneDrive"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Microsoft Onedrive"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_msft_onenote" {
  name = "${var.prefix}Auto Update Microsoft OneNote"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Microsoft Onenote"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_msft_outlook" {
  name = "${var.prefix}Auto Update Microsoft Outlook"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Microsoft Outlook"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_msft_powerpoint" {
  name = "${var.prefix}Auto Update Microsoft PowerPoint"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Microsoft Powerpoint"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_msft_remote_desktop" {
  name = "${var.prefix}Auto Update Microsoft Remote Desktop 10"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Microsoft Remote Desktop"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_msft_edge" {
  name = "${var.prefix}Auto Update Microsoft Edge"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Microsoft Edge"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_brave_browser" {
  name = "Auto Update Brave Browser"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Brave Browser"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_google_chrome" {
  name = "Auto Update Google Chrome"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Google Chrome"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_mozilla_firefox" {
  name = "Auto Update Mozilla Firefox"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Mozilla Firefox"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_installer_slack" {
  name = "Auto Update Slack"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Slack"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_msft_teams" {
  name = "Auto Update Microsoft Teams"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Microsoft Teams"
    and_or      = "and"
    priority    = 0
  }
}

resource "jamfpro_smart_computer_group" "group_zoom_us" {
  name = "Auto Update Zoom"
  criteria {
    name        = "Application Title"
    search_type = "like"
    value       = "Zoom.us"
    and_or      = "and"
    priority    = 0
  }
}

## App Installers - Microsoft 365 Applications
resource "jamfpro_app_installer" "jamfpro_app_installer_microsoft_edge_365" {
  name            = "Microsoft Edge"
  enabled         = true
  deployment_type = "SELF_SERVICE"
   update_behavior = "AUTOMATIC"
   category_id     = jamfpro_category.category_browsers.id
   site_id         = "-1"
   smart_group_id  = jamfpro_smart_computer_group.group_msft_edge.id

   install_predefined_config_profiles = false
   trigger_admin_notifications        = false

   notification_settings {
     notification_message  = "A new update is available"
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
     include_in_compliance_category = true
     force_view_description         = true
     description                    = "This is an example app deployment"

     categories {
       id       = jamfpro_category.category_browsers.id
       featured = true
     }
   }
 }

resource "jamfpro_app_installer" "jamfpro_app_installer_microsoft_remote_desktop_365" {
  name            = "Microsoft Remote Desktop 10"
  enabled         = true
  deployment_type = "SELF_SERVICE"
   update_behavior = "AUTOMATIC"
   category_id     = jamfpro_category.category_admin_tools.id
   site_id         = "-1"
   smart_group_id  = jamfpro_smart_computer_group.group_msft_remote_desktop.id

   install_predefined_config_profiles = false
   trigger_admin_notifications        = false

   notification_settings {
     notification_message  = "A new update is available"
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
     include_in_compliance_category = true
     force_view_description         = true
     description                    = "This is an example app deployment"

     categories {
       id       = jamfpro_category.category_admin_tools.id
       featured = true
     }
   }
 }

resource "jamfpro_app_installer" "jamfpro_app_installer_microsoft_powerpoint_365" {
  name            = "Microsoft PowerPoint 365"
  enabled         = true
  deployment_type = "SELF_SERVICE"
   update_behavior = "AUTOMATIC"
   category_id     = jamfpro_category.category_microsoft_365.id
   site_id         = "-1"
   smart_group_id  = jamfpro_smart_computer_group.group_msft_powerpoint.id

   install_predefined_config_profiles = false
   trigger_admin_notifications        = false

   notification_settings {
     notification_message  = "A new update is available"
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
     include_in_compliance_category = true
     force_view_description         = true
     description                    = "This is an example app deployment"

     categories {
       id       = jamfpro_category.category_microsoft_365.id
       featured = true
     }
   }
 }

resource "jamfpro_app_installer" "jamfpro_app_installer_microsoft_outlook_365" {
  name            = "Microsoft Outlook 365"
  enabled         = true
  deployment_type = "SELF_SERVICE"
   update_behavior = "AUTOMATIC"
   category_id     = jamfpro_category.category_microsoft_365.id
   site_id         = "-1"
   smart_group_id  = jamfpro_smart_computer_group.group_msft_outlook.id

   install_predefined_config_profiles = false
   trigger_admin_notifications        = false

   notification_settings {
     notification_message  = "A new update is available"
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
     include_in_compliance_category = true
     force_view_description         = true
     description                    = "This is an example app deployment"

     categories {
       id       = jamfpro_category.category_microsoft_365.id
       featured = true
     }
   }
 }

resource "jamfpro_app_installer" "jamfpro_app_installer_microsoft_onenote_365" {
  name            = "Microsoft OneNote 365"
  enabled         = true
  deployment_type = "SELF_SERVICE"
   update_behavior = "AUTOMATIC"
   category_id     = jamfpro_category.category_microsoft_365.id
   site_id         = "-1"
   smart_group_id  = jamfpro_smart_computer_group.group_msft_onenote.id

   install_predefined_config_profiles = false
   trigger_admin_notifications        = false

   notification_settings {
     notification_message  = "A new update is available"
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
     include_in_compliance_category = true
     force_view_description         = true
     description                    = "This is an example app deployment"

     categories {
       id       = jamfpro_category.category_microsoft_365.id
       featured = true
     }
   }
 }

resource "jamfpro_app_installer" "jamfpro_app_installer_microsoft_onedrive_365" {
  name            = "Microsoft OneDrive"
  enabled         = true
  deployment_type = "SELF_SERVICE"
   update_behavior = "AUTOMATIC"
   category_id     = jamfpro_category.category_microsoft_365.id
   site_id         = "-1"
   smart_group_id  = jamfpro_smart_computer_group.group_msft_onedrive.id

   install_predefined_config_profiles = false
   trigger_admin_notifications        = false

   notification_settings {
     notification_message  = "A new update is available"
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
     include_in_compliance_category = true
     force_view_description         = true
     description                    = "This is an example app deployment"

     categories {
       id       = jamfpro_category.category_microsoft_365.id
       featured = true
     }
   }
 }

resource "jamfpro_app_installer" "jamfpro_app_installer_microsoft_word_365" {
  name                = "Microsoft Word 365"
  enabled             = true
  deployment_type     = "SELF_SERVICE"
  update_behavior     = "AUTOMATIC"
  category_id         = jamfpro_category.category_microsoft_365.id
  site_id             = "-1"
  smart_group_id      = jamfpro_smart_computer_group.group_msft_word.id

  install_predefined_config_profiles = false
  trigger_admin_notifications        = false

  notification_settings {
    notification_message  = "A new update is available"
    notification_interval = 1
    deadline_message      = "Update deadline approaching"
    deadline              = 1
    quit_delay            = 1
    complete_message      = "Update completed successfully"
    relaunch              = true
    suppress              = false
  }

  self_service_settings {
    include_in_featured_category    = true
    include_in_compliance_category  = true
    force_view_description          = true
    description                     = "This is an example app deployment"

    categories {
      id       = jamfpro_category.category_microsoft_365.id
      featured = true
    }
  }
}

## App Installers - Browsers
resource "jamfpro_app_installer" "jamfpro_app_installer_brave_browser" {
  name                = "Brave Browser"
  enabled             = true
  deployment_type     = "SELF_SERVICE"
  update_behavior     = "AUTOMATIC"
  category_id         = jamfpro_category.category_browsers.id
  site_id             = "-1"
  smart_group_id      = jamfpro_smart_computer_group.group_brave_browser.id

  install_predefined_config_profiles = false
  trigger_admin_notifications        = false

  notification_settings {
    notification_message  = "A new update is available"
    notification_interval = 1
    deadline_message      = "Update deadline approaching"
    deadline              = 1
    quit_delay            = 1
    complete_message      = "Update completed successfully"
    relaunch              = true
    suppress              = false
  }

  self_service_settings {
    include_in_featured_category    = true
    include_in_compliance_category  = true
    force_view_description          = true
    description                     = "This is an example app deployment"

    categories {
      id       = jamfpro_category.category_browsers.id
      featured = true
    }
  }
}

resource "jamfpro_app_installer" "jamfpro_app_installer_google_chrome" {
  name                = "Google Chrome"
  enabled             = true
  deployment_type     = "SELF_SERVICE"
  update_behavior     = "AUTOMATIC"
  category_id         = jamfpro_category.category_browsers.id
  site_id             = "-1"
  smart_group_id      = jamfpro_smart_computer_group.group_google_chrome.id

  install_predefined_config_profiles = false
  trigger_admin_notifications        = false

  notification_settings {
    notification_message  = "A new update is available"
    notification_interval = 1
    deadline_message      = "Update deadline approaching"
    deadline              = 1
    quit_delay            = 1
    complete_message      = "Update completed successfully"
    relaunch              = true
    suppress              = false
  }

  self_service_settings {
    include_in_featured_category    = true
    include_in_compliance_category  = true
    force_view_description          = true
    description                     = "This is an example app deployment"

    categories {
      id       = jamfpro_category.category_browsers.id
      featured = true
    }
  }
}

resource "jamfpro_app_installer" "jamfpro_app_installer_mozilla_firefox" {
  name                = "Mozilla Firefox"
  enabled             = true
  deployment_type     = "SELF_SERVICE"
  update_behavior     = "AUTOMATIC"
  category_id         = jamfpro_category.category_browsers.id
  site_id             = "-1"
  smart_group_id      = jamfpro_smart_computer_group.group_mozilla_firefox.id

  install_predefined_config_profiles = false
  trigger_admin_notifications        = false

  notification_settings {
    notification_message  = "A new update is available"
    notification_interval = 1
    deadline_message      = "Update deadline approaching"
    deadline              = 1
    quit_delay            = 1
    complete_message      = "Update completed successfully"
    relaunch              = true
    suppress              = false
  }

  self_service_settings {
    include_in_featured_category    = true
    include_in_compliance_category  = true
    force_view_description          = true
    description                     = "This is an example app deployment"

    categories {
      id       = jamfpro_category.category_browsers.id
      featured = true
    }
  }
}

##Appinstallers - Collaboration
resource "jamfpro_app_installer" "jamfpro_app_installer_installer_slack" {
  name                = "Slack"
  enabled             = true
  deployment_type     = "SELF_SERVICE"
  update_behavior     = "AUTOMATIC"
  category_id         = jamfpro_category.category_collaboration.id
  site_id             = "-1"
  smart_group_id      = jamfpro_smart_computer_group.group_installer_slack.id

  install_predefined_config_profiles = false
  trigger_admin_notifications        = false

  notification_settings {
    notification_message  = "A new update is available"
    notification_interval = 1
    deadline_message      = "Update deadline approaching"
    deadline              = 1
    quit_delay            = 1
    complete_message      = "Update completed successfully"
    relaunch              = true
    suppress              = false
  }

  self_service_settings {
    include_in_featured_category    = true
    include_in_compliance_category  = true
    force_view_description          = true
    description                     = "This is an example app deployment"

    categories {
      id       = jamfpro_category.category_collaboration.id
      featured = true
    }
  }
}

resource "jamfpro_app_installer" "jamfpro_app_installer_msft_teams" {
  name                = "Microsoft Teams"
  enabled             = true
  deployment_type     = "SELF_SERVICE"
  update_behavior     = "AUTOMATIC"
  category_id         = jamfpro_category.category_collaboration.id
  site_id             = "-1"
  smart_group_id      = jamfpro_smart_computer_group.group_msft_teams.id

  install_predefined_config_profiles = false
  trigger_admin_notifications        = false

  notification_settings {
    notification_message  = "A new update is available"
    notification_interval = 1
    deadline_message      = "Update deadline approaching"
    deadline              = 1
    quit_delay            = 1
    complete_message      = "Update completed successfully"
    relaunch              = true
    suppress              = false
  }

  self_service_settings {
    include_in_featured_category    = true
    include_in_compliance_category  = true
    force_view_description          = true
    description                     = "This is an example app deployment"

    categories {
      id       = jamfpro_category.category_collaboration.id
      featured = true
    }
  }
}

resource "jamfpro_app_installer" "jamfpro_app_zoom_us" {
  name                = "Zoom Client for Meetings"
  enabled             = true
  deployment_type     = "SELF_SERVICE"
  update_behavior     = "AUTOMATIC"
  category_id         = jamfpro_category.category_collaboration.id
  site_id             = "-1"
  smart_group_id      = jamfpro_smart_computer_group.group_zoom_us.id

  install_predefined_config_profiles = false
  trigger_admin_notifications        = false

  notification_settings {
    notification_message  = "A new update is available"
    notification_interval = 1
    deadline_message      = "Update deadline approaching"
    deadline              = 1
    quit_delay            = 1
    complete_message      = "Update completed successfully"
    relaunch              = true
    suppress              = false
  }

  self_service_settings {
    include_in_featured_category    = true
    include_in_compliance_category  = true
    force_view_description          = true
    description                     = "This is an example app deployment"

    categories {
      id       = jamfpro_category.category_collaboration.id
      featured = true
    }
  }
}

## Create policies
resource "jamfpro_policy" "policy_reissue_recovery_key" {
  name          = "${var.prefix}Reissue Filevault 2 Recovery Key"
  enabled       = true
  trigger_other = ""
  frequency     = "Ongoing"
  category_id   = jamfpro_category.category_disk_encrpytion.id
  

  scope {
    all_computers      = false
    computer_group_ids = [jamfpro_smart_computer_group.group_invalid_recovery_key.id]
  }

  self_service {
    use_for_self_service            = true
    self_service_display_name       = "Get New Recovery Key"
    install_button_text             = "Fix Now"
    self_service_description        = ""
    force_users_to_view_description = false
    feature_on_main_page            = true
  }

  payloads {
    scripts {
      id = jamfpro_script.script_reissuekey.id
      priority    = "After"
      parameter4  = "<Replace with your organization name>"
      parameter5  = ""
      parameter6  = "<replace with additional info for the end user>"
    }

   maintenance {
      recon                       = true
      reset_name                  = false
      install_all_cached_packages = false
      heal                        = false
      prebindings                 = false
      permissions                 = false
      byhost                      = false
      system_cache                = false
      user_cache                  = false
      verify                      = false
    }
  }
}

resource "jamfpro_policy" "policy_rename_computer_currentuser" {
  name          = "${var.prefix}Rename Computer: Current User"
  enabled       = true
  trigger_other = ""
  frequency     = "Once per computer"
  category_id   = jamfpro_category.category_admin_tools.id
  

  scope {
    all_computers      = true
  }

  self_service {
    use_for_self_service            = true
    self_service_display_name       = "Rename Computer To Reflect User and Hardware Model"
    install_button_text             = "Try it out"
    self_service_description        = "This Self Service policy will rename your Mac to CurrentUser-Hardwaremodel"
    force_users_to_view_description = true
    feature_on_main_page            = true
  }

  payloads {
    scripts {
      id = jamfpro_script.script_rename_mac_current_user.id
      priority    = "After"
      parameter4  = ""
      parameter5  = ""
      parameter6  = ""
    }
  }
}

resource "jamfpro_macos_configuration_profile_plist" "jamfpro_macos_configuration_profile_enablefv" {
  name                = "Enable Filevault 2"
  description         = "This configuration profile enforces Filevault 2 encryption. Prompts at next login"
  level               = "System"
  category_id         = jamfpro_category.category_disk_encrpytion.id
  redeploy_on_update  = "Newly Assigned"
  distribution_method = "Install Automatically"
  payloads            = file("${var.support_files_path_prefix}support_files/computer_config_profiles/enablefilevault.mobileconfig")
  payload_validate    = false
  user_removable      = false

  scope {
    all_computers = true
    all_jss_users = false
  }
}
