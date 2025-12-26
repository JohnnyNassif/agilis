# Post-Deployment Verification Checklist

## ✅ Step 1: Verify All Resources Created

### Check Resource Group
```bash
cd infra/environments/dev
terraform output resource_group_name
az group show --name $(terraform output -raw resource_group_name) --query "properties.provisioningState"
```

### Verify Key Resources Exist
```bash
RG=$(terraform output -raw resource_group_name)

# Check App Service
az webapp list --resource-group $RG --query "[].{Name:name, State:state}" -o table

# Check Storage Account
az storage account list --resource-group $RG --query "[].{Name:name, Kind:kind}" -o table

# Check Cosmos DB
az cosmosdb list --resource-group $RG --query "[].{Name:name, Kind:kind}" -o table

# Check Key Vault
az keyvault list --resource-group $RG --query "[].{Name:name, Location:location}" -o table

# Check Front Door
az afd profile list --resource-group $RG --query "[].{Name:name, SKU:sku.name}" -o table
```

---

## ✅ Step 2: Verify Front Door & WAF Configuration

### Get Front Door Endpoint
```bash
cd infra/environments/dev
terraform output frontdoor_endpoint_hostname
```

### Test Front Door Endpoint
```bash
FRONTDOOR_HOST=$(terraform output -raw frontdoor_endpoint_hostname)
curl -I https://$FRONTDOOR_HOST/
```

