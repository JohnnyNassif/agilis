# Deployment Runbook (Terraform from Local Machine)

**Audience:** Internal development/ops  
**Scope:** Bootstrap (remote state) + Dev/Prod infrastructure deployment using Terraform from a developer workstation.  
**Out of scope:** Legal/compliance certification. This runbook documents technical steps and operational checks only.

---

## Key Constraints (Read First)

- **Provider registration is manual**: this repo sets `skip_provider_registration = true` in both `infra/providers.tf` and `infra/bootstrap/providers.tf`, so Terraform will **not** auto-register Azure resource providers.
- **Global name uniqueness**: App Service names must be globally unique across Azure. If you hit “name already exists”, change `common_prefix` in the environment tfvars.
- **Hardening vs Terraform drift**:
  - Storage/Key Vault/Cosmos public access is hardened **manually** after deploy (see shared checklist).
  - Terraform is configured to avoid reverting approved manual hardening in key places (e.g., Key Vault/Cosmos/App Service restrictions where applicable).
- **Storage container 403 risk from local machine**:
  - `azurerm_storage_container` is a **data-plane** operation.
  - If you disable Storage public access and your local machine cannot reach the private endpoint, Terraform plan/apply may fail with **403** when it refreshes or manages containers.
  - If you must keep running Terraform from local, consider **not managing containers with Terraform**, or run Terraform from inside the VNet for those operations.

---

## Prerequisites

### Tooling
- Terraform **>= 1.5**
- Azure CLI (`az`)
- Git Bash/PowerShell on Windows is fine

### Authentication
Use either:
- **Interactive**: `az login` (best for dev)
- **Service principal**: set `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`

### Access
Minimum: ability to create resources in the target subscription/resource groups (Contributor), plus permissions needed for RBAC assignments.

---

## One-Time Subscription Setup: Register Required Resource Providers

Because provider auto-registration is disabled, register providers once per subscription:

```bash
az account set --subscription "<SUBSCRIPTION_ID>"

for ns in \
  Microsoft.Network \
  Microsoft.Web \
  Microsoft.Storage \
  Microsoft.KeyVault \
  Microsoft.DocumentDB \
  Microsoft.Cdn \
  Microsoft.OperationalInsights \
  Microsoft.Insights \
  Microsoft.SecurityInsights \
  Microsoft.Authorization \
  Microsoft.ManagedIdentity \
  Microsoft.Compute \
  Microsoft.RecoveryServices
do
  az provider register --namespace "$ns"
done
```

Verify:

```bash
az provider show --namespace Microsoft.Storage --query "registrationState" -o tsv
```

If Terraform errors mention a missing namespace, register that provider and re-run.

---

## Environment Inputs (tfvars)

Each environment uses:
- Bootstrap: `infra/bootstrap/environments/<env>/<env>.auto.tfvars`
- Main infra: `infra/environments/<env>/<env>.auto.tfvars`

**Most common required fields:**
- `subscription_id`, `tenant_id`
- `common_prefix` (must be globally unique enough to avoid App Service name collisions)
- alert recipients (especially in prod)
- RBAC admin user object IDs (prod)

---

## Step A — Bootstrap Remote State (per environment)

1) Init:

```bash
cd infra/bootstrap/environments/<env>
terraform init
```

2) Plan + apply:

```bash
terraform plan  -var-file="<env>.auto.tfvars"
terraform apply -var-file="<env>.auto.tfvars"
```

3) Capture outputs:

```bash
terraform output
```

4) Update backend:
- Put the output values into: `infra/environments/<env>/backend.tf`

---

## Step B — Deploy Infrastructure (per environment)

1) Init:

```bash
cd infra/environments/<env>
terraform init
```

2) Plan:

```bash
terraform plan -var-file="<env>.auto.tfvars"
```

3) Apply:

```bash
terraform apply -var-file="<env>.auto.tfvars"
```

4) Outputs:

```bash
terraform output
```

---

## Step C — Post-Deployment Verification (all environments)

Follow:
- `infra/docs/shared/POST_DEPLOYMENT_CHECKLIST.md`

At minimum, verify:
- Front Door endpoint responds
- App Service is running
- Key Vault secrets exist
- Logs flowing to Log Analytics / App Insights

---

## Step D — Post-Deployment Hardening (PHI/Prod)

Follow:
- `infra/docs/shared/HIPAA_COMPLIANCE_MANUAL_CHECKLIST.md`

Key actions:
- App Service Access Restrictions: allow Front Door only + deny all
- Disable public network access for Storage, Key Vault, Cosmos DB
- Verify private DNS + private endpoint access from jump VM/VNet

**Important:** After disabling Storage public access, Terraform from local may fail on storage containers (data-plane). Plan future changes accordingly.

---

## Common Failures & Fixes

### 1) MissingSubscriptionRegistration / provider not registered
- Register the provider namespace with `az provider register --namespace ...`
- Re-run `terraform plan`

### 2) 409 Conflict while ensuring providers are registered
- Expected in fresh subscriptions when auto-registration is attempted concurrently.
- This repo disables provider auto-registration (`skip_provider_registration = true`). Register providers manually (section above).

### 3) App Service name already exists
- App Service names are globally unique.
- Change `common_prefix` in `<env>.auto.tfvars` and retry.

### 4) 403 on `azurerm_storage_container`
- Root cause: Storage container management is data-plane; your local machine cannot reach the storage endpoint after hardening.
- Options:
  - Run Terraform from inside the VNet for those operations, or
  - Stop managing containers with Terraform (preferred if Terraform must run locally), or
  - Temporarily re-enable public access only long enough to reconcile (not recommended for PHI/prod).

---

## Safety Checklist Before Changing Prod

- Review plan output for unintended reversions (especially networking/public access/access restrictions).
- Confirm you are using the correct workspace/state (`infra/environments/prod` vs dev).
- Ensure alert recipients + RBAC admin IDs are correct.
- Make changes in small increments.




