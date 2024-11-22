# Copyright 2024, Jamf
/*
This terraform blueprint will build the SaaS Tenancy Control vignette from Experience Jamf.
To do  -

Jamf Pro import cert

 Prerequisites:
  - 
*/

terraform {
  required_providers {
    jsc = {
      source  = "danjamf/jsctfprovider"
      version = ">= 0.0.15"
    }
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = ">= 0.1.9"
    }
    aws = {
    }
  }
}




variable "jsc_username" {
  description = "JSC username (email)"
  type        = string
}

variable "jsc_password" {
  description = "JSC password"
  type        = string
  sensitive   = true
}


variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}
