variable "app_name" {}
variable "identifier" {}
variable "reply_url" {}

resource "azuread_application" "this" {
  display_name = var.app_name

  web {
    redirect_uris = [var.reply_url]
  }

  identifier_uris = ["api://${var.app_name}"]
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
}
