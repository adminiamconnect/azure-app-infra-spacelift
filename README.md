0) Prereqs

You have:

Azure subscription + Entra tenant

A Spacelift org + space

A GitHub repo with OpenTofu code

Versions (sane defaults):

OpenTofu >= 1.5

hashicorp/azurerm ~> 3.x

hashicorp/azuread ~> 2.47 (or similar)

1) Repo structure in GitHub

Example layout (matches what you showed):

azure-app-infra-spacelift/
  environments/
    dev/
      main.tf
      providers.tf
      versions.tf (optional)
  modules/
    app-service/
      main.tf
      variables.tf

Commit all config. Spacelift runs from the repo.

2) Create Spacelift Stack (GitHub → Stack)

Spacelift → Stacks → Create stack

Connect VCS → choose the repo

Set Project root to:

environments/dev (if that’s where providers.tf/main.tf live)

Choose:

Runner type: default is fine (or your worker pool)

Terraform: pick OpenTofu (or “Terraform/OpenTofu” depending UI)

3) Configure Spacelift → Azure auth for Azurerm (OIDC)
3.1 Create/verify the Azure “Spacelift deploy” App Registration

In Entra Portal:

App registrations → New registration

Name: spacelift-terraform-deploy

Create

Record:

Tenant ID

Client ID (Application ID)

3.2 Create Federated Credential (OIDC trust)

In that App Registration:

Certificates & secrets → Federated credentials → Add

Choose Workload identity federation

Issuer / subject must match Spacelift’s OIDC issuer and subject format.

In Spacelift you also saw Org setting: OIDC subject template — this matters.
If you changed the org subject template, you must make Azure federated credential match it.

Important: The SPACELIFT_OIDC_TOKEN / ${SPACELIFT_OIDC_TOKEN} value is not a secret you store — it’s a runtime-issued OIDC token Spacelift injects during runs. Treat it as sensitive when printed, but you do not need to “create” it.

3.3 Give the Spacelift deploy app access to the Azure Subscription

Azure Portal → Subscription → Access Control (IAM):

Assign roles to the Service Principal of spacelift-terraform-deploy:

Contributor (or tighter if you’re locking down)

If you manage role assignments: User Access Administrator (optional, only if needed)

4) Spacelift Cloud Integration: Azure

In Spacelift:

Integrations → Cloud integrations → Azure

Configure with:

Tenant ID

Client ID (from spacelift-terraform-deploy)

Subscription ID

Federated auth / OIDC enabled (depending UI)

Attach it to your Stack:

Stack → Settings → Integrations → Attach cloud integration → pick Azure integration

This is what causes Spacelift to auto-populate some ARM_* values as <computed>.

5) Stack environment variables (Azurm + AzureAD)

Go to Stack → Environment.

5.1 Required for Azurerm

Set / verify:

ARM_SUBSCRIPTION_ID = <your subscription id>

ARM_TENANT_ID = <your tenant id>

ARM_CLIENT_ID = <client id of spacelift deploy app>

✅ For OIDC auth, you typically also need:

ARM_USE_OIDC = true

You don’t have it right now — add it.
(You already set provider "azuread" { use_oidc = true } and you likely want azurerm to use OIDC too.)

5.2 If Spacelift provides an OIDC token variable

Some setups use:

ARM_OIDC_TOKEN = ${SPACELIFT_OIDC_TOKEN}

If Spacelift integration handles token injection automatically, you may not need to define ARM_OIDC_TOKEN manually. But if your provider expects it and Spacelift isn’t wiring it, set it.

Mark as secret?

Marking ${SPACELIFT_OIDC_TOKEN} as secret is fine but not strictly required; the token itself is ephemeral. The risk is it being printed in logs.

5.3 Remove client secret for true OIDC (optional but recommended)

If you’re moving fully off secrets:

Remove ARM_CLIENT_SECRET

But: if Spacelift integration still expects to use it, don’t remove until OIDC path works.

6) Providers configuration in code

In environments/dev/providers.tf:

provider "azurerm" {
  features {}
}

provider "azuread" {
  use_oidc = true
}

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}

✅ Add ARM_USE_OIDC=true in Spacelift env to make azurerm use OIDC (that’s the missing piece in your screenshots).

7) Create Entra groups + App Registration + Enterprise App (service principal)

In environments/dev/main.tf (example skeleton):

