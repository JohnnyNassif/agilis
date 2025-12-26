# Deployment Readiness Checklist

**Date:** December 17, 2025
**Environment:** Development / Production

Use this checklist to ensure your infrastructure is ready for deployment.

**Canonical reference:** `infra/docs/internal/DEPLOYMENT_RUNBOOK.md` (this folder)

---

## ✅ Pre-Deployment (MUST DO)

### Critical Issue Fix
- [ ] **Cosmos DB auth check:** Verify `local_authentication_disabled = false` in `infra/modules/cosmos_mongo/main.tf` (line 22)
  - This repo uses a primary-key-based connection string; disabling local authentication would break app connectivity.
  - See `CRITICAL_ISSUE_SUMMARY.md` for context (this folder)

### Azure Prerequisites
- [ ] Azure CLI installed (`az --version`)
- [ ] Authenticated to Azure (`az login` or service principal configured)
- [ ] Terraform >= 1.5.0 installed (`terraform --version`)
- [ ] Target subscription has sufficient quota
- [ ] Subscription has required resource providers registered

### Configuration Files
- [ ] `infra/environments/<env>/<env>.auto.tfvars` file populated
- [ ] `subscription_id` and `tenant_id` configured
- [ ] `infra/environments/<env>/backend.tf` configured (after bootstrap)

---

## 🔧 Configuration Review (Development)

### Development Settings (Already Configured ✅)
- [x] `app_service_sku_name = "B1"` (supports VNet integration)
- [x] `app_service_always_on = false` (cost savings)
- [x] `app_service_enable_ip_restrictions = false` (easier testing)
- [x] `cosmos_free_tier_enabled = true` (free tier)
- [x] `bastion_enabled = true` (for database access)
- [x] Public access hardening is completed manually post-deploy (see shared checklist)
- [x] `frontdoor_sku_name = "Premium_AzureFrontDoor"` (includes OWASP rules)

### Optional Adjustments
- [ ] Adjust `cosmos_mongo_database_max_throughput` if needed (default: 1000 RU/s)
- [ ] Add admin user Object IDs to `rbac_admin_user_principal_ids` (if needed)
- [ ] Configure alert recipients (optional for dev):
  - [ ] `security_alerts_email_addresses`
  - [ ] `security_alerts_sms_numbers`

---

## 🏭 Configuration Review (Production)

### Required Production Changes
- [ ] `app_service_sku_name = "P1v3"` or higher (production SLA)
- [ ] `app_service_always_on = true` (prevent cold starts)
- [ ] `app_service_enable_ip_restrictions = true` (block direct access)
- [ ] `cosmos_free_tier_enabled = false` (only 1 free tier per subscription)
- [ ] `cosmos_mongo_database_max_throughput = 4000` (or as needed)
- [ ] Complete post-deployment hardening checklist (disable public access + verify private access)
- [ ] `key_vault_purge_protection_enabled = true` (prevent accidental deletion)
- [ ] `rbac_enable_admin_users = true` (client admin access)
- [ ] `rbac_enable_current_user_access = false` (remove dev access)
- [ ] `rbac_admin_user_principal_ids = ["<object-id-1>", "<object-id-2>"]` (client admins)

### Required Production Alert Configuration
- [ ] `security_alerts_email_addresses = ["security@example.com"]`
- [ ] `security_alerts_sms_numbers = ["5551234567"]` (optional)
- [ ] `security_alerts_webhook_urls = ["https://..."]` (optional, e.g., Slack)

### Optional Production Settings
- [ ] Custom domain: `frontdoor_custom_domain_name = "api.example.com"`
- [ ] Custom domain: `static_web_app_custom_domain_name = "app.example.com"`
- [ ] Bastion: `bastion_enabled = false` (disable for cost savings if using VPN)
- [ ] Policy: `policy_enable_hipaa_initiative = true` (if available in subscription)

---

## 🚀 Deployment Steps

