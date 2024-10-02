# EJ-Terraform

Terraform configuration for the "Experience Jamf (EJ)" environment.

Provider versions used in this release:

- deploymenttheory/jamfpro > = v0.2.0
- danjamf/jsctfprovider >= v0.0.15
- hasicorp/aws v55.62.0 (optional with SaaS tenancy control)

This project utlizes the unoffical Terraform providers for [Jamf Pro](https://registry.terraform.io/providers/deploymenttheory/jamfpro/latest) and [Jamf Security Cloud](https://registry.terraform.io/providers/danjamf/jsctfprovider/latest)

## Prerequisites

While this project is private, you'll need to authenticate against GitHub to clone this repository. We advise you generate a Personal Access Token (PAT) in GitHub settings. Once done, you can follow the commands below.

## Project Initialization

Open a Terminal window and enter the following commands. Replace the following placeholders:

- [BRANCH-NAME]: The name of the branch to clone (main, danwork, vincent-work, etc)
- [PAT]: Your Personal Access Token (you may receive additional SSO login prompts upon first use)
- [FIRST.LAST]: Your local user directory

```
git clone -b [BRANCH-NAME] https://[PAT]@github.com/jamf/ExperienceJamf-Terraform.git /Users/[FIRST.LAST]/ExperienceJamf-Terraform/
cd /Users/[FIRST.LAST]/ExperienceJamf-Terraform
terraform init
```

## Parallelism and API delay

This project running a big amount of API commands to create a full Jamf Pro configuration, some testings indicate that lowering Terraform parallelism from 10 to 1 reduces the chances of API call errors. Run this command before applying your configuration

```
export TF_CLI_ARGS_apply="-parallelism=1"
```

We also recommend setting the `mandatory_request_delay_milliseconds`provider key to 100.

## Variables definition

This Terraform project requires Jamf API credentials and other context-specific variables that you'll need to define locally in a terraform.tfvars file.

```
cd /Users/[FIRST.LAST]/ExperienceJamf-Terraform
nano terraform.tfvars
```

Copy and paste the following data then customize it with your own credentials and set knobs to enable specific modules contained within this project. 

```
## Jamf Pro Account Details
jamfpro_instance_url  = ""
jamfpro_auth_method   = "" ## oauth2 or basic
jamfpro_client_id     = ""
jamfpro_client_secret = ""
jamfpro_username      = ""
jamfpro_password      = ""

## Jamf Protect Account Details
jamfprotect_url             = ""
jamfprotect_clientID        = ""
jamfprotect_client_password = ""

## Jamf Security Cloud (RADAR) Account Details
jsc_username            = ""
jsc_password            = ""
jsc_provided_idp_client = ""
tje_okta_clientid       = ""
tje_okta_orgdomain      = ""
block_page_logo         = ""
## block_page_logo takes a Base 64 encoded string conversion of the image only

### SaaS Tenancy
include_ej_saas_tenancy = false
VPCId                   = ""
KeyName                 = ""
SubnetId                = ""
aws_region              = ""

## Choose which Activation Profile option you want to output in your module
activation_profile_target = "macosplist"

# File path prefix for Terraform directory
support_files_path_prefix = "" ## Path to your directory - example: /Users/<youruser>/filename/

## Optional suffix
wizard_suffix = ""

## MODULE KNOBS
## Experience Jamf Knobs
include_ej_base                 = false
include_ej_incident_response    = false
include_ej_mac_cis_benchmark    = false
include_ej_mobile_cis_benchmark = false
include_ej_secure_remote_access = false
include_ej_jsc_config           = false

## Jamf Pro Knobs
include_jamfpro_demo_config     = false
include_jamfpro_prerequisites   = false

## App Installer Knobs
include_google_chrome   = true
include_mozilla_firefox = true
include_microsoft_teams = true
include_slack           = true
include_okta_verify     = true
include_swift_dialog    = true
include_dropbox         = true
include_google_drive    = true
include_jamf_composer   = true
include_jamf_connect    = true
include_pppc_utility    = true
include_jamfcheck       = true
include_nudge           = true
include_utm             = true
include_zoom            = true

## Jamf Protect Knobs
include_jamf_protect_for_macOS  = false

## Jamf Security Cloud Knobs
include_jsc_demo_config         = false
include_jsc_dp_only             = false
include_jsc_mtd_only            = false
include_jsc_all_services        = false
include_jsc_base                = false
include_jsc_ztna                = false
include_jsc_network_relay       = false
include_jsc_block_pages         = false
include_jsc_mtd_dp_only         = false
include_jsc_ztna_dp_only        = false
include_jsc_ztna_mtd_only       = false

## Misc Knobs
include_sandbox                 = false
include_onboarder_wizard        = false

```

Save and exit.

## Usage

Ensure that you are in the correct project folder when performing Terraform commands (e.g.: /Users/[FIRST.LAST]/ExperienceJamf-Terraform/)

Enter the following command to apply full Terraform config:

```
terraform apply
```

Enter this command to only apply specific modules:

```
terraform apply -target "module.[MODULE_NAME]"
```

N.b. by default all modules will be applied. You can unselect individual modules by modifing the module knobs in your tfvars file e.g.

```
include_ej_mac_cis_benchmark = false
```

## Modules

Each module can be applied individually to test EJ vignettes:

- module.ej_base
- module.ej_incident_response
- module.ej_mac_cis_benchmark
- module.ej_mobile_cis_benchmark
- module.ej_secure_remote_access

Other modules are also available for more general purpose:

- module.jamfpro_demo_config
- module.jsc_demo_config

Want to experiment with your own config? Use this module:

- module.sandbox
