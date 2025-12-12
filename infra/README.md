# Agilis HIPAA Terraform Stack

This repository provisions the Azure infrastructure for the Agilis multi-tenant dental SaaS platform. All code is environment-agnostic; per-environment configuration lives under `infra/environments/<env>`.

## Prerequisites
- Terraform >= 1.5
- Azure CLI installed and authenticated (`az login` or Service Principal credentials)
  - Required for storage container creation via Resource Manager API (bypasses data plane restrictions)
- Access to the target Azure subscriptions

## Bootstrap Remote State (per environment)
1. **Populate tfvars**: Copy `infra/bootstrap/environments/<env>/<env>.tfvars.example` to `<env>.auto.tfvars` and fill in `subscription_id`, `tenant_id`, `common_prefix`, etc.
2. **Initialize**:
   ```bash
   cd infra/bootstrap/environments/<env>
   terraform init
   ```
3. **Plan & Apply**:
   ```bash
   terraform plan -var-file="<env>.auto.tfvars"
   terraform apply -var-file="<env>.auto.tfvars"
   ```
4. **Capture outputs**: After apply, run `terraform output` to retrieve the backend RG, storage account, and container. Each environment keeps its own state artifacts (e.g., `rg-agilis-dev-tfstate`).

## Configure Main Environment Backend
Update `infra/environments/<env>/backend.tf` with the values from the bootstrap outputs:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-agilis-dev-tfstate"
    storage_account_name = "agilisdevstatexxxx"
    container_name       = "tfstate"
    key                  = "agilis/dev/terraform.tfstate"
  }
}
```
Repeat for prod once its bootstrap apply has completed.

## Per-Environment Terraform Workflow
1. **Set environment variables or login**:
   - `az login` (interactive) or export `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID` for a service principal.
2. **Populate tfvars**:
   - Copy `infra/environments/<env>/<env>.tfvars.example` to `<env>.auto.tfvars` and adjust values (SKU sizes, location, tags, etc.). Dev examples already default to lower-cost SKUs.
3. **Initialize**:
   ```bash
   cd infra/environments/<env>
   terraform init
   ```
4. **Plan**:
   ```bash
   terraform plan -var-file="<env>.auto.tfvars"
   ```
5. **Apply** (when ready):
   ```bash
   terraform apply -var-file="<env>.auto.tfvars"
   ```
6. **Destroy** (if needed for dev/test):
   ```bash
   terraform destroy -var-file="<env>.auto.tfvars"
   ```

## Current Module Coverage
- `modules/resource_group`: Core RG per environment.
- `modules/network`: VNet, app/data subnets, NSGs, subnet delegation for App Service, and associations.
- `modules/app_service`: Linux App Service Plan + Node.js Web App, HTTPS-only, managed identity, VNet integration.
- `modules/cosmos_mongo`: Cosmos Mongo account, database, collection, private endpoint, DNS integration.
- `modules/storage`: Storage account with private endpoints, automatic container creation.
- `bootstrap/modules/state_backend`: Remote state RG, storage account, container.

Upcoming modules (not yet implemented): Key Vault, Front Door WAF, Monitoring (Log Analytics + App Insights), Sentinel, RBAC.

**Storage Container Provisioning**: Containers are created automatically during `terraform apply`. Because container creation requires data plane API access, the storage account temporarily enables public access during provisioning, then immediately disables it. The account remains private at all other times, maintaining HIPAA compliance. This is a standard pattern for private storage accounts with automated provisioning.

## Environment Defaults
- **Dev**: Uses Standard S2 App Service, Cosmos autoscale up to 1000 RU/s, free tier enabled, no auto failover.
- **Prod**: Uses Premium v3 App Service, Cosmos autoscale 4000 RU/s, failover enabled, no free tier.

Adjust these via the tfvars files as needed.

## Post-Deployment Manual Checklist
- Verify storage containers were created successfully (check via Azure Portal or `az storage container list`).
- Verify private endpoints and DNS links resolve inside the VNet for Cosmos and Storage.
- Confirm App Service can reach Cosmos and Storage via private endpoints (no public egress).
- Plan Key Vault secret ingestion (Cosmos connection string, Storage SAS/keys) and update App Service to use Key Vault references once the vault is in place.
