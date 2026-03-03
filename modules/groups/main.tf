module "salesforce_group" {
  source     = "../../modules/groups"
  group_name = "Salesforce Global Users"
}

module "salesforce_saml_app" {
  source   = "../../modules/saml-app"
  app_name = "Salesforce"
}
