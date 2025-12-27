# Environment Configuration Requests

This document explains how the client requests application configuration changes (environment variables, feature flags, endpoints) for **dev/prod** environments.

**Important:** Infrastructure and platform configuration (Terraform) is managed by the **Agilis operator**. The client should not directly modify Key Vault, App Service configuration, networking, or Front Door without coordination.

---

## What configuration changes are supported

Common requests include:
- **Backend config** (App Service app settings):
  - feature flags (enable/disable modules)
  - third‑party integration settings (non-secret IDs, base URLs)
  - allowed origins (CORS) *if implemented at the app layer*
  - logging level (info/debug) if supported by the app
- **Frontend config** (Angular):
  - API base URL (usually Front Door + `/api`)
  - feature flags (if implemented in frontend)
- **Secrets** (Key Vault):
  - API keys/tokens/credentials for integrations (client provides securely)
  - rotation of existing secrets (scheduled or emergency)

---

## What is NOT supported as a “config request”

These require an infrastructure change request (Agilis operator):
- private endpoint / DNS changes
- Front Door routing/WAF rule changes
- App Service access restrictions changes
- disabling/enabling public network access on Storage/Key Vault/Cosmos
- adding new Azure resources

---

## How to submit a configuration request (template)

Copy/paste the following and fill it in:

### 1) Request metadata
- **Environment:** dev / prod
- **Requested by:** name + email
- **Urgency:** normal / urgent / emergency
- **Desired change window:** date/time range + timezone

### 2) What should change
- **Target:** backend / frontend / both
- **Setting name(s):** (exact key names)
- **New value(s):** (redact secrets if sending over email)
- **Is it a secret?** yes/no
  - If yes: provide via an approved secure channel (never in plain email/chat)

### 3) Why
- **Business reason:** short explanation
- **Expected impact:** what should change after this is applied

### 4) Verification plan
- **How to verify success:** endpoint(s) / user journey(s)
- **How to verify no regression:** key pages/flows to re-test

### 5) Rollback plan
- **Rollback method:** revert value(s) / redeploy previous app version
- **Owner:** who will approve rollback if needed

---

## How changes are applied (operator workflow)

Depending on the request, the Agilis operator will apply changes via:
- App Service configuration updates (app settings)
- Key Vault secret creation/rotation (and app settings reference updates, if applicable)
- Frontend rebuild/redeploy (if config is compile-time)

After the change, the operator will notify the client and request verification.

---

## Verification checklist

After you are told the change is applied:
1. Verify frontend loads (Front Door/custom domain)
2. Verify backend endpoints through Front Door (`/api/...`)
3. Check Application Insights for new errors in the last 15–30 minutes
4. Confirm expected behavior changed (feature flag, integration, etc.)

If verification fails, escalate using `RELEASE_PROCESS_AND_SUPPORT.md`.






