# Copyright 2024, Jamf
resource "jsc_hostnamemapping" "saastenancy" {
  for_each  = toset(local.domain_array)
  hostname  = each.value
  a         = [aws_eip.ElasticIP.public_ip]
  securedns = true
}
