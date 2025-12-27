# Security Hardening and Verification

This document describes the **required** security hardening steps and verification checks to perform after Terraform deployment, especially for environments that will store **PHI**.

---

## When to perform these steps

- After the Agilis operator completes infrastructure deployment
- Before storing any PHI

---

## Hardening checklist (authoritative)

Use the shared checklist as the step-by-step source of truth:
- `../shared/HIPAA_COMPLIANCE_MANUAL_CHECKLIST.md`

This covers:
- App Service access restrictions (**Front Door only + deny all**, including **SCM/Kudu**)
- Disable public network access for Storage Account, Key Vault, and Cosmos DB (and confirm firewall defaults)
- Verification steps (private DNS + access)

---

## Critical verification (what “done” means)

### 1) App Service is not publicly reachable
- `https://<app>.azurewebsites.net` should be **blocked**
- Only Azure Front Door should be able to reach the backend

### 2) Storage / Key Vault / Cosmos DB public access is disabled
- Portal checks show public network access disabled
- Private endpoint DNS resolution works from inside the VNet (jump VM)

**Key Vault note:** For hardened environments, Key Vault network ACLs should be set to **Default action: Deny** with **Bypass: None**, and **Public network access: Disabled**.

### 3) Logging/monitoring is active
- App Insights receiving telemetry
- Diagnostic logs flowing to Log Analytics
- Sentinel (if enabled) shows data connectors/analytics rules running

Use:
- `../shared/POST_DEPLOYMENT_CHECKLIST.md`

---

## Important note (Terraform from local machine)

Infrastructure changes are performed by the Agilis operator. If hardening steps are pending or verification fails, escalate to the Agilis operator for remediation.


