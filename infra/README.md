# Agilis HIPAA Terraform Stack

This repository provisions the Azure infrastructure for the Agilis multi-tenant dental SaaS platform. All code is environment-agnostic; per-environment configuration lives under `infra/environments/<env>`.

## Quick Links

- **[Frontend Deployment Guide](FRONTEND_DEPLOYMENT_GUIDE.md)** - Step-by-step guide for deploying Angular frontend to Azure Static Web Apps

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
   
   **Note**: Currently, public access is enabled for Storage Account, Cosmos DB, and Key Vault. After all HIPAA resources are created, you can disable public access manually (see "HIPAA Compliance - Disabling Public Access" section below).
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
- `modules/key_vault`: Key Vault with private endpoint, RBAC, soft delete, purge protection, and automatic secret storage.
- `modules/monitoring`: Log Analytics Workspace, Application Insights, and diagnostic settings for all resources (App Service, Cosmos, Storage, Key Vault).
- `modules/bastion`: Azure Bastion with Windows jump VM, auto-shutdown schedule, and Key Vault access (optional, pay-as-you-go).
- `modules/frontdoor_waf`: Azure Front Door with WAF policy, OWASP Top 10 protection, bot management, and DDoS protection (**MANDATORY for HIPAA compliance**).
- `modules/policy`: Azure Policy assignments for HIPAA compliance enforcement, including HIPAA/HITRUST initiative and custom policies for private endpoints, encryption, and diagnostic settings.
- `modules/security_alerts`: Security monitoring alerts for failed authentication, policy violations, network anomalies, and data exfiltration attempts (**HIGH PRIORITY for HIPAA compliance**).
- `modules/sentinel`: Azure Sentinel (SIEM/SOAR) for advanced security monitoring, threat detection, and automated response. Includes data connectors (Azure Activity, Security Center, Key Vault, Storage) and analytics rules for security events (**HIGH PRIORITY for HIPAA compliance**).
- `bootstrap/modules/state_backend`: Remote state RG, storage account, container.

**Storage Container & Key Vault Secret Provisioning**: Both containers and secrets are created automatically during `terraform apply` using a consolidated approach:

- **Storage Containers**: All containers are created using Terraform's native `azurerm_storage_container` resources. Public access is currently enabled to facilitate infrastructure development and testing.

- **Key Vault Secrets**: All secrets (Cosmos connection string, Storage account key, Storage account name) are created using Terraform's native `azurerm_key_vault_secret` resources. Public access is currently enabled to facilitate infrastructure development and testing.

**HIPAA Compliance**: Public access is currently **enabled** for Storage Account, Cosmos DB, and Key Vault. After all HIPAA resources are created, public access should be disabled manually (see "HIPAA Compliance - Disabling Public Access" section below).

## Environment Defaults
- **Dev**: Uses Standard S2 App Service, Cosmos autoscale up to 1000 RU/s, free tier enabled, no auto failover.
- **Prod**: Uses Premium v3 App Service, Cosmos autoscale 4000 RU/s, failover enabled, no free tier.

Adjust these via the tfvars files as needed.

## Post-Deployment Manual Checklist
- ✅ Verify storage containers were created successfully (check via Azure Portal or `az storage container list`).
- ✅ Verify private endpoints and DNS links resolve inside the VNet for Cosmos, Storage, and Key Vault.
- ✅ Confirm App Service can reach Cosmos and Storage via private endpoints (no public egress).
- ✅ Verify Key Vault secrets are stored (Cosmos connection string, Storage account key and name).
- ✅ Confirm App Service app_settings use Key Vault references (check App Service Configuration in Azure Portal).
- ✅ Verify Application Insights is configured and receiving telemetry (check Application Insights in Azure Portal).
- ✅ Verify diagnostic settings are enabled for all resources (check Log Analytics workspace in Azure Portal).
- ✅ Confirm logs are flowing to Log Analytics workspace (run sample queries in Log Analytics).
- ✅ If Bastion is enabled: Verify Windows VM can access Key Vault via managed identity (connect via Bastion and test).

## HIPAA Compliance - Disabling Public Access

**NOTE**: Currently, public access is **enabled** for Storage Account, Cosmos DB, and Key Vault to facilitate infrastructure development and testing.

**After all HIPAA resources are created**, you can manually disable public access by:

