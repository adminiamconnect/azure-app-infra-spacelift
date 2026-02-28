resource "azuread_group" "salesforce_users" {
  display_name     = "Salesforce Global Users"
  security_enabled = true
}

resource "azuread_application" "salesforce_app" {
  display_name = "Salesforce Global"
}

resource "azuread_service_principal" "salesforce_sp" {
  application_id = azuread_application.salesforce_app.application_id
}
