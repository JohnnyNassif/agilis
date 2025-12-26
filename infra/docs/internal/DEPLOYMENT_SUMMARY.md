# Multi-App Support - Implementation Summary

**Date:** December 18, 2025  
**Status:** ℹ️ Historical summary (verify current Terraform state before using)

---

## 🎯 What Was Implemented

Your infrastructure now supports **6 separate applications** (3 frontends + 3 backends):

### Applications

| # | Application | Frontend | Backend | SKU (Prod) | Purpose |
|---|-------------|----------|---------|------------|---------|
| 1 | **Main Portal** | Static Web App | App Service | Standard / P1v3 | Primary portal (via Front Door) |
| 2 | **Whiteboard** | Static Web App | App Service | Free / B1 | Drawing tool (iframe embedded) |
| 3 | **Telehealth** | Static Web App | App Service | Free / B1 | Video calls (iframe embedded) |

### Architecture Highlights

✅ **Main Portal** is exposed via Front Door (WAF protected)  
✅ **Whiteboard & Telehealth** may use direct URLs (embedded in Main Portal via iframes) depending on your chosen Front Door routing approach  
✅ **All backends** share the same VNet, Key Vault, Cosmos DB, and Storage  
✅ **Cost-optimized** - Whiteboard/Telehealth use minimal B1/Free tiers  

---

## 📁 Files Modified

### 1. **infra/main.tf**
- Added 3 new module calls for whiteboard frontend/backend
- Added 3 new module calls for telehealth frontend/backend
- Total: 6 applications (3 original + 3 new)

### 2. **infra/variables.tf**
- Added 12 new variables for whiteboard/telehealth configuration
  - `app_service_whiteboard_sku_name` (default: B1)
  - `app_service_whiteboard_plan_capacity` (default: 1)
  - `app_service_whiteboard_always_on` (default: false)
  - `app_service_telehealth_sku_name` (default: B1)
  - `app_service_telehealth_plan_capacity` (default: 1)
  - `app_service_telehealth_always_on` (default: false)
  - `static_web_app_whiteboard_sku_tier` (default: Free)
  - `static_web_app_whiteboard_sku_size` (default: Free)
  - `static_web_app_whiteboard_app_settings` (default: {})
  - `static_web_app_telehealth_sku_tier` (default: Free)
  - `static_web_app_telehealth_sku_size` (default: Free)
  - `static_web_app_telehealth_app_settings` (default: {})

### 3. **infra/outputs.tf**
- Added 12 new outputs for whiteboard/telehealth resources
  - URLs, IDs, names, API keys for all 4 new resources

### 4. **infra/environments/dev/dev.auto.tfvars**
- Configured whiteboard/telehealth apps with Free/B1 tiers
- All apps use minimal resources for development

### 5. **infra/environments/prod/prod.auto.tfvars**
- Main app: Standard Static Web App + P1v3 App Service (production-grade)
- Whiteboard: Free Static Web App + B1 App Service (minimal tier)
- Telehealth: Free Static Web App + B1 App Service (minimal tier)
- **Total estimated cost:** ~$161/month for all 6 apps

### 6. **infra/docs/archive/MULTI_APP_ARCHITECTURE.md** (Archived reference)
- Comprehensive documentation on multi-app architecture
- Deployment guide
- Frontend integration examples (Angular + iframes)
- Security considerations (CORS, CSP, auth tokens)
- Testing guide
- Cost breakdown

---

## 💰 Cost Impact

### Before (Single App)
- Main Frontend: $0 (Free) / $25 (Standard)
- Main Backend: $13 (B1) / $110 (P1v3)
- **Total:** $13-135/month

### After (Multi-App)
- Main Frontend: $0 (Free) / $25 (Standard)
- Main Backend: $13 (B1) / $110 (P1v3)
- Whiteboard Frontend: $0 (Free)
- Whiteboard Backend: $13 (B1)
- Telehealth Frontend: $0 (Free)
- Telehealth Backend: $13 (B1)
- **Total:** $39-161/month

### Cost Increase
- **Development:** +$26/month (2 extra App Services)
- **Production:** +$26/month (2 extra App Services)

**Note:** This is cost-optimized! Whiteboard/Telehealth use minimal tiers since they have low load.

---

## 🚀 Deployment Steps

### Step 1: Initialize Terraform (if needed)

```bash
cd infra/environments/prod
terraform init
```

### Step 2: Review Changes

```bash
terraform plan
```

**Expected Output:**
- ✅ 4 new resources to be created (2 Static Web Apps + 2 App Services)
- ✅ Existing resources unchanged

### Step 3: Apply Changes

```bash
terraform apply
```

**Confirm:** Type `yes` when prompted

### Step 4: Capture Outputs

```bash
terraform output

# Save these values for CI/CD:
terraform output -raw static_web_app_whiteboard_api_key > .secrets/whiteboard_api_key.txt
terraform output -raw static_web_app_telehealth_api_key > .secrets/telehealth_api_key.txt
```

### Step 5: Deploy Frontend Apps

