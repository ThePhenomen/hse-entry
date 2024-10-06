variable "username" {
  description = "Username for Ovirt, sensitive data"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^.*?@internal", var.username))
    error_message = "Missing @internal in provided username for Ovirt"
  }
}

variable "password" {
  description = "Username's password for Ovirt, sensitive data"
  type        = string
  sensitive   = true
}

variable "url" {
  description = "Ovirt Url"
  type        = string
  validation {
    condition     = can(regex("^https:.*?api?", var.url))
    error_message = "Incorrect Ovirt api url, must be https://<fqdn>/api/"
  }
}

variable "cluster_id" {
  description = "Cluster id in Ovirt for VM"
  type        = string
}

variable "template_id" {
  description = "Template id for VM in selected cluster"
  type        = string
}

variable "vnic_id" {
  description = "Vnic id profile in Ovirt, get from python"
  type        = string
}

variable "hostnames" {
  description = "Virtual machine hostname"
  type        = list(string)
  default     = ["test01.example.com"]
}

variable "vms_count" {
  description = "Number of virtual machines to create"
  type        = number
  default     = 1
}

variable "vm_volume_size" {
  description = "Volume size for VM disks"
  type        = list(number)
  default     = [64]
}

variable "vm_cpu" {
  description = "VM CPU amount"
  type        = list(number)
  default     = [4]
}

variable "vm_ozu" {
  description = "VM OZU amount"
  type        = list(number)
  default     = [8]
}

variable "comment" {
  description = "VM comment for zvirt"
  type        = list(string)
  default     = ["VM for test"]
}