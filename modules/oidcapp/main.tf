variable "app_name" {}
variable "redirect_uris" {
  type = list(string)
}

resource "azuread_application" "this" {
  display_name = var.app_name

  web {
    redirect_uris = var.redirect_uris
  }
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
}
