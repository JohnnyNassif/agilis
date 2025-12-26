# Client Handover Pack - Agilis Infrastructure

This folder contains the documents intended to be delivered to the client for operating and deploying the Agilis platform on Azure.

---

## What the client can do with this pack

- Deploy the **frontend** to Azure Static Web Apps
- Deploy the **backend application code** to Azure App Service
- Perform required **security hardening** steps before storing PHI
- Monitor the platform using **Front Door**, **App Service**, **App Insights**, **Log Analytics**, and **Sentinel**

---

## Documents (deliver these)

### Deployment
- `FRONTEND_DEPLOYMENT_GUIDE.md`
- `BACKEND_APP_DEPLOYMENT_GUIDE.md`
- `RELEASE_PROCESS_AND_SUPPORT.md`
- `CUSTOM_DOMAIN_AND_DNS_SETUP.md`
- `ENVIRONMENT_CONFIGURATION_REQUESTS.md`

### Security & Verification
- `SECURITY_HARDENING_AND_VERIFICATION.md`
- `BAA_SIGNING_GUIDE.md`

### Operations
- `OPERATIONS_AND_MONITORING_GUIDE.md`
- `BACKUPS_AND_RECOVERY_EXPECTATIONS.md`
- `INCIDENT_RESPONSE_AND_SECURITY_EVENTS.md`
- `JUMP_BOX_OPERATIONS_GUIDE.md`
- `SENTINEL_GUIDE.md`

---

## Infrastructure change policy

- Infrastructure creation/updates (Terraform) are performed by the **Agilis operator** only.
- If the client needs infrastructure changes (new environments, scaling, new alert destinations, domain changes), submit a request to the Agilis operator.

---

## Related reference documents (optional to include)

These are more “reference” than “runbook”, but can be shared with client IT/security teams:
- `../shared/ARCHITECTURE_DIAGRAM.md`
- `../shared/AZURE_POLICY_VS_INITIATIVE.md`
- `../shared/POST_DEPLOYMENT_CHECKLIST.md`
- `../shared/HIPAA_COMPLIANCE_MANUAL_CHECKLIST.md`


