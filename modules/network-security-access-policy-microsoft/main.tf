## Call Terraform provider
terraform {
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = ">= 0.1.5"
    }
    jsc = {
      source  = "danjamf/jsctfprovider"
      version = ">= 0.0.15"
    }
  }
}

data "jsc_pag_vpnroutes" "vpn_route_nearest" {
  name = "Nearest Data Center"
}

data "jsc_pag_apptemplates" "ap_data_ms365" {
  name = "Microsoft 365"
}

resource "jsc_pag_ztnaapp" "ap_ms365" {
  name                                             = "Microsoft 365"
  routingtype                                      = "CUSTOM"
  routingid                                        = data.jsc_pag_vpnroutes.vpn_route_nearest.id
  routingdnstype                                   = "IPv6"
  categoryname                                     = "Productivity"
  securityriskcontrolenabled                       = true
  securityriskcontrolthreshold                     = "HIGH"
  securityriskcontrolnotifications                 = true
  securitydohintegrationblocking                   = true
  securitydohintegrationnotifications              = true
  securitydevicemanagementbasedaccessenabled       = true
  securitydevicemanagementbasedaccessnotifications = true
  assignmentallusers                               = true
  apptemplateid                                    = data.jsc_pag_apptemplates.ap_data_ms365.id
}

data "jsc_pag_apptemplates" "ap_data_ms_auth" {
  name = "Microsoft Authentication"
}

resource "jsc_pag_ztnaapp" "ap_ms_auth" {
  name                                             = "Microsoft Authentication"
  routingtype                                      = "CUSTOM"
  routingid                                        = data.jsc_pag_vpnroutes.vpn_route_nearest.id
  routingdnstype                                   = "IPv6"
  categoryname                                     = "Productivity"
  securityriskcontrolenabled                       = true
  securityriskcontrolthreshold                     = "HIGH"
  securityriskcontrolnotifications                 = true
  securitydohintegrationblocking                   = true
  securitydohintegrationnotifications              = true
  securitydevicemanagementbasedaccessenabled       = true
  securitydevicemanagementbasedaccessnotifications = true
  assignmentallusers                               = true
  apptemplateid                                    = data.jsc_pag_apptemplates.ap_data_ms_auth.id
  depends_on                                       = [jsc_pag_ztnaapp.ap_ms365]
}

data "jsc_pag_apptemplates" "ap_data_ms_endpoint_manager" {
  name = "Microsoft Endpoint Manager"
}

resource "jsc_pag_ztnaapp" "ap_ms_endpoint_manager" {
  name                                             = "Microsoft Endpoint Manager"
  routingtype                                      = "CUSTOM"
  routingid                                        = data.jsc_pag_vpnroutes.vpn_route_nearest.id
  routingdnstype                                   = "IPv6"
  categoryname                                     = "Productivity"
  securityriskcontrolenabled                       = true
  securityriskcontrolthreshold                     = "HIGH"
  securityriskcontrolnotifications                 = true
  securitydohintegrationblocking                   = true
  securitydohintegrationnotifications              = true
  securitydevicemanagementbasedaccessenabled       = true
  securitydevicemanagementbasedaccessnotifications = true
  assignmentallusers                               = true
  apptemplateid                                    = data.jsc_pag_apptemplates.ap_data_ms_endpoint_manager.id
  depends_on                                       = [jsc_pag_ztnaapp.ap_ms_auth]
}

data "jsc_pag_apptemplates" "ap_data_ms_one_drive" {
  name = "Microsoft OneDrive"
}

resource "jsc_pag_ztnaapp" "ap_ms_one_drive" {
  name                                             = "Microsoft One Drive"
  routingtype                                      = "CUSTOM"
  routingid                                        = data.jsc_pag_vpnroutes.vpn_route_nearest.id
  routingdnstype                                   = "IPv6"
  categoryname                                     = "Productivity"
  securityriskcontrolenabled                       = true
  securityriskcontrolthreshold                     = "HIGH"
  securityriskcontrolnotifications                 = true
  securitydohintegrationblocking                   = true
  securitydohintegrationnotifications              = true
  securitydevicemanagementbasedaccessenabled       = true
  securitydevicemanagementbasedaccessnotifications = true
  assignmentallusers                               = true
  apptemplateid                                    = data.jsc_pag_apptemplates.ap_data_ms_one_drive.id
  depends_on                                       = [jsc_pag_ztnaapp.ap_ms_endpoint_manager]
}

data "jsc_pag_apptemplates" "ap_data_ms_outlook" {
  name = "Microsoft Outlook"
}

resource "jsc_pag_ztnaapp" "ap_ms_outlook" {
  name                                             = "Microsoft Outlook"
  routingtype                                      = "CUSTOM"
  routingid                                        = data.jsc_pag_vpnroutes.vpn_route_nearest.id
  routingdnstype                                   = "IPv6"
  categoryname                                     = "Productivity"
  securityriskcontrolenabled                       = true
  securityriskcontrolthreshold                     = "HIGH"
  securityriskcontrolnotifications                 = true
  securitydohintegrationblocking                   = true
  securitydohintegrationnotifications              = true
  securitydevicemanagementbasedaccessenabled       = true
  securitydevicemanagementbasedaccessnotifications = true
  assignmentallusers                               = true
  apptemplateid                                    = data.jsc_pag_apptemplates.ap_data_ms_outlook.id
  depends_on                                       = [jsc_pag_ztnaapp.ap_ms_one_drive]
}

data "jsc_pag_apptemplates" "ap_data_ms_teams" {
  name = "Microsoft Teams"
}

resource "jsc_pag_ztnaapp" "ap_ms_teams" {
  name                                             = "Microsoft Teams"
  routingtype                                      = "CUSTOM"
  routingid                                        = data.jsc_pag_vpnroutes.vpn_route_nearest.id
  routingdnstype                                   = "IPv6"
  categoryname                                     = "Productivity"
  securityriskcontrolenabled                       = true
  securityriskcontrolthreshold                     = "HIGH"
  securityriskcontrolnotifications                 = true
  securitydohintegrationblocking                   = true
  securitydohintegrationnotifications              = true
  securitydevicemanagementbasedaccessenabled       = true
  securitydevicemanagementbasedaccessnotifications = true
  assignmentallusers                               = true
  apptemplateid                                    = data.jsc_pag_apptemplates.ap_data_ms_teams.id
  depends_on                                       = [jsc_pag_ztnaapp.ap_ms_outlook]
}
