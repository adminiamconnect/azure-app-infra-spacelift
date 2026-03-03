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


########################################
# GROUP
########################################

resource "azuread_group" "salesforceblink_users" {
  display_name     = "Salesforce Blink Users"
  security_enabled = true
}

########################################
# SAML APPLICATION
########################################

resource "azuread_application" "salesforceblink_app" {
  display_name = "Salesforce Blink"

  identifier_uris = [
    "https://salesforce.iamconnect.co.uk"
  ]

  web {
    redirect_uris = [
      "https://salesforce.com/saml/acs"
    ]
  }
}

########################################
# ENTERPRISE APPLICATION (SERVICE PRINCIPAL)
########################################

resource "azuread_service_principal" "salesforce_sp" {
  client_id = azuread_application.salesforce_app.client_id
}

########################################
# ASSIGN GROUP TO APP
########################################

resource "azuread_app_role_assignment" "salesforce_group_assignment" {
  principal_object_id = azuread_group.salesforce_users.object_id
  resource_object_id  = azuread_service_principal.salesforce_sp.object_id
  app_role_id         = "00000000-0000-0000-0000-000000000000"
}
