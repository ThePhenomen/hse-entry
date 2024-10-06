locals {
  path_to_init = "init/data.yaml"
}

# data "ovirt_blank_template" "blank" {
# }

resource "ovirt_vm" "test_vm" {
  count                        = var.vms_count
  name                         = var.hostnames[count.index]
  initialization_hostname      = var.hostnames[count.index]
  comment                      = var.comment[count.index]
  clone                        = true
  cluster_id                   = var.cluster_id
  template_id                  = var.template_id
  memory                       = var.vm_ozu[count.index]
  maximum_memory               = var.vm_ozu[count.index]
  cpu_sockets                  = var.vm_cpu[count.index]
  cpu_cores                    = 1
  cpu_threads                  = 1
  initialization_custom_script = file(local.path_to_init)
}

resource "ovirt_vm_disks_resize" "resize_test" {
  count      = var.vms_count
  vm_id      = ovirt_vm.test_vm[count.index].id
  size       = var.vm_volume_size[count.index]
  depends_on = [ovirt_vm.test_vm]
}

resource "ovirt_nic" "net" {
  count           = var.vms_count
  name            = "nic1"
  vm_id           = ovirt_vm.test_vm[count.index].id
  vnic_profile_id = var.vnic_id
  depends_on      = [ovirt_vm.test_vm]
}

resource "ovirt_vm_start" "test" {
  count         = var.vms_count
  vm_id         = ovirt_vm.test_vm[count.index].id
  status        = "up"
  stop_behavior = "shutdown"
  force_stop    = true
  depends_on    = [ovirt_vm_disks_resize.resize_test, ovirt_nic.net]
}

data "ovirt_wait_for_ip" "vm_ip" {
  count      = var.vms_count
  vm_id      = ovirt_vm.test_vm[count.index].id
}

output "ipv4" {
  value = data.ovirt_wait_for_ip.vm_ip[*].interfaces.*.ipv4_addresses
}