### Step 1: Bootstrap Remote State (One-Time per Environment)
```bash
cd infra/bootstrap/environments/<env>
terraform init
terraform plan -var-file="<env>.auto.tfvars"
terraform apply -var-file="<env>.auto.tfvars"
terraform output  # Copy these values to environment backend.tf
```

### Step 2: Configure Backend
- [ ] Update `infra/environments/<env>/backend.tf` with bootstrap outputs
- [ ] Verify values: `resource_group_name`, `storage_account_name`, `container_name`

### Step 3: Deploy Infrastructure
```bash
cd infra/environments/<env>
terraform init
terraform plan -var-file="<env>.auto.tfvars"  # Review carefully
terraform apply -var-file="<env>.auto.tfvars"
```

### Step 4: Wait for Completion
- [ ] Deployment completes without errors
- [ ] Note: Deployment can take **15-30 minutes** (Front Door is slow to provision)
- [ ] Capture outputs: `terraform output` (save Front Door hostname, Static Web App hostname)

---

## 🔍 Post-Deployment Verification

### Infrastructure Validation
- [ ] All resources created successfully (check Azure Portal)
- [ ] Front Door provisioning state is "Succeeded"
- [ ] Private endpoints in "Approved" state
- [ ] Diagnostic settings configured on all resources