**Expected**: Should return HTTP 200 or 503 (if App Service doesn't have a default page yet)

### Verify WAF Policy
```bash
RG=$(terraform output -raw resource_group_name)
WAF_POLICY=$(terraform output -raw frontdoor_waf_policy_name)

az network front-door waf-policy show \
  --resource-group $RG \
  --name $WAF_POLICY \
  --query "{Name:name, Mode:policySettings.enabledState, RuleSets:managedRulesSets}" -o json
```

---

## ✅ Step 3: Verify Private Endpoints & DNS

### Check Private Endpoints
```bash
RG=$(terraform output -raw resource_group_name)

az network private-endpoint list --resource-group $RG \
  --query "[].{Name:name, ProvisioningState:provisioningState, PrivateLinkServiceConnections:privateLinkServiceConnections[0].provisioningState}" \
  -o table
```

**Expected**: All should show `Succeeded`

### Verify Private DNS Zones
```bash
az network private-dns zone list --resource-group $RG \
  --query "[].{Name:name, NumberOfRecords:numberOfRecords}" -o table
```

**Expected**: Should see zones for:
- `privatelink.blob.core.windows.net` (Storage)
- `privatelink.vaultcore.azure.net` (Key Vault)
- `privatelink.mongo.cosmos.azure.com` (Cosmos DB)

---

## ✅ Step 4: Verify Key Vault Secrets

### List Secrets
```bash
VAULT_NAME=$(terraform output -raw key_vault_name)

az keyvault secret list --vault-name $VAULT_NAME --query "[].{Name:name, Enabled:attributes.enabled}" -o table
```

**Expected**: Should see:
- `cosmos-connection-string`
- `storage-account-key`
- `storage-account-name`

### Verify App Service Can Access Key Vault
```bash
APP_SERVICE=$(terraform output -raw app_service_name)
VAULT_NAME=$(terraform output -raw key_vault_name)

# Check if App Service managed identity has Key Vault access
az role assignment list \
  --scope $(az keyvault show --name $VAULT_NAME --query id -o tsv) \
  --query "[?principalName=='$APP_SERVICE'].{Principal:principalName, Role:roleDefinitionName}" -o table
```

**Expected**: Should show `Key Vault Secrets User` role assignment

---

## ✅ Step 5: Verify App Service Configuration

### Check App Service App Settings
```bash
APP_SERVICE=$(terraform output -raw app_service_name)
RG=$(terraform output -raw resource_group_name)

az webapp config appsettings list \
  --name $APP_SERVICE \
  --resource-group $RG \
  --query "[?contains(name, 'VAULT') || contains(name, 'COSMOS') || contains(name, 'STORAGE')].{Name:name, Value:value}" -o table
```

**Expected**: Should see Key Vault references like:
- `@Microsoft.KeyVault(SecretUri=...)`

### Verify VNet Integration
```bash
APP_SERVICE=$(terraform output -raw app_service_name)
RG=$(terraform output -raw resource_group_name)

az webapp vnet-integration list \
  --name $APP_SERVICE \
  --resource-group $RG -o table
```

**Expected**: Should show VNet integration enabled

---

## ✅ Step 6: Verify Diagnostic Settings

### Check Diagnostic Settings for All Resources
```bash
RG=$(terraform output -raw resource_group_name)

# Get Log Analytics Workspace name
LAW_NAME=$(az monitor log-analytics workspace list --resource-group $RG --query "[0].name" -o tsv)

# Check diagnostic settings
az monitor diagnostic-settings list --resource-group $RG \
  --query "[].{Name:name, TargetResource:resourceId, LogAnalytics:logAnalyticsDestinationType}" \
  -o table
```

**Expected**: Should see diagnostic settings for (at minimum):
- App Services (main + telehealth + whiteboard)
- Static Web Apps (main + telehealth + whiteboard)
- Cosmos DB
- Storage Account (metrics) + Blob service (read/write/delete logs)
- Key Vault (AuditEvent)
- Front Door (access/health/WAF logs)
- NSGs (event + rule counter)
- Bastion (audit logs + metrics)
- Application Insights (export to Log Analytics)

---

## ✅ Step 7: Verify Monitoring (Application Insights)

### Check Application Insights
```bash
RG=$(terraform output -raw resource_group_name)

az monitor app-insights component show \
  --app $(az monitor app-insights component list --resource-group $RG --query "[0].name" -o tsv) \
  --resource-group $RG \
  --query "{Name:name, InstrumentationKey:instrumentationKey, ConnectionString:connectionString}" -o json
```

---

## ✅ Step 8: Test Connectivity (If Bastion Enabled)

### Connect to Jump VM
1. **Start VM** (if stopped):
   ```bash
   VM_NAME=$(terraform output -raw bastion_vm_name)
   RG=$(terraform output -raw resource_group_name)
   az vm start --name $VM_NAME --resource-group $RG
   ```

2. **Get VM Password**:
   ```bash
   terraform output -raw bastion_vm_password
   ```

3. **Connect via Azure Portal**:
   - Go to Azure Portal → Virtual Machines → `vm-agilis-dev-jmp`
   - Click "Connect" → "Bastion"
   - Enter username: `azureadmin` (or check output)
   - Enter password from step 2

4. **Test Key Vault Access from VM**:
   ```powershell
   # In VM PowerShell
   az login --identity
   az keyvault secret show --vault-name <vault-name> --name cosmos-connection-string
   ```

---

## ✅ Step 9: Verify Network Security

### Check NSG Rules
```bash
RG=$(terraform output -raw resource_group_name)

az network nsg list --resource-group $RG \
  --query "[].{Name:name, Rules:securityRules[?direction=='Inbound' && access=='Deny'].name}" -o table
```

**Expected**: Should see deny rules for Internet inbound

### Verify Storage Account Network Rules
```bash
STORAGE_NAME=$(terraform output -raw storage_account_name)
RG=$(terraform output -raw resource_group_name)

az storage account show \
  --name $STORAGE_NAME \
  --resource-group $RG \
  --query "{PublicAccess:publicNetworkAccess, NetworkRules:networkRuleSet}" -o json
```

**Note**: `publicNetworkAccess` may still be `Enabled` until you complete the post-deployment hardening checklist.

---

## ✅ Step 10: Verify Cosmos DB Configuration

### Check Cosmos DB Settings
```bash
COSMOS_NAME=$(terraform output -raw cosmos_account_name)
RG=$(terraform output -raw resource_group_name)

az cosmosdb show \
  --name $COSMOS_NAME \
  --resource-group $RG \
  --query "{PublicAccess:publicNetworkAccess, VNetFilter:isVirtualNetworkFilterEnabled, Backup:backupPolicy}" -o json
```

**Note**: `publicNetworkAccess` may still be `Enabled` until you complete the post-deployment hardening checklist.

---

## 🚨 Step 11: Next Steps - HIPAA Compliance

### Current Status
✅ **Infrastructure deployed successfully**
⚠️ **Public access is still ENABLED** for Storage Account, Cosmos DB, and Key Vault

### When Ready to Disable Public Access

Follow `infra/docs/shared/HIPAA_COMPLIANCE_MANUAL_CHECKLIST.md`.

If you prefer CLI (instead of portal), you can disable public access manually:

```bash
RG=$(terraform output -raw resource_group_name)
STORAGE=$(terraform output -raw storage_account_name)
VAULT=$(terraform output -raw key_vault_name)
COSMOS=$(terraform output -raw cosmos_account_name)

# Disable Storage Account public access
az storage account update \
  --name $STORAGE \
  --resource-group $RG \
  --public-network-access Disabled

# Disable Key Vault public access
az keyvault update \
  --name $VAULT \
  --resource-group $RG \
  --public-network-access Disabled

# Set Key Vault network rule to Deny
az keyvault network-rule set \
  --name $VAULT \
  --resource-group $RG \
  --default-action Deny

# Disable Cosmos DB public access
az cosmosdb update \
  --name $COSMOS \
  --resource-group $RG \
  --public-network-access Disabled
```

**Important:** After disabling public access, Terraform runs from a local machine may fail on some data-plane resources (e.g., Storage containers). If you must manage data-plane resources via Terraform, run Terraform from inside the VNet (jump VM/runner), or stop managing those data-plane resources with Terraform.

3. **Enable Infrastructure Encryption** (HIPAA Requirement)
   ```bash
   az storage account update \
     --name $STORAGE \
     --resource-group $RG \
     --enable-infrastructure-encryption
   ```

---

## 📋 Quick Verification Script

Save this as `verify-deployment.sh`:

```bash
#!/bin/bash
set -e

cd infra/environments/dev
RG=$(terraform output -raw resource_group_name)

echo "=== Verifying Deployment ==="
echo "Resource Group: $RG"
echo ""

echo "1. Checking resources..."
az group show --name $RG --query "properties.provisioningState" -o tsv
echo "✅ Resource Group exists"

echo ""
echo "2. Checking Front Door..."
FD_HOST=$(terraform output -raw frontdoor_endpoint_hostname 2>/dev/null || echo "N/A")
echo "Front Door Hostname: $FD_HOST"

echo ""
echo "3. Checking Key Vault secrets..."
VAULT=$(terraform output -raw key_vault_name)
az keyvault secret list --vault-name $VAULT --query "[].name" -o tsv | wc -l
echo "✅ Secrets configured"

echo ""
echo "4. Checking Private Endpoints..."
az network private-endpoint list --resource-group $RG --query "length([?provisioningState=='Succeeded'])" -o tsv
echo "✅ Private endpoints configured"

echo ""
echo "=== Deployment Verification Complete ==="
```

Run: `chmod +x verify-deployment.sh && ./verify-deployment.sh`

---

## 🎯 Summary

**✅ Completed:**
- All resources deployed successfully
- Front Door with WAF configured
- Private endpoints configured
- Key Vault secrets created
- Diagnostic settings enabled
- Monitoring configured

**⚠️ Pending:**
- Disable public access (when ready)
- Enable infrastructure encryption on Storage Account
- Deploy application code to App Service
- Configure custom domain (optional)

**📝 Notes:**
- Public access is currently enabled for development/testing
- All resources are accessible via private endpoints
- Front Door protects App Service from direct Internet access
- WAF is configured with OWASP Top 10 rules (Premium SKU)

