terraform {
  required_version = ">=1.7.4"
  required_providers {
    ovirt = {
      source  = "ovirt/ovirt"
      version = "2.1.5"
    }
  }
}

provider "ovirt" {
  tls_insecure = true
  mock         = false
  url          = var.url
  username     = var.username
  password     = var.password
}