```bash
# Main Portal (no changes needed if already deployed)
cd main-portal
npm run build:prod
az staticwebapp deploy --name swa-agilis-prod --api-key <MAIN_API_KEY>

# Whiteboard
cd whiteboard-frontend
npm run build:prod
az staticwebapp deploy --name swa-agilis-prod-whiteboard --api-key <WHITEBOARD_API_KEY>

# Telehealth
cd telehealth-frontend
npm run build:prod
az staticwebapp deploy --name swa-agilis-prod-telehealth --api-key <TELEHEALTH_API_KEY>
```

### Step 6: Deploy Backend APIs

```bash
# Main Backend (no changes if already deployed)
cd main-backend
az webapp up --name app-agilis-prod-api --resource-group rg-agilis-prod-core

# Whiteboard Backend
cd whiteboard-backend
az webapp up --name app-agilis-prod-api-whiteboard --resource-group rg-agilis-prod-core

# Telehealth Backend
cd telehealth-backend
az webapp up --name app-agilis-prod-api-telehealth --resource-group rg-agilis-prod-core
```

### Step 7: Update Main Portal Frontend

Update your main portal's environment config with the new URLs:

```typescript
// main-portal/src/environments/environment.prod.ts
export const environment = {
  production: true,
  apiUrl: 'https://portal.agilis.com/api',
  whiteboardUrl: 'https://swa-agilis-prod-whiteboard.azurestaticapps.net',
  telehealthUrl: 'https://swa-agilis-prod-telehealth.azurestaticapps.net'
};
```

Redeploy main portal with updated config.

### Step 8: Verify Deployment

```bash
# Test all apps are accessible
curl https://swa-agilis-prod.azurestaticapps.net/
curl https://swa-agilis-prod-whiteboard.azurestaticapps.net/
curl https://swa-agilis-prod-telehealth.azurestaticapps.net/

# Test backends
curl https://app-agilis-prod-api.azurewebsites.net/api/health
curl https://app-agilis-prod-api-whiteboard.azurewebsites.net/api/health
curl https://app-agilis-prod-api-telehealth.azurewebsites.net/api/health
```

---

## ✅ Validation Checklist

After deployment, verify:

- [ ] All 6 applications are running
- [ ] Main portal loads via Front Door
- [ ] Whiteboard iframe loads within main portal
- [ ] Telehealth iframe loads within main portal
- [ ] No CORS errors in browser console
- [ ] Main backend can access Cosmos DB (via Key Vault connection string)
- [ ] Main backend can access Storage (via Key Vault secrets)
- [ ] Application Insights shows telemetry from all 3 backends
- [ ] Log Analytics shows logs from all 6 applications
- [ ] Front Door routes API paths correctly:
  - `/api/*` → main backend
  - `/api/telehealth/*` → telehealth backend (rewritten to `/api/*` at origin)
  - `/api/whiteboard/*` → whiteboard backend (rewritten to `/api/*` at origin)

---

## 🔧 Rollback Plan

If deployment fails, rollback is simple:

```bash
cd infra/environments/prod
terraform destroy -target=module.static_web_app_whiteboard
terraform destroy -target=module.static_web_app_telehealth
terraform destroy -target=module.app_service_whiteboard
terraform destroy -target=module.app_service_telehealth
```

This will remove only the new resources, leaving your main app untouched.

---

## 📚 Additional Documentation

- **Multi-App Architecture (archived):** `../archive/MULTI_APP_ARCHITECTURE.md`
- **Storage Lifecycle Policy:** `../shared/STORAGE_LIFECYCLE_POLICY.md`
- **Frontend Deployment:** `../client/FRONTEND_DEPLOYMENT_GUIDE.md`
- **Infrastructure Review:** `INFRASTRUCTURE_REVIEW.md` (this folder)

---

## 🎯 Next Steps

1. **Development:** Deploy to dev environment first for testing
2. **Testing:** Verify iframe integration works correctly
3. **Production:** Deploy to production after successful dev testing
4. **Monitoring:** Set up alerts for the new applications
5. **Documentation:** Update internal docs with new URLs

---

## ❓ FAQ

### Q: Can I add more apps in the future?

**A:** Yes! Just duplicate the module calls in `main.tf` and add corresponding variables/outputs. The pattern is established and easily extendable.

### Q: Can I change the SKU tiers later?

**A:** Yes! Just update the variables in `prod.auto.tfvars` and run `terraform apply`. No data loss.

### Q: Do I need separate databases for each app?

**A:** No. All apps share the same Cosmos DB database. Use tenant isolation at the application level (multi-tenancy).

### Q: Can I put whiteboard/telehealth behind Front Door too?

**A:** Yes. You can add additional origins/routes to the existing Front Door profile (path-based routing). This typically does **not** require additional Front Door profiles; validate cost impact based on your traffic volume and rules.

### Q: What if I only want to add whiteboard first?

**A:** Just remove the telehealth module calls from `main.tf` and the corresponding variables. Terraform is modular.

---

**Code Status:** ℹ️ Historical note (verify current repo state before use)
**Ready for Deployment:** ✅ Depends on current environment configuration + post-deployment hardening completion

---

**Last Updated:** December 18, 2025  
**Author:** AI Infrastructure Assistant  
**Client:** Agilis Dental


