# Copyright 2024, Jamf
variable "KeyName" {
  type        = string
  sensitive   = false
  default     = ""
  description = "AWS Keyname to attach to SaaS Tenancy instance. If blank, no SSH access will be possible"
}

variable "VPCId" {
  type        = string
  sensitive   = false
  default     = ""
  description = "AWS VPC to attach SaaS Tenancy Instance to."
}

variable "SubnetId" {
  type        = string
  sensitive   = false
  default     = ""
  description = "AWS SubnetID to attach SaaS Tenancy Instance to."
}

variable "CertificateBody" {
  type        = string
  sensitive   = false
  default     = ""
  description = "Provided Cert Body for TLS inspection. If not provided, self-signed will be generated"
}

variable "CertificatePrivateKey" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Provided Cert PrivateKey for TLS inspection. If not provided, self-signed will be generated"
}

variable "aws_region" {
  type        = string
  sensitive   = false
  default     = "us-west-2"
  description = "AWS region for SaaS tenancy instance"
}
