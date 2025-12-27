# Post-deployment HIPAA remediation steps (PROD)

**Purpose:** Engineering-only, command-line remediation steps to bring the **current deployed** Azure environment into a HIPAA-aligned posture (technical safeguards + auditability).  
**Non-goal:** This is not legal certification.

**Scope:** `rg-agilis-prod-core` (Central US), subscription `29751eff-5ecd-42aa-97cc-6f0799bf7365`

**Important:** These steps are **manual**, **post-deploy**, and were derived from live validation results. At the time of assessment:
- Storage + Key Vault were compliant (public network access disabled; diagnostic/audit logs present).
- App Service ingress restrictions were **NOT** configured (all 3 backends were publicly reachable).
- Cosmos DB `publicNetworkAccess` was **Enabled**.
- Subscription Activity Log was **NOT** exported to Log Analytics (AzureActivity table empty).
- NSG Flow Logs + Traffic Analytics were enabled, but **Traffic Analytics data was not landing** in Log Analytics.

---

## Prereqs

### Auth + safety
- Confirm you are in the correct tenant/subscription:

```bash
az account show -o table
```

- Set shell variables (Git Bash):

```bash
export MSYS_NO_PATHCONV=1

SUBSCRIPTION_ID="29751eff-5ecd-42aa-97cc-6f0799bf7365"
RG="rg-agilis-prod-core"
LAW_NAME="law-agilis-prod"

APP_MAIN="app-agilis-prod-api-p1"
APP_WHITEBOARD="app-agilis-prod-api-white-board"
APP_TELEMED="app-agilis-prod-api-telemed"

COSMOS="cosmosagilisprodprod"
STORAGE="stagilisprodh5xc"
KV="kvagilisprod0rv9"

FD_PROFILE="fd-agilis-prod"
FD_ID="081cc030-f12a-4d78-b128-884c433e1168"
```

---

## 1) Enforce Front Door–only ingress to App Services (P0: Required)

**Goal:** Block direct access to `*.azurewebsites.net` and restrict both **main site** and **SCM/Kudu** to Azure Front Door.

### 1.0 Prereq: Confirm the Front Door ID (FDID)

The access restriction allow rule should validate the header `x-azure-fdid` against the Front Door Profile `frontDoorId`.

**Recommended (works reliably in Git Bash):**

```bash
export MSYS_NO_PATHCONV=1

FD_PROFILE_ID=$(az resource show \
  --resource-group "$RG" \
  --resource-type "Microsoft.Cdn/profiles" \
  --name "$FD_PROFILE" \
  --query id -o tsv)

FD_ID=$(az rest --method get --url "https://management.azure.com${FD_PROFILE_ID}?api-version=2023-05-01" \
  --query "properties.frontDoorId" -o tsv)

echo "FD_PROFILE_ID=$FD_PROFILE_ID"
echo "FD_ID=$FD_ID"
```

### 1.1 Verify current state (should NOT be “Allow all”)

```bash
for APP in "$APP_MAIN" "$APP_WHITEBOARD" "$APP_TELEMED"; do
  echo "== $APP =="
  az webapp config access-restriction show -g "$RG" -n "$APP" \
    --query "{main:ipSecurityRestrictions, scm:scmIpSecurityRestrictions, scmUseMain:scmIpSecurityRestrictionsUseMain}" -o jsonc
done
```

### 1.2 Configure main-site access restrictions

For each app (`$APP_MAIN`, `$APP_WHITEBOARD`, `$APP_TELEMED`):

```bash
for APP in "$APP_MAIN" "$APP_WHITEBOARD" "$APP_TELEMED"; do
  echo "Configuring MAIN site restrictions for $APP"

  # Allow Front Door backend service tag WITH header validation
  az webapp config access-restriction add \
    --resource-group "$RG" \
    --name "$APP" \
    --rule-name "AllowFrontDoor" \
    --action Allow \
    --priority 100 \
    --service-tag AzureFrontDoor.Backend \
    --http-header "x-azure-fdid=$FD_ID"

  # Deny all other ingress
  az webapp config access-restriction add \
    --resource-group "$RG" \
    --name "$APP" \
    --rule-name "DenyAll" \
    --action Deny \
    --priority 2147483647 \
    --ip-address "0.0.0.0/0"
done
```

