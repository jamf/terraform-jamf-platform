# EJ-Terraform - Local macOS Account Management (LMAM) Vignette

Terraform vignette for the "Experience Jamf (EJ)" environment. This vignette deploys all components needed for the Jamf Connect focussed vignette.

Provider versions used in this release:

- deploymenttheory/jamfpro v0.1.5


## Prerequisites

The Dialog tool must be already deployed on computers to display some dialogs related to this vignette

## Deploy this module

Create a terraform.tfvars in the root folder and set the following knob to true:

```
include_ej_mac_LMAM = true
```

Then run the following commands:

```
terraform init
terraform plan
terraform apply
```