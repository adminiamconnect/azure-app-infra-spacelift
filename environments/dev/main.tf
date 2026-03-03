#################################
# GROUP
#################################

resource "azuread_group" "salesforce_users" {
  display_name     = "Salesforce Global Users"
  security_enabled = true
}

#################################
# OIDC APP
#################################

module "salesforce_oidc_app" {
  source = "../../modules/oidcapp"

  app_name      = "Salesforce OIDC"
  redirect_uris = ["https://salesforce.com/oauth/callback"]
}

#################################
# SAML APP
#################################

module "salesforce_saml_app" {
  source    = "../../modules/samlapp"
  app_name  = "salesforce-saml"
  reply_url = "https://salesforce.com/saml/acs"
}
