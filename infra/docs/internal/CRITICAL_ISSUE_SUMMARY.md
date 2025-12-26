# ✅ Cosmos DB Authentication Note (Resolved)

**Date:** December 17, 2025
**Status:** RESOLVED (configuration updated)

---

## Summary

Historically, this repo had `local_authentication_disabled = true` in the Cosmos DB module, which would break connection-string authentication. The current code has been updated to allow connection-string authentication.

---

## Technical Details

**File:** `infra/modules/cosmos_mongo/main.tf` (Line 22)

**Expected current value:**

```terraform
local_authentication_disabled = false
```

---

## What to do

### Verify the config (recommended)
- Confirm `infra/modules/cosmos_mongo/main.tf` has `local_authentication_disabled = false`.
- Deploy and run an application-level database connectivity check (recommended: a `/health/database` endpoint or equivalent).

---

## Optional future improvement
If you want to avoid key-based connection strings entirely, you can consider moving to Azure AD/RBAC-based authentication for Cosmos DB in a future iteration (requires app changes and careful driver support validation).

---

