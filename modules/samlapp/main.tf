variable "app_name" {
  type = string
}

data "azuread_application_template" "template" {
  display_name = var.app_name
}

resource "azuread_service_principal" "saml_sp" {
  application_template_id = data.azuread_application_template.template.template_id
  display_name            = var.app_name
}

output "service_principal_id" {
  value = azuread_service_principal.saml_sp.object_id
}
