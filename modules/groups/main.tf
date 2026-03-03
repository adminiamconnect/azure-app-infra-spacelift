variable "group_name" {}

resource "azuread_group" "this" {
  display_name     = var.group_name
  security_enabled = true
}