### 1.3 Configure SCM/Kudu access restrictions

**Note:** Azure CLI `2.45.0` does not support `--scm-site` for the `show` command, but it does for `add`. Use `--scm-site true` when adding SCM rules.

```bash
for APP in "$APP_MAIN" "$APP_WHITEBOARD" "$APP_TELEMED"; do
  echo "Configuring SCM site restrictions for $APP"

  az webapp config access-restriction add \
    --resource-group "$RG" \
    --name "$APP" \
    --rule-name "AllowFrontDoor-SCM" \
    --action Allow \
    --priority 100 \
    --service-tag AzureFrontDoor.Backend \
    --http-header "x-azure-fdid=$FD_ID" \
    --scm-site true

  az webapp config access-restriction add \
    --resource-group "$RG" \
    --name "$APP" \
    --rule-name "DenyAll-SCM" \
    --action Deny \
    --priority 2147483647 \
    --ip-address "0.0.0.0/0" \
    --scm-site true
done
```

### 1.4 Verification (required evidence)
- CLI evidence (expect to see **AllowFrontDoor** + **DenyAll** in both sections):

```bash
for APP in "$APP_MAIN" "$APP_WHITEBOARD" "$APP_TELEMED"; do
  echo "== $APP (post-change) =="
  az webapp config access-restriction show -g "$RG" -n "$APP" -o jsonc
done
```

- Verify the rule content (spot-check):
  - In `ipSecurityRestrictions`: `AllowFrontDoor` should show `tag`/service tag `AzureFrontDoor.Backend` and `headers` containing `x-azure-fdid` with the expected value.
  - In `scmIpSecurityRestrictions`: `AllowFrontDoor-SCM` and `DenyAll-SCM` should be present.

- Functional test (expected behaviors):
  - Direct access should fail:
    - `https://$APP_MAIN.azurewebsites.net`
    - `https://$APP_WHITEBOARD.azurewebsites.net`
    - `https://$APP_TELEMED.azurewebsites.net`
  - Access via Front Door should succeed (replace with your API health endpoints).

---

## 2) Disable Cosmos DB public network access (P0: Required)

**Current observed state:** `publicNetworkAccess=Enabled` (NOT acceptable for ePHI boundary).

### 2.1 Apply lockdown

```bash
az cosmosdb update \
  --resource-group "$RG" \
  --name "$COSMOS" \
  --public-network-access Disabled
```

### 2.2 Verify

```bash
az cosmosdb show -g "$RG" -n "$COSMOS" --query "{publicNetworkAccess:publicNetworkAccess, isVnetFilterEnabled:isVirtualNetworkFilterEnabled}" -o table
```

**Expected:** `publicNetworkAccess Disabled` and `isVnetFilterEnabled True`.

---

## 2.3 (Recommended) Disable Storage “blob public access” capability

Even with `publicNetworkAccess=Disabled` and private containers, explicitly disabling blob public access prevents accidental configuration drift.

```bash
az storage account update \
  --resource-group "$RG" \
  --name "$STORAGE" \
  --allow-blob-public-access false

az storage account show -g "$RG" -n "$STORAGE" --query "{allowBlobPublicAccess:allowBlobPublicAccess}" -o table
```

---

## 3) Export subscription Activity Log to Log Analytics (P0: Required)

**Why:** HIPAA audit controls require an auditable trail of administrative/control-plane actions (creation/deletion/updates to resources, RBAC changes, etc.). Without this, `AzureActivity` is empty.

**Note:** This is now intended to be handled by Terraform (subscription-scoped diagnostic settings). If you are deploying a new environment, you should only need to **verify** this is present.

### 3.1 Create subscription diagnostic setting

```bash
LAW_ID=$(az monitor log-analytics workspace show -g "$RG" -n "$LAW_NAME" --query id -o tsv)

az monitor diagnostic-settings subscription create \
  --name "diag-subscription-activity-to-law" \
  --workspace "$LAW_ID" \
  --logs '[{"category":"Administrative","enabled":true},{"category":"Security","enabled":true},{"category":"ServiceHealth","enabled":true},{"category":"Alert","enabled":true},{"category":"Recommendation","enabled":true},{"category":"Policy","enabled":true},{"category":"Autoscale","enabled":true},{"category":"ResourceHealth","enabled":true}]'
```

