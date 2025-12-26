# Backend App Deployment Guide (Client)

This guide explains how the client deploys **backend application code** to the existing Azure **App Service** resources.

**Important:** Infrastructure (Terraform) is operated by the Agilis operator. This guide is for **application deployments only**.

---

## What you will deploy

- The backend API application to Azure App Service (Linux).
- If your environment includes multiple backend apps (e.g., Main API / Telehealth / Whiteboard), repeat the same deployment process per App Service.

---

## What is already handled by infrastructure

Terraform provisions and configures:
- App Service(s) and Service Plan(s)
- Network integration, private endpoints, Key Vault, Cosmos DB, Storage
- App settings and Key Vault references (where applicable)
- Front Door/WAF routing for the public entrypoint

You should **not** change infrastructure settings unless coordinated with the Agilis operator.

---

## Prerequisites

- Access to the Azure subscription/resource group containing the App Service(s)
- Access to your source code repository (backend)
- A Node.js API that can run on Linux App Service

**Runtime:** This infrastructure provisions App Service with **Node.js `18-lts`**.

---

## Application requirements (Node.js)

### TypeScript build → `dist/`
Your backend is TypeScript and should compile to a `dist/` folder.

### Required `package.json` scripts (TypeScript)
Your backend should have:
- `npm ci` / `npm install` working without interactive prompts
- `build` that produces `dist/`
- `start` that runs the compiled output from `dist/`

Example:

```json
{
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "start": "node dist/server.js"
  }
}
```

**Notes:**
- The exact entry file may be `dist/index.js`, `dist/main.js`, or `dist/server.js` depending on your project.
- The `build` script can also use your bundler (e.g., `tsup`, `esbuild`) as long as it produces runnable JS in `dist/`.

### Port binding
App Service provides the port via `process.env.PORT`. Your server must listen on that port.

---

## Configuration policy (secrets and env vars)

- Do **not** commit secrets to source control.
- App configuration (connection strings, Key Vault references, etc.) is managed on the App Service by the Agilis operator.
- If you need new environment variables, request them from the Agilis operator.

---

## Step 1 — Identify the correct App Service(s)

In Azure Portal:
1. Go to **App Services**
2. Locate the backend App Service(s) provided by the Agilis operator (names vary per environment)

If you are not sure which one is “Main API”, ask the Agilis operator for:
- App Service name(s)
- Front Door endpoint hostname for the environment
- Expected API base path (typically `/api`)

---

## Step 2 — Choose a deployment method

### Option A (recommended): GitHub Actions via Deployment Center
This is the most repeatable method for clients.

1. App Service → **Deployment Center**
2. Select your source control (GitHub) and authenticate
3. Choose repository + branch
4. Configure build settings (runtime/version) as needed
5. Save to create the workflow

**Notes:**
- The App Service runtime is Node.js **18 LTS**. If you use GitHub Actions, ensure the workflow builds with Node **18**.
- If SCM/advanced tools site access restrictions are enabled, deployment may require an approved path (GitHub Actions, temporary allow-listing, etc.).
- Keep secrets out of GitHub; rely on App Service settings/Key Vault references already configured.

Recommended build steps for TypeScript:
- `npm ci`
- `npm run build`

### Option B: ZIP deploy using Azure CLI (manual)
1. Build your backend locally (produce a deployable artifact)
2. Create a zip that includes at least:
   - `package.json`
   - `package-lock.json` (recommended)
   - `dist/` (compiled output)
   - any runtime assets your app needs (e.g., `public/`, templates, migrations) if applicable
3. Deploy the zip:

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"

RG="<RESOURCE_GROUP>"
APP="<APP_SERVICE_NAME>"
ZIP_PATH="./backend.zip"

az webapp deployment source config-zip \
  --resource-group "$RG" \
  --name "$APP" \
  --src "$ZIP_PATH"
```

After deployment, App Service will install dependencies and start your app using your configured startup (`npm start` by default for Node). Ensure your `start` script runs the compiled output from `dist/`.

### Option C: Portal upload (quick tests only)
Use only for emergency/temporary validation. Prefer GitHub Actions for real deployments.

---

## Step 3 — Post-deploy verification

### Verify the API is reachable through Front Door
The backend should be accessed through the Front Door URL (not `*.azurewebsites.net`).

Ask the Agilis operator for the environment Front Door hostname, then verify:

```bash
curl -I https://<FRONTDOOR_HOST>/api/
```

If you have a health endpoint (recommended), verify:

```bash
curl -i https://<FRONTDOOR_HOST>/api/health
```

### Verify logs and errors
In Azure Portal:
- App Service → **Log stream** (short-term)
- Application Insights → **Failures** / **Logs** (preferred)

---

## Common issues

### “It deployed but returns 502/503 through Front Door”
- Check App Service is **Running**
- Check App Service logs / Application Insights failures
- Check Front Door origin health
- Escalate to Agilis operator if origin health is failing or routing rules need adjustment

### “I cannot reach the API via azurewebsites.net”
This is expected if access restrictions are enabled. Use Front Door hostname.

### “Deployment fails due to SCM site restrictions”
If SCM/advanced tools access restrictions are enabled, deployment may be blocked from your network.
- Escalate to Agilis operator to coordinate an approved deployment path (GitHub Actions, temporary allow-listing, etc.).


