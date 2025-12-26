# Release Process and Support (Client)

This document explains how the client releases **frontend** and **backend** application code, how to verify a release, how to roll back, and what information to provide when escalating issues.

**Important:** Infrastructure changes (Terraform) are performed by the Agilis operator.

---

## Roles and responsibilities

- **Client**:
  - Deploy frontend application code (Static Web Apps)
  - Deploy backend application code (App Service)
  - Perform release verification checks
  - Monitor and report incidents with required details
- **Agilis operator**:
  - Manages infrastructure, networking, private endpoints/DNS, and access restrictions
  - Adjusts Front Door routing, WAF, and platform-level configuration when requested

---

## Release checklist (recommended order)

1) **Backend release**
- Deploy backend to App Service (see `BACKEND_APP_DEPLOYMENT_GUIDE.md`)

2) **Backend verification**
- Verify API health through Front Door (see verification section below)

3) **Frontend release**
- Deploy Angular frontend to Static Web Apps (see `FRONTEND_DEPLOYMENT_GUIDE.md`)

4) **End-to-end verification**
- Validate key user journeys in the portal
- Confirm error rates are normal in Application Insights

---

## Post-release verification (required)

### 1) Verify Front Door is reachable
```bash
curl -I https://<FRONTDOOR_HOST>/
```

### 2) Verify API through Front Door (not azurewebsites)
If you have a health endpoint (recommended):

```bash
curl -i https://<FRONTDOOR_HOST>/api/health
```

If you do not have a health endpoint, validate at least one read-only endpoint via Front Door.

### 3) Verify frontend portal
- Load portal URL via Front Door
- Verify login (if applicable)
- Verify at least one page that calls the backend API

### 4) Verify monitoring shows normal behavior
In Azure Portal:
- Application Insights → **Failures**: check last 30–60 minutes
- Application Insights → **Performance**: verify no major degradation
- Front Door → **Monitoring**: origin health OK

---

## Rollback procedures

### Backend rollback (App Service)
Preferred rollback method depends on how you deploy:
- **GitHub Actions / Deployment Center**: redeploy the previous known-good commit/tag (re-run the workflow for that ref).
- **ZIP deploy**: redeploy the last known-good zip artifact.

After rollback:
- Re-run the post-release verification checks.

### Frontend rollback (Static Web Apps)
- Redeploy the previous known-good build/commit using your chosen deployment path (GitHub Actions / SWA CLI / portal token workflow).
- Verify portal and API calls again.

---

## Support / escalation (what to send)

When reporting an issue to the Agilis operator, include:
- **Environment**: dev / prod
- **Timestamp** (UTC)
- **Affected URL(s)**: include the full URL and path (Front Door URL)
- **What changed**: frontend release, backend release, config change, etc.
- **Screenshots**:
  - Front Door error response (if any)
  - App Service status (Running/Stopped)
  - Application Insights failure summary

If possible, also include:
- **Correlation/request ID** from response headers (if your API returns one)
- **Exact error message** and HTTP status code

---

## When to escalate immediately

- Sustained **5xx** errors (502/503/500) through Front Door
- Authentication failures affecting all users
- Suspected security incident (WAF spike, suspicious access patterns)
- Loss of access to PHI-related resources or failures in key workflows (upload/download)




