resource "azuread_group" "salesforce_users" {
  display_name     = "Salesforce Global Users"
  security_enabled = true
}

resource "azuread_application" "salesforce_app" {
  display_name = "Salesforce Global"
}

  web {
    redirect_uris = [
      "https://login.salesforce.com",
      "https://mydomain.my.salesforce.com"
    ]
  }

resource "azuread_service_principal" "salesforce_sp" {
  application_id = azuread_application.salesforce_app.application_id
}
