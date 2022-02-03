locals {
  short_service_id               = substr(var.tre_resource_id, -4, -1)
  short_workspace_id             = substr(var.workspace_id, -4, -1)
  short_parent_id                = substr(var.parent_service_id, -4, -1)
  workspace_resource_name_suffix = "${var.tre_id}-ws-${local.short_workspace_id}"
  service_resource_name_suffix   = "${var.tre_id}-ws-${local.short_workspace_id}-svc-${local.short_service_id}"
  core_vnet                      = "vnet-${var.tre_id}"
  core_resource_group_name       = "rg-${var.tre_id}"
  vm_name                        = "ubuntuvm${local.short_service_id}"
  keyvault_name                  = lower("kv-${substr(local.workspace_resource_name_suffix, -20, -1)}")
  image_ref = {
    "Ubuntu 18.04" = {
      "publisher" = "Canonical"
      "offer"     = "UbuntuServer"
      "sku"       = "18_04-lts-gen2"
      "version"   = "latest"
    },
    "Ubuntu 18.04 Data Science VM" = {
      "publisher" = "microsoft-dsvm"
      "offer"     = "ubuntu-1804"
      "sku"       = "1804-gen2"
      "version"   = "latest"
    }
  }
}