1. **Uncomment the `disable_public_access` script** in `infra/main.tf` (lines 355-572)
2. **Run the script** via Terraform: `terraform apply -var-file="dev.auto.tfvars" -auto-approve`
3. **Or manually disable** via Azure Portal/CLI:
   - Storage Account: `az storage account update --name <name> --resource-group <rg> --public-network-access Disabled`
   - Key Vault: `az keyvault update --name <name> --resource-group <rg> --public-network-access Disabled` + `az keyvault network-rule set --name <name> --resource-group <rg> --default-action Deny`
   - Cosmos DB: Set `public_network_access_enabled = false` in Terraform and apply

**Important**: After disabling public access, Terraform may not be able to refresh storage container state from your local machine. Use `terraform apply -refresh=false` for subsequent runs, or manage containers via Azure Portal/CLI from within the VNet (via Bastion).

## Azure Bastion Usage (Pay-as-You-Go)

If `bastion_enabled = true` is set in your environment tfvars:

1. **Start the Windows VM** (when needed):
   - Azure Portal → Virtual Machines → Select your jump VM → Start
   - Or via CLI: `az vm start --name <vm-name> --resource-group <rg-name>`

2. **Connect via Azure Bastion**:
   - Azure Portal → Virtual Machines → Select your jump VM → Connect → Bastion
   - Enter VM admin username and password (retrieve password: `terraform output -raw bastion_vm_password`)
   - Browser-based RDP session opens (no VPN needed)

3. **Install Azure CLI on VM** (first time only):
   - Once connected, install Azure CLI: `winget install -e --id Microsoft.AzureCLI`
   - Or download from: https://aka.ms/installazurecliwindows
   - Restart PowerShell/Command Prompt after installation

4. **Access Key Vault from VM**:
   - VM has managed identity with "Key Vault Secrets User" role
   - Login with managed identity: `az login --identity`
   - Use Azure CLI: `az keyvault secret show --vault-name <vault-name> --name <secret-name>`
   - Or use Azure PowerShell: `Get-AzKeyVaultSecret -VaultName <vault-name> -Name <secret-name>`

5. **Access Storage Account from VM**:
   - VM has managed identity with "Storage Blob Data Contributor" role
   - VM subnet has service endpoints enabled for Microsoft.Storage
   - Storage Account is accessible via private endpoint (DNS resolves automatically)
   - Login with managed identity: `az login --identity`
   - List containers: `az storage container list --account-name <storage-account-name> --auth-mode login`
   - List blobs: `az storage blob list --container-name <container-name> --account-name <storage-account-name> --auth-mode login`
   - Or get storage account key from Key Vault: `az keyvault secret show --vault-name <vault-name> --name storage-account-key --query value -o tsv`

6. **Access Cosmos DB from VM**:
   - VM has managed identity with "Cosmos DB Account Reader Role"
   - VM subnet has service endpoints enabled for Microsoft.AzureCosmosDB
   - Cosmos DB is accessible via private endpoint (DNS resolves automatically)
   - Get connection string from Key Vault: `az keyvault secret show --vault-name <vault-name> --name cosmos-connection-string --query value -o tsv`
   - Use MongoDB connection string with MongoDB Compass, Azure Data Studio, or your application
   - Example MongoDB connection: `mongodb://<account-name>:<password>@<account-name>.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb`

5. **VM Auto-Shutdown**:
   - VM automatically shuts down at configured time (default: 6 PM UTC)
   - Saves compute costs when not in use
   - Only pay for Bastion usage time (~$0.19/hour) + VM storage (~$0.10/month)

**VM Sizing**:
- **Default**: `Standard_B2s` (2 vCPU, 4GB RAM) - Recommended for database IDE work (MongoDB Compass, Azure Data Studio, etc.)
- **Cost**: ~$26.60/month when running 24/7, ~$1.78/month for 2 hours/day usage
- **Scaling**: Update `bastion_vm_size` in your tfvars file if you need more resources:
  - `Standard_B2ms` (2 vCPU, 8GB RAM) - ~$53.20/month (24/7) or ~$3.55/month (2hrs/day)
  - `Standard_D2s_v3` (2 vCPU, 8GB RAM, consistent performance) - ~$70/month (24/7) or ~$4.67/month (2hrs/day)

**Cost**: ~$1.78-4.67/month for 2 hours/day usage (VM stopped when not in use, Bastion pay-per-use)
