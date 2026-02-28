module "app_service" {
  source              = "../../modules/app-service"
  app_name            = "dev-myapp"
  location            = "UK South"
  resource_group_name = "rg-dev-myapp"
}
