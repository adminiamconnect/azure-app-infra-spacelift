
########################################
# OIDC App Config
########################################

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
# SAML APPLICATION
########################################

resource "azuread_group" "salesforceblink_users" {
  display_name     = "Salesforce Blink Users"
  security_enabled = true
}

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
resource "azuread_service_principal" "salesforce_blink" {
  application_id = azuread_application.salesforceblink_app.application_id
}
########################################
# SAML APPLICATION
########################################

resource "azuread_group" "Trello_users" {
  display_name     = "Trello Users"
  security_enabled = true
}

resource "azuread_application" "Trello_app" {
  display_name = "Trello"

  identifier_uris = [
    "https://trelloapp.iamconnect.co.uk"
  ]

  web {
    redirect_uris = [
      "https://salesforce.com/saml/acs"
    ]
  }

}
resource "azuread_service_principal" "trello_app" {
  application_id = azuread_application.trello_app.application_id
}

