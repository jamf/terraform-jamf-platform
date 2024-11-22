# Copyright 2024, Jamf
## Define miscellaneous variables
variable "prefix" {
  type    = string
  default = "EJ - "
}

variable "support_files_path_prefix" {
  type    = string
  default = ""
}

# Variables
variable "KeyName" {
  description = "Name of an existing EC2 KeyPair to enable SSH access to the instance"
  type        = string
}
variable "InstanceType" {
  description = "EC2 instance type"
  type        = string
  default     = "t4g.micro"
}
variable "CertificateBody" {
  description = "The body of the SSL/TLS certificate base64 encoded (leave empty for self signed)"
  type        = string
}
variable "CertificatePrivateKey" {
  description = "The private key of the SSL/TLS certificate base64 encoded (leave empty for self signed)"
  type        = string
}
variable "Domain" {
  description = "internal domain to add to the header if multiple seperated by space"
  type        = string
  default     = "accounts.google.com"
}
variable "SaaSApplication" {
  description = "Choose which application to allow for the domain"
  type        = string
  default     = "Google"
}

variable "VPCId" {
  description = "VPC Id where the instance will be launched"
  type        = string
}
variable "SubnetId" {
  description = "Subnet Id where the instance will be launched"
  type        = string
}
