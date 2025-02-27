## Call Terraform provider
terraform {
  required_providers {
    jsc = {
      source  = "danjamf/jsctfprovider"
      version = ">= 0.0.15"
    }
  }
}

data "jsc_pag_vpnroutes" "vpn_route_nearest" {
  name = "Nearest Data Center"
}

data "jsc_pag_apptemplates" "ap_data_adobe" {
  name = "Adobe"
}

resource "jsc_pag_ztnaapp" "ap_adobe" {
  name                                             = "Adobe"
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
  apptemplateid                                    = data.jsc_pag_apptemplates.ap_data_adobe.id
}
