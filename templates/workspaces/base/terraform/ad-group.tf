resource "azuread_group" "workspace_pis" {
  display_name       = "TRE_ws${local.short_workspace_id}_PIs"
  owners             = [data.azuread_client_config.current.object_id]
  security_enabled   = true
  assignable_to_role = true
}