### 3.2 Verify export is configured

```bash
az monitor diagnostic-settings subscription list -o jsonc
```

### 3.3 Verify data is arriving (KQL)
Wait 10–30 minutes after enabling, then validate in Log Analytics/Sentinel:

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| take 50
```

---

## 4) NSG Flow Logs + Traffic Analytics: ensure ingestion is actually working (P1: Required in this environment)

**Observed:** Flow logs were enabled and Traffic Analytics was set `enabled=true`, but **no TA data** was present in Log Analytics (no `AzureNetworkAnalytics_CL` table; TA search over 7 days returned 0).

### 4.1 Confirm flow log configuration (should show Enabled=True, TaEnabled=True)

```bash
az network watcher flow-log list --location centralus \
  --query "[].{name:name,enabled:enabled,retentionDays:retentionPolicy.days,taEnabled:flowAnalyticsConfiguration.networkWatcherFlowAnalyticsConfiguration.enabled,workspace:flowAnalyticsConfiguration.networkWatcherFlowAnalyticsConfiguration.workspaceId}" \
  -o table
```

### 4.2 Confirm the Log Analytics workspace ID used by Traffic Analytics

```bash
az monitor log-analytics workspace show -g "$RG" -n "$LAW_NAME" --query "{name:name,customerId:customerId,location:location,id:id}" -o jsonc
```

### 4.3 Troubleshooting actions (apply in order)

- **Wait window**: Traffic Analytics is not real-time. After enablement/changes, allow **1–2 hours** for ingestion.
- **Confirm Network Watcher** exists in the region (`NetworkWatcher_centralus` in `NetworkWatcherRG`).
- **Confirm the flow log storage account** used by the flow log resources is reachable by Network Watcher.
- **If tables never appear after a full day**: re-create the flow logs for each NSG with explicit `--workspace`, `--workspace-region`, and `--traffic-analytics true` (use the same retention days).

> Note: The exact `az network watcher flow-log create/update` parameters vary by Azure CLI version. Validate flags with `-h` before running.

### 4.4 Evidence queries (KQL)

Once ingestion is working, at least one of these should return results:

```kusto
search "TrafficAnalytics" or "AzureNetworkAnalytics"
| where TimeGenerated > ago(24h)
| take 200
```

And NSG diagnostics should continue to be populated:

```kusto
AzureDiagnostics
| where TimeGenerated > ago(24h)
| where Category in ("NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter")
| take 200
```

---

## 5) Bastion/jump VM auditability (P1: Required in this environment)

### 5.1 Verify Bastion diagnostic settings exist (BastionAuditLogs enabled)

```bash
az rest --method get --url "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.Network/bastionHosts/bas-agilis-prod/providers/Microsoft.Insights/diagnosticSettings?api-version=2021-05-01-preview" -o jsonc
```

### 5.2 Verify AMA + DCR exist for Windows event collection

```bash
az vm extension list -g "$RG" --vm-name vm-agilis-prod-jmp -o table

az resource show -g "$RG" --resource-type Microsoft.Insights/dataCollectionRules -n dcr-agilis-prod-jmp-wev -o jsonc
```

### 5.3 Verify Windows events landing (KQL)

```kusto
search "WindowsEvent" or "SecurityEvent"
| where TimeGenerated > ago(24h)
| take 50
```

---

## Appendix A — Current resource inventory (PROD)

```bash
az resource list -g "$RG" --query "[].{name:name,type:type,location:location}" -o table
```

## Appendix B — Known CLI limitations in this environment

- Azure CLI version observed: `2.45.0`.
- `az monitor log-analytics query` prompted for extension install in non-interactive runs; use the Sentinel UI for KQL, or call the Log Analytics REST API if you need automation.
- In Git Bash, use `export MSYS_NO_PATHCONV=1` when passing Azure resource IDs.