# HIPAA Compliance Manual Checklist

**Purpose:** This checklist contains manual steps required to achieve HIPAA compliance after Terraform deployment. These steps were previously automated via scripts but are now done manually to avoid deployment errors.

**When to Complete:** After successful `terraform apply` completes and all resources are created.

**Estimated Time:** 15-20 minutes

---

## ⚠️ IMPORTANT: Complete This Checklist Before Storing PHI

**DO NOT store any Protected Health Information (PHI) until all steps in this checklist are completed and verified.**

---

## 📋 Checklist Overview

- [ ] **Part 1: App Service IP Restrictions** (P0.2 - Block direct access)
- [ ] **Part 2: Disable Storage Account Public Access** (P0.4)
- [ ] **Part 3: Disable Key Vault Public Access** (P0.4)
- [ ] **Part 4: Disable Cosmos DB Public Access** (P0.4)
- [ ] **Part 5: Verification** (Verify all changes)

---

## Part 1: App Service IP Restrictions (P0.2)

**Goal:** Block direct access to App Service via `*.azurewebsites.net` URLs. Only allow traffic from Azure Front Door.

**Why:** HIPAA requires that applications are not directly accessible from the internet. All traffic must go through Front Door with WAF protection.

### Step 1.1: Get Front Door ID

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Front Door profiles** → `fd-<prefix>-prod`
3. In the **Overview** page, find **Front Door ID** (GUID format, e.g., `b5333fa2-fa08-4006-a286-1e107da3fc64`)
4. **Copy this ID** - you'll need it in Step 1.3

**Alternative (Azure CLI):**
```bash
RESOURCE_GROUP="rg-<prefix>-prod-core"
FRONTDOOR_PROFILE="fd-<prefix>-prod"

az afd profile show \
  --resource-group "$RESOURCE_GROUP" \
  --profile-name "$FRONTDOOR_PROFILE" \
  --query "properties.frontDoorId" -o tsv
```

### Step 1.2: Configure Main Site IP Restrictions

1. Go to **App Services** → `app-<prefix>-prod-api`
2. Navigate to **Networking** → **Access Restrictions**
3. Click **+ Add rule** for **Main site**

**Rule 1: Deny All (Highest Priority)**
- **Name:** `DenyAll`
- **Action:** Deny
- **Priority:** `2147483647` (highest)
- **IP Address:** `0.0.0.0/0`
- Click **Add**

**Rule 2: Allow Front Door (Lower Priority)**
- **Name:** `AllowFrontDoor`
- **Action:** Allow
- **Priority:** `100`
- **Service Tag:** `AzureFrontDoor.Backend`
- **HTTP Header:**
  - **Header name:** `x-azure-fdid`
  - **Header value:** `<Front-Door-ID-from-Step-1.1>`
- Click **Add**

**Alternative (Azure CLI):**
```bash
RESOURCE_GROUP="rg-<prefix>-prod-core"
APP_SERVICE="app-<prefix>-prod-api"
FRONTDOOR_ID="<Front-Door-ID-from-Step-1.1>"

# Add DenyAll rule
az webapp config access-restriction add \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_SERVICE" \
  --rule-name "DenyAll" \
  --action Deny \
  --priority 2147483647 \
  --ip-address "0.0.0.0/0" \
  --scm-site false

# Add AllowFrontDoor rule with header validation
az webapp config access-restriction add \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_SERVICE" \
  --rule-name "AllowFrontDoor" \
  --action Allow \
  --priority 100 \
  --service-tag AzureFrontDoor.Backend \
  --http-header "x-azure-fdid=$FRONTDOOR_ID" \
  --scm-site false
```

### Step 1.3: Configure SCM/Kudu Site IP Restrictions

1. Still in **Access Restrictions**, switch to **SCM site** tab
2. Click **+ Add rule**

**Rule 1: Deny All SCM (Highest Priority)**
- **Name:** `DenyAll-SCM`
- **Action:** Deny
- **Priority:** `2147483647`
- **IP Address:** `0.0.0.0/0`
- Click **Add**

