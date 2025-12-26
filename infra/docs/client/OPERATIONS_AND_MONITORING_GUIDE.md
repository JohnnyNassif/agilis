# Operations and Monitoring Guide (Client)

This guide describes what to monitor day-to-day, where to look when something breaks, and how to validate that the platform is operating as expected.

---

## Primary Azure resources to monitor

- **Azure Front Door (Premium)**: availability, routing, WAF blocks
- **App Service (Backend APIs)**: availability, errors, CPU/memory, restarts
- **Application Insights**: request failures, dependency failures, traces
- **Log Analytics Workspace**: platform + audit logs (WAF/Front Door, Key Vault audit, Cosmos requests, Storage blob logs, NSG logs, Bastion audit logs, Windows event logs from jump VM)
- **Microsoft Sentinel** (if enabled): incidents, analytics rules, connector health

---

## Daily checks (recommended)

### 1) Front Door availability
- Confirm Front Door endpoint responds:
  - `curl -I https://<frontdoor-endpoint>/`
- In Azure Portal:
  - Front Door → **Monitoring** → check origin health and metrics

### 2) Backend health (App Service)
- App Service → **Overview**: status “Running”
- App Service → **Diagnose and solve problems**: check for recent incidents
- App Service → **Monitoring**:
  - Metrics: HTTP 5xx, Requests, Average Response Time

### 3) Application Insights
- Application Insights → **Failures**:
  - Top failing operations
  - Dependency failures (Cosmos/Storage/Key Vault)
- Application Insights → **Logs**:
  - Search for exceptions in last 24h

---

## After each application release (recommended)

### Frontend release checks
- Load the main portal via the Front Door URL and verify:
  - login flow (if applicable)
  - core navigation
  - API calls succeed (no 4xx/5xx spikes)

### Backend release checks
- Verify API health via Front Door:
  - `curl -i https://<FRONTDOOR_HOST>/api/health` (or equivalent)
  - `curl -i https://<FRONTDOOR_HOST>/api/telehealth/health` (rewritten to `/api/health` on the telehealth backend)
  - `curl -i https://<FRONTDOOR_HOST>/api/whiteboard/health` (rewritten to `/api/health` on the whiteboard backend)
- Watch Application Insights for:
  - request failures
  - dependency failures
  - unhandled exceptions

### 4) Log Analytics
- Ensure logs are present for:
  - Front Door WAF logs
  - Key Vault audit events
  - Storage blob logs (via blob service diagnostic settings)
  - Cosmos DB requests
  - NSG diagnostic logs (events + rule counters)
  - Bastion audit logs
  - Jump VM Windows event logs (Security/System/Application) via AMA + DCR

### 5) Sentinel (if enabled)
- Sentinel → **Incidents**: review new incidents
- Sentinel → **Analytics**: ensure rules are enabled and running

---

## Troubleshooting map (symptom → where to look)

### Users see 403/blocked access
- Check Front Door WAF logs (WAF blocks)
- Check App Service Access Restrictions (allow Front Door header + deny all)

### Users see 502/503 from Front Door
- Front Door origin health probes failing
- App Service not running / returning errors
- Check App Service logs and Application Insights failures

### Backend can’t access Cosmos/Storage/Key Vault
- Confirm private endpoint + private DNS resolution from jump VM
- Confirm resource public access settings and networking rules
- Check Application Insights dependency failures

### Infrastructure-related issue is suspected
- Infrastructure changes are performed by the Agilis operator.
- If an infrastructure-related issue is suspected (Front Door rules, access restrictions, private endpoints), escalate to the Agilis operator with:
  - timestamp (UTC)
  - affected URL(s)
  - screenshots of Front Door/App Service/App Insights errors (if available)

---

## Incident response (minimal)

1) Identify the failing surface:
   - Front Door vs App Service vs dependency
2) Check relevant logs:
   - WAF logs, App Insights failures, Log Analytics tables
3) Mitigate:
   - Roll back last app deployment, or
   - Temporarily loosen access restriction (time-boxed) only if approved
4) Document:
   - What changed, impact, root cause, and long-term fix


