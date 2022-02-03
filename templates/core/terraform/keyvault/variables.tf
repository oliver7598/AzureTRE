variable "tre_id" {}
variable "location" {}
variable "resource_group_name" {}
variable "core_vnet" {}
variable "shared_subnet" {}
variable "tenant_id" {}
variable "managed_identity_tenant_id" {}
variable "managed_identity_object_id" {}

variable "debug" {
  type        = bool
  default     = false
  description = "Whether to turn off Purge Protection"
}