### Network Connectivity
- [ ] Front Door endpoint accessible via browser (should see 404 or backend response)
- [ ] Direct App Service URL blocked (https://*.azurewebsites.net should be inaccessible)
- [ ] Static Web App URL accessible (frontend loads)

### Security Controls
- [ ] Public access disabled on Cosmos DB (Portal → Settings → Networking → "Public network access: Disabled")
- [ ] Public access disabled on Storage Account
- [ ] Public access disabled on Key Vault
- [ ] WAF in Prevention mode (if production)
- [ ] IP restrictions configured on App Service (Portal → Networking → Access Restrictions)

### Logging & Monitoring
- [ ] Log Analytics Workspace shows data flowing (wait 15-30 minutes)
- [ ] Application Insights receiving telemetry
- [ ] Sentinel onboarded successfully
- [ ] Check diagnostic settings on App Service, Cosmos, Storage, Key Vault, Front Door

### Application Connectivity (CRITICAL)
- [ ] **Test database connection** from App Service
  - Deploy a simple health check endpoint: `GET /health/database`
  - Verify it can connect to Cosmos DB
  - Check Application Insights for connection errors
- [ ] Test Key Vault access (secrets accessible via managed identity)
- [ ] Test Storage access (can upload/download files)

### Bastion Access (If Enabled)
- [ ] Bastion provisioned successfully
- [ ] Windows VM started and accessible via Bastion
- [ ] VM has connectivity to private endpoints
- [ ] Can access Cosmos DB using connection string from VM
- [ ] Auto-shutdown configured (check VM → Auto-shutdown settings)

---

## ⚠️ Common Issues and Solutions

### Issue: Terraform Errors on `azurerm_key_vault_secret`
**Symptom:** "AuthorizationFailed" or "Forbidden" errors when creating secrets

**Solutions:**
1. Wait 2-3 minutes after RBAC assignments (Azure AD propagation delay)
2. Run `terraform apply` again (idempotent)
3. Verify current user has "Key Vault Secrets Officer" role

---

### Issue: App Service Cannot Connect to Cosmos DB
**Symptom:** Connection timeout or authentication errors

**Solutions:**
1. **Check authentication config:** Ensure `local_authentication_disabled = false` ✅
2. Check private endpoint DNS resolution (should resolve to 10.10.2.x address)
3. Verify NSG rules allow VNet-to-VNet traffic
4. Wait 10-15 minutes for private DNS propagation
5. Restart App Service (`az webapp restart`)

---

### Issue: Front Door Shows "Origin Unhealthy"
**Symptom:** Front Door returns 503 Service Unavailable

**Solutions:**
1. Wait 10-15 minutes for Front Door provisioning to complete
2. Check health probe path is accessible on App Service
3. Verify App Service is running (not stopped)
4. Check Front Door → Monitoring → Health probe status

---

### Issue: Direct App Service Access Still Works
**Symptom:** Can access `*.azurewebsites.net` directly (should be blocked)

**Solutions:**
1. Verify `app_service_enable_ip_restrictions = true` in tfvars
2. Manually verify IP restrictions in Portal → App Service → Networking → Access Restrictions
3. Should see rules: "AllowFrontDoor" (priority 100), "DenyAll" (priority 2147483647)

---

### Issue: Storage Logs Not Appearing in Log Analytics
**Symptom:** No entries in `StorageBlobLogs` table

**Solutions:**
1. Wait 30-60 minutes for first logs to appear (initial delay is normal)
2. Verify diagnostic settings on Storage Account → Monitoring → Diagnostic settings
3. Check diagnostic settings on Blob Service (separate from Storage Account)
4. Trigger some storage activity (upload/download files)

---

### Issue: Sentinel Alerts Not Triggering
**Symptom:** No alerts/incidents in Sentinel despite suspicious activity

**Solutions:**
1. Verify Sentinel is onboarded (Portal → Microsoft Sentinel → workspace should be listed)
2. Check analytics rules are enabled (Sentinel → Analytics → Active rules)
3. Wait 15-30 minutes for rules to evaluate (based on `alert_frequency_minutes`)
4. Verify logs are flowing to Log Analytics (check relevant tables)
5. For WAF alerts: Ensure Front Door diagnostic settings include "FrontDoorWebApplicationFirewallLog"

---

## 📊 Success Criteria

### Development Environment
- ✅ All infrastructure deployed without errors
- ✅ Application can connect to Cosmos DB
- ✅ Front Door routing works (frontend and backend)
- ✅ Logs flowing to Log Analytics
- ✅ Bastion accessible (if enabled)

### Production Environment
- ✅ All development criteria met
- ✅ Public access disabled on all data services
- ✅ Direct App Service access blocked (only via Front Door)
- ✅ WAF in Prevention mode
- ✅ Security alerts configured and tested
- ✅ Admin users can access resources via Azure Portal
- ✅ Terraform service principal access working (for future deployments)

---

## 🎯 Post-Deployment Tasks

### Immediate (Within 24 Hours)
- [ ] Deploy application code to App Service
- [ ] Deploy frontend to Static Web App
- [ ] Test end-to-end user flows
- [ ] Trigger test security alerts (verify notifications received)
- [ ] Document Front Door endpoint URL for DNS/CDN configuration

### Within 1 Week
- [ ] Configure custom domains (if planned)
- [ ] Set up CI/CD pipelines for application deployments
- [ ] Review and tune Sentinel analytics rules (adjust thresholds if needed)
- [ ] Enable Azure Defender for Cloud (recommended)
- [ ] Schedule HIPAA compliance audit review

### Within 1 Month
- [ ] Review cost optimization opportunities
- [ ] Evaluate multi-region failover requirements
- [ ] Consider implementing Customer-Managed Keys (if required)
- [ ] Conduct security testing (penetration test if required)
- [ ] Review and update disaster recovery procedures

---

## 📞 Support Resources

### Documentation
- **Full Review:** `INFRASTRUCTURE_REVIEW.md` (comprehensive analysis; this folder)
- **Critical Issue:** `CRITICAL_ISSUE_SUMMARY.md` (database authentication fix; this folder)
- **Frontend Deployment:** `../client/FRONTEND_DEPLOYMENT_GUIDE.md`
- **Post-Deployment:** `../shared/POST_DEPLOYMENT_CHECKLIST.md`
- **HIPAA Manual Checklist:** `../shared/HIPAA_COMPLIANCE_MANUAL_CHECKLIST.md`
- **Pre-Deployment Review:** `PRE_DEPLOYMENT_REVIEW.md` (this folder)

### Azure Resources
- [Azure HIPAA Compliance](https://docs.microsoft.com/en-us/azure/compliance/offerings/offering-hipaa-us)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

**Last Updated:** December 17, 2025
**Version:** 1.0

