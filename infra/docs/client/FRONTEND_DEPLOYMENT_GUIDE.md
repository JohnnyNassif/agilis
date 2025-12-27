# Frontend Deployment Guide

This guide explains how to deploy the **frontend application(s)** to Azure **Static Web Apps**.

**Important:**
- Infrastructure (Front Door/WAF, Static Web Apps, certificates, routing) is managed by the **Agilis operator**.
- The client deploys **application code only**.
- Access the platform via **Front Door / custom domain** (not the `*.azurestaticapps.net` default hostname).

---

## What you will deploy

Depending on the environment, you may have:
- **1 frontend** (single portal app), or
- **multiple frontends** (e.g., Portal / Whiteboard / Telehealth) deployed as separate Static Web Apps.

If you are not sure which Static Web Apps are in scope for your deployment, ask the Agilis operator for:
- The Static Web App name(s)
- The expected public hostname (Front Door or custom domain)
- Which app(s) are considered production-relevant

---

## How frontend traffic flows (high level)

```
Internet
  ↓
Azure Front Door (WAF)
  ├─→ /api/* → Backend (App Service)
  └─→ /*     → Frontend (Static Web App)
```

---

## Prerequisites

- Access to the Azure subscription/resource group containing the Static Web App(s)
- Your frontend source repository
- Node.js + npm (version per your frontend project requirements)

---

## Step 1 — Get the Static Web App deployment token (Portal)

Repeat for each Static Web App you deploy.

1. Azure Portal → **Static Web Apps**
2. Select the target Static Web App
3. Go to **Deployment tokens**
4. Copy the token (treat as sensitive)

---

## Step 2 — Configure your API base URL (frontend)

Your frontend should call the backend via **Front Door** using the `/api` prefix.

**Recommended pattern (Angular)**: set the API base URL in your Angular environment files (compile-time):

```typescript
export const environment = {
  production: true,
  apiUrl: "https://<FRONTDOOR_HOST>/api",
};
```

If you need to change the API hostname for an environment, submit a request via `ENVIRONMENT_CONFIGURATION_REQUESTS.md`.

---

## Step 3 — Build the frontend

From your project root:

```bash
npm ci
npm run build
```

Confirm your build output folder exists (commonly `dist/<app-name>`).

---

## Step 4 — Deploy to Static Web Apps

### Option A (recommended): GitHub Actions via Static Web Apps

If your source is in GitHub, use the Static Web App’s built-in deployment integration (Deployment Center).
This provides the most repeatable and auditable deployment path.

Portal steps (high level):
1. Static Web App → **Deployment Center**
2. Connect GitHub repo + branch
3. Confirm build preset/paths
4. Save to create the workflow

### Option B: Static Web Apps CLI (manual)

```bash
npm install -g @azure/static-web-apps-cli

# Replace with your build output directory and deployment token:
swa deploy ./dist/<output-folder> --deployment-token "<TOKEN>"
```

---

## SPA routing (Angular) — required config

If your Angular app uses client-side routes, configure route fallback for Static Web Apps.

Create `staticwebapp.config.json` in your app output root (or repo root and ensure it is copied to the output):

```json
{
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/assets/*", "/*.{css,js,map,png,jpg,jpeg,gif,svg,ico}"]
  }
}
```

---

## Post-deploy verification (required)

Ask the Agilis operator for the correct **Front Door/custom domain** hostname, then verify:

1) Frontend loads:
- `https://<FRONTDOOR_HOST>/`

2) API calls succeed via Front Door:
- `https://<FRONTDOOR_HOST>/api/...`

3) Monitoring:
- Application Insights shows normal failure rates after deployment

---

## Common issues

### “I can access the Static Web App default hostname but not Front Door”
Escalate to the Agilis operator (Front Door routing/custom domain binding issue).

### “Routes return 404 after refresh”
You are missing `staticwebapp.config.json` navigation fallback.

### “Frontend can’t call the API”
- Confirm the API base URL is `https://<FRONTDOOR_HOST>/api`
- Check browser network tab + console
- Escalate if this looks like a platform routing/WAF issue