**Rule 2: Allow Front Door SCM (Optional - for deployments)**
- **Name:** `AllowFrontDoor-SCM`
- **Action:** Allow
- **Priority:** `100`
- **Service Tag:** `AzureFrontDoor.Backend`
- **HTTP Header:**
  - **Header name:** `x-azure-fdid`
  - **Header value:** `<Front-Door-ID-from-Step-1.1>`
- Click **Add**

**Alternative (Azure CLI):**
```bash
# Add DenyAll-SCM rule
az webapp config access-restriction add \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_SERVICE" \
  --rule-name "DenyAll-SCM" \
  --action Deny \
  --priority 2147483647 \
  --ip-address "0.0.0.0/0" \
  --scm-site true

# Add AllowFrontDoor-SCM rule (optional)
az webapp config access-restriction add \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_SERVICE" \
  --rule-name "AllowFrontDoor-SCM" \
  --action Allow \
  --priority 100 \
  --service-tag AzureFrontDoor.Backend \
  --http-header "x-azure-fdid=$FRONTDOOR_ID" \
  --scm-site true
```

### Step 1.4: Verify App Service IP Restrictions

**Verification:**
1. Try accessing `https://app-<prefix>-prod-api.azurewebsites.net` directly
2. **Expected:** Connection refused or timeout (direct access blocked)
3. Access via Front Door URL: `https://fe-<prefix>-prod.azurefd.net`
4. **Expected:** Application loads successfully

**Alternative (Azure CLI):**
```bash
# Check main site rules
az webapp config access-restriction show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_SERVICE" \
  --scm-site false \
  --query "ipSecurityRestrictions" -o json

# Check SCM site rules
az webapp config access-restriction show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_SERVICE" \
  --scm-site true \
  --query "ipSecurityRestrictions" -o json
```

**✅ Checklist Item:** [ ] App Service IP restrictions configured and verified

---

## Part 2: Disable Storage Account Public Access (P0.4)

**Goal:** Disable public network access and set network rules to Deny for HIPAA compliance.

### Step 2.1: Disable Public Network Access

1. Go to **Storage accounts** → `st<prefix>prod<random>`
2. Navigate to **Networking**
3. Under **Public network access**, select **Disabled**
4. Click **Save**
5. Wait for the change to complete (may take 1-2 minutes)

**Alternative (Azure CLI):**
```bash
STORAGE_ACCOUNT="st<prefix>prod<random>"
RESOURCE_GROUP="rg-<prefix>-prod-core"

az storage account update \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --public-network-access Disabled
```

### Step 2.2: Set Network Rules to Deny

1. Still in **Networking** → **Firewalls and virtual networks**
2. Select **Selected networks**
3. Under **Default action**, ensure it's set to **Deny**
4. Under **Exceptions**, ensure **Allow Azure services on the trusted services list to access this storage account** is checked
5. Click **Save**

**Alternative (Azure CLI):**
```bash
az storage account network-rule set \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --default-action Deny \
  --bypass AzureServices
```

### Step 2.3: Verify Storage Account Settings

**Verification:**
1. Go to **Storage accounts** → `st<prefix>prod<random>` → **Networking**
2. Verify **Public network access** shows **Disabled**
3. Verify **Default action** shows **Deny**

**Alternative (Azure CLI):**
```bash
# Check public network access
az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "publicNetworkAccess" -o tsv
# Expected: Disabled

# Check network rules
az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "networkRuleSet.defaultAction" -o tsv
# Expected: Deny
```

**✅ Checklist Item:** [ ] Storage Account public access disabled and network rules set to Deny

---

## Part 3: Disable Key Vault Public Access (P0.4)

**Goal:** Disable public network access and set network rules to Deny for HIPAA compliance.

### Step 3.1: Disable Public Network Access

1. Go to **Key Vaults** → `kv<prefix>prod<random>`
2. Navigate to **Networking**
3. Under **Public network access**, select **Disabled**
4. Click **Save**
5. Wait for the change to complete (may take 1-2 minutes)