7.1 Group
resource "azuread_group" "salesforce_group" {
  display_name     = "Salesforce Global Users"
  security_enabled = true
}
7.2 App Registration
resource "azuread_application" "salesforce_app" {
  display_name = "Salesforce Global"
}
7.3 Enterprise App (Service Principal)
resource "azuread_service_principal" "salesforce_sp" {
  application_id = azuread_application.salesforce_app.application_id
}

That’s the “same Salesforce app” pattern: application + service principal.

8) Optional: assign group to the Enterprise App

To assign a group to an enterprise app, the app must have at least one app role (or you assign to the default role if available).

8.1 Define an app role on the App Registration
resource "azuread_application" "salesforce_app" {
  display_name = "Salesforce Global"

  app_role {
    allowed_member_types = ["User", "Group"]
    description          = "Salesforce access"
    display_name         = "Salesforce User"
    enabled              = true
    id                   = "00000000-0000-0000-0000-000000000001" # replace with real GUID
    value                = "Salesforce.User"
  }
}

(Use a proper GUID generator; don’t reuse across roles.)

8.2 Assign group to that role on the Service Principal
resource "azuread_app_role_assignment" "salesforce_group_assignment" {
  app_role_id         = azuread_application.salesforce_app.app_role[0].id
  principal_object_id = azuread_group.salesforce_group.object_id
  resource_object_id  = azuread_service_principal.salesforce_sp.object_id
}
9) The big gotcha you hit: 403 “Insufficient privileges” on azuread_application

That specific error:

ApplicationsClient.BaseClient.Post(): ... 403 Authorization_RequestDenied

Means: the identity OpenTofu is using does not have permission to create app registrations.

There are two layers here:

9.1 Microsoft Graph application permissions (API permissions)

You showed these granted already:

Application.ReadWrite.All

Directory.ReadWrite.All

Group.ReadWrite.All

AppRoleAssignment.ReadWrite.All

These are necessary.

9.2 Entra directory role assignments (admin roles)

Even with Graph app permissions, some tenants require the service principal be assigned one of:

Application Administrator or

Cloud Application Administrator

You’ve assigned those (good).

Do you also need Groups Administrator?

Usually no if you have Group.ReadWrite.All app permission.

But if your tenant has restrictions, it can still help.

If your error is for creating applications, that’s not fixed by Groups Admin. That one is fixed by Application Admin / Cloud App Admin.

9.3 Why it still failed after 10 minutes

Common reasons:

The Spacelift run is not actually using OIDC for AzureAD provider (still using a different identity / cached creds)

You granted permissions to the wrong service principal (e.g., app registration vs enterprise app object)

Admin consent done in App Reg but the Enterprise Application permission grant/consent is not effective (less common, but can happen if you didn’t click grant properly)

You’re still running with ARM_CLIENT_SECRET / old integration and it’s pointing at a different app identity than you think

Fast verification in Spacelift run logs:

Confirm the ARM_CLIENT_ID used at runtime matches the deploy app you updated

Confirm azuread provider is set to use_oidc = true

Add ARM_USE_OIDC=true so azurerm isn’t falling back into a different flow (this matters more than it seems when multiple auth methods exist)

10) Configure “SSO app” (SAML/OIDC) for Salesforce/Okta

This depends on which direction you mean:

A) Entra as IdP → Salesforce (SAML)

You’ll need:

azuread_application with SAML settings (often easier in Portal than TF)

Set Identifier (Entity ID), Reply URL (ACS), Sign-on URL

Upload cert, set claims

Terraform support exists but many teams do SAML config in the Portal because it’s fiddly.

B) Entra as IdP → Okta (OIDC/SAML)

Same idea: create enterprise app + config.
But again, the protocol-specific config is often done in UI.

If you tell me which exact SSO (Salesforce or Okta) + which protocol (SAML vs OIDC), I’ll give you the correct Terraform blocks + minimal portal steps.

11) End-to-end “flow” checklist (quick)

✅ GitHub repo has providers.tf + main.tf
✅ Spacelift stack points to correct folder
✅ Azure integration attached to stack
✅ Stack env vars: ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ARM_USE_OIDC=true
✅ Entra deploy app has:

Federated credential matching Spacelift OIDC subject

Graph App perms + Admin consent

Directory Role assignment: Application Admin / Cloud App Admin
✅ OpenTofu code creates:

azuread_application

azuread_service_principal

azuread_group

optional role + assignment
