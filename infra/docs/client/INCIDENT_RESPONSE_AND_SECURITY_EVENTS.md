# Incident Response and Security Events Playbook (Client)

This playbook explains how to triage outages and security events, what to check in Azure, and what information to send to the Agilis operator for fast remediation.

**Important:** Infrastructure changes are performed by the Agilis operator. The client performs triage and escalation.

---

## Severity levels (simple)

- **P0 (Critical):** Full outage, PHI access broken, sustained 5xx, or suspected security incident
- **P1 (High):** Major feature broken for many users, intermittent 5xx, elevated error rate
- **P2 (Normal):** Single feature bug, isolated user impact, minor performance issues

---

## First 10 minutes triage (do this first)

1) **Confirm scope**
- Which environment: dev / prod
- Which surface: portal UI / API / login / file upload / other
- First observed time (UTC)

2) **Confirm Front Door behavior**
- Try the portal URL in a private/incognito window
- Capture the HTTP status and error page if present

3) **Confirm backend health through Front Door**
If available:

```bash
curl -i https://<FRONTDOOR_HOST>/api/health
```

4) **Capture evidence**
- Screenshot of the error (browser + network tab if possible)
- Exact failing URL(s)

---

## Where to look (symptom → Azure checks)

### A) 502/503 from Front Door
Likely origin health / backend issue.

Check:
- Front Door → **Monitoring**: origin health probe status
- App Service → **Overview**: Running/Stopped
- Application Insights → **Failures**: top failing requests

### B) 403 Forbidden / blocked access
Likely WAF or access restrictions.

Check:
- Front Door (WAF) logs: WAF blocks/spikes
- App Service → Networking → **Access Restrictions** (rules present/unchanged)

### C) API works yesterday, now 500 errors
Likely backend release regression.

Check:
- Application Insights → **Failures**
- Application Insights → **Logs**: exceptions around incident time
- App Service → **Log stream** (short-term)

Rollback:
- Follow `RELEASE_PROCESS_AND_SUPPORT.md`

### D) Files upload/download failing
Likely dependency (Storage) access or app bug.

Check:
- Application Insights dependency failures
- Log Analytics (if available) for Storage logs
- Provide the failing file action, timestamp, and user/tenant context

### E) Suspected security incident
Examples:
- sudden spike in WAF blocks
- suspicious sign-in patterns
- unexpected data access behavior

Check:
- Front Door WAF logs: top rules triggered, IPs, paths
- Sentinel → **Incidents** (if enabled)
- Azure Activity Log: recent privileged changes (if you have access)

Immediately escalate (P0).

---

## What to send to the Agilis operator (required)

Include:
- **Severity:** P0/P1/P2
- **Environment:** dev/prod
- **Timestamp range (UTC):** start time and “still ongoing?” yes/no
- **Affected URL(s):** full URL + path (Front Door/custom domain)
- **What changed recently:** backend release / frontend release / config change request / none
- **Screenshots**:
  - browser error page + network tab (if available)
  - Front Door origin health (if relevant)
  - Application Insights failures summary

If available, add:
- Request/correlation IDs from response headers
- App Service deployment ID/commit (if using GitHub Actions)

---

## Safe immediate actions the client can take

- Roll back the last **application** release (frontend or backend) if the incident started right after a release.
- Disable a newly introduced feature flag (if your app supports it and the operator has provided a safe mechanism).

Do **not**:
- Change Front Door routes/WAF rules
- Change access restrictions
- Change public network access settings
- Change Key Vault/Cosmos/Storage configuration

---

## Post-incident checklist (recommended)

- Record timeline: detection → mitigation → resolution
- Document root cause (app vs infra) and follow-up actions
- Add/adjust monitoring alerts if the incident was not detected quickly