**Alternative (Azure CLI):**
```bash
VAULT_NAME="kv<prefix>prod<random>"
RESOURCE_GROUP="rg-<prefix>-prod-core"

az keyvault update \
  --name "$VAULT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --public-network-access Disabled
```

### Step 3.2: Set Network Rules to Deny

1. Still in **Networking** → **Firewalls and virtual networks**
2. Under **Default action**, select **Deny**
3. Click **Save**

**Alternative (Azure CLI):**
```bash
az keyvault network-rule set \
  --name "$VAULT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --default-action Deny
```

### Step 3.3: Verify Key Vault Settings

**Verification:**
1. Go to **Key Vaults** → `kv<prefix>prod<random>` → **Networking**
2. Verify **Public network access** shows **Disabled**
3. Verify **Default action** shows **Deny**

**Alternative (Azure CLI):**
```bash
# Check public network access
az keyvault show \
  --name "$VAULT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "properties.publicNetworkAccess" -o tsv
# Expected: Disabled

# Check network rules
az keyvault network-rule list \
  --name "$VAULT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "defaultAction" -o tsv
# Expected: Deny
```

**✅ Checklist Item:** [ ] Key Vault public access disabled and network rules set to Deny

---

## Part 4: Disable Cosmos DB Public Access (P0.4)

**Goal:** Disable public network access for HIPAA compliance.

### Step 4.1: Disable Public Network Access

1. Go to **Azure Cosmos DB** → `cosmos<prefix>prodprod`
2. Navigate to **Networking**
3. Under **Public network access**, select **Disabled**
4. Click **Save**
5. Wait for the change to complete (may take 2-3 minutes)

**Alternative (Azure CLI):**
```bash
COSMOS_ACCOUNT="cosmos<prefix>prodprod"
RESOURCE_GROUP="rg-<prefix>-prod-core"

az cosmosdb update \
  --name "$COSMOS_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --public-network-access Disabled
```

### Step 4.2: Verify Cosmos DB Settings

**Verification:**
1. Go to **Azure Cosmos DB** → `cosmos<prefix>prodprod` → **Networking**
2. Verify **Public network access** shows **Disabled**

**Alternative (Azure CLI):**
```bash
az cosmosdb show \
  --name "$COSMOS_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "publicNetworkAccess" -o tsv
# Expected: Disabled
```

**✅ Checklist Item:** [ ] Cosmos DB public access disabled

---

## Part 5: Final Verification

### Step 5.1: Verify All Resources Are Compliant

Run this verification script to check all resources:

```bash
#!/bin/bash
RESOURCE_GROUP="rg-<prefix>-prod-core"
STORAGE_ACCOUNT="st<prefix>prod<random>"
VAULT_NAME="kv<prefix>prod<random>"
COSMOS_ACCOUNT="cosmos<prefix>prodprod"
APP_SERVICE="app-<prefix>-prod-api"

echo "=========================================="
echo "HIPAA Compliance Verification"
echo "=========================================="

# Check Storage Account
echo "Checking Storage Account..."
STORAGE_PUBLIC=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "publicNetworkAccess" -o tsv)
STORAGE_DENY=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "networkRuleSet.defaultAction" -o tsv)

if [ "$STORAGE_PUBLIC" = "Disabled" ] && [ "$STORAGE_DENY" = "Deny" ]; then
  echo "✅ Storage Account: Compliant"
else
  echo "❌ Storage Account: NOT Compliant (Public: $STORAGE_PUBLIC, Default: $STORAGE_DENY)"
fi

# Check Key Vault
echo "Checking Key Vault..."
VAULT_PUBLIC=$(az keyvault show \
  --name "$VAULT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "properties.publicNetworkAccess" -o tsv)
VAULT_DENY=$(az keyvault network-rule list \
  --name "$VAULT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "defaultAction" -o tsv)

if [ "$VAULT_PUBLIC" = "Disabled" ] && [ "$VAULT_DENY" = "Deny" ]; then
  echo "✅ Key Vault: Compliant"
else
  echo "❌ Key Vault: NOT Compliant (Public: $VAULT_PUBLIC, Default: $VAULT_DENY)"
fi

# Check Cosmos DB
echo "Checking Cosmos DB..."
COSMOS_PUBLIC=$(az cosmosdb show \
  --name "$COSMOS_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "publicNetworkAccess" -o tsv)

if [ "$COSMOS_PUBLIC" = "Disabled" ]; then
  echo "✅ Cosmos DB: Compliant"
else
  echo "❌ Cosmos DB: NOT Compliant (Public: $COSMOS_PUBLIC)"
fi

# Check App Service IP Restrictions
echo "Checking App Service IP Restrictions..."
APP_RULES=$(az webapp config access-restriction show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_SERVICE" \
  --scm-site false \
  --query "length(ipSecurityRestrictions)" -o tsv)

if [ "$APP_RULES" -ge 2 ]; then
  echo "✅ App Service: IP Restrictions configured ($APP_RULES rules)"
else
  echo "⚠️  App Service: Only $APP_RULES rules found (expected at least 2)"
fi

echo "=========================================="
echo "Verification Complete"
echo "=========================================="
```

### Step 5.2: Test Application Access

1. **Test Direct Access (Should Fail):**
   - Try: `https://app-<prefix>-prod-api.azurewebsites.net`
   - **Expected:** Connection refused/timeout

2. **Test Front Door Access (Should Succeed):**
   - Try: `https://fe-<prefix>-prod.azurefd.net`
   - **Expected:** Application loads successfully

**✅ Checklist Item:** [ ] All resources verified and application accessible via Front Door only

---

## 📝 Quick Reference: Resource Names

Replace `<prefix>` with your actual prefix (e.g., `agilis1`, `agilis2`, etc.):

- **Resource Group:** `rg-<prefix>-prod-core`
- **Storage Account:** `st<prefix>prod<random>` (check Azure Portal for exact name)
- **Key Vault:** `kv<prefix>prod<random>` (check Azure Portal for exact name)
- **Cosmos DB:** `cosmos<prefix>prodprod`
- **App Service:** `app-<prefix>-prod-api`
- **Front Door Profile:** `fd-<prefix>-prod`

**To find exact resource names:**
```bash
RESOURCE_GROUP="rg-<prefix>-prod-core"

# List all resources
az resource list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[].{Name:name, Type:type}" -o table
```

---

## 🚨 Troubleshooting

### Issue: "Cannot access Storage Account after disabling public access"

**Solution:** Access is now only via private endpoint. Ensure:
- Your machine is connected to the VNet (via VPN/Bastion)
- Or use Azure Portal (which uses Azure Services bypass)

### Issue: "Cannot access Key Vault after disabling public access"

**Solution:** Same as above - access via private endpoint or Azure Portal.

### Issue: "App Service not accessible via Front Door"

**Check:**
1. Front Door endpoint is healthy
2. Backend pool is configured correctly
3. IP restrictions allow Front Door (check header validation)

### Issue: "Azure CLI commands fail"

**Solution:** Ensure you're authenticated:
```bash
az login
az account set --subscription "<subscription-id>"
```

---

## ✅ Completion Checklist

- [ ] Part 1: App Service IP Restrictions completed
- [ ] Part 2: Storage Account public access disabled
- [ ] Part 3: Key Vault public access disabled
- [ ] Part 4: Cosmos DB public access disabled
- [ ] Part 5: All resources verified
- [ ] Application tested via Front Door (works)
- [ ] Application tested via direct URL (blocked)

---

## 📞 Support

If you encounter issues:
1. Check Azure Portal for resource status
2. Review Azure Activity Log for errors
3. Verify network connectivity (private endpoints)
4. Contact Azure Support if needed

---

**Last Updated:** December 20, 2025  
**Version:** 1.0  
**Status:** Ready for Production Use

