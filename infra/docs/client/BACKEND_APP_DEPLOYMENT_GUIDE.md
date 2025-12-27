# Backend App Deployment Guide

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

## Connecting to Key Vault and the database (Node.js/Express)

This section explains how your backend should connect to:
- **Cosmos DB (Mongo API)** for the application database
- **Azure Key Vault** for secrets (optional; most deployments use Key Vault references)

### Important notes (production vs local development)

- In **production**, App Service is configured by the Agilis operator with **Key Vault references**. This means your app reads secrets from **environment variables** (e.g., `process.env.COSMOS_CONNECTION_STRING`) without embedding credentials in code.
- In **local development**, you likely cannot reach Key Vault private endpoints from your laptop. Use a local `.env` file for dev secrets, or develop from an approved network path.

---

### Database: Cosmos DB (Mongo API)

#### Expected environment variable
- `COSMOS_CONNECTION_STRING` (provided via App Service settings / Key Vault reference)

#### Node.js packages

```bash
npm install mongodb
```

#### Example: create a Mongo client and reuse it (recommended)

```js
// db/mongo.js
const { MongoClient } = require("mongodb");

let client;

async function connectMongo() {
  const uri = process.env.COSMOS_CONNECTION_STRING;
  if (!uri) {
    throw new Error("Missing required env var: COSMOS_CONNECTION_STRING");
  }

  // Recommended options for Cosmos DB (Mongo API)
  client = new MongoClient(uri, {
    maxPoolSize: 20,
    minPoolSize: 0,
    serverSelectionTimeoutMS: 10000,
    connectTimeoutMS: 10000,
    retryWrites: false, // Cosmos Mongo API commonly requires retryWrites=false
    tls: true,
  });

  await client.connect();
  return client;
}

function getMongoClient() {
  if (!client) {
    throw new Error("Mongo client not initialized. Call connectMongo() first.");
  }
  return client;
}

async function closeMongo() {
  if (client) {
    await client.close();
    client = undefined;
  }
}

module.exports = { connectMongo, getMongoClient, closeMongo };
```

```js
// server.js (Express bootstrap)
const express = require("express");
const { connectMongo, getMongoClient, closeMongo } = require("./db/mongo");

async function main() {
  await connectMongo();

  const app = express();
  app.use(express.json());

  // Example route to verify DB connectivity
  app.get("/api/health/db", async (req, res) => {
    const client = getMongoClient();
    // Simple ping
    await client.db("admin").command({ ping: 1 });
    res.status(200).json({ ok: true });
  });

  const port = process.env.PORT || 8080;
  const server = app.listen(port, () => {
    console.log(`Server listening on port ${port}`);
  });

  // Graceful shutdown (recommended)
  const shutdown = async (signal) => {
    console.log(`Received ${signal}, shutting down...`);
    server.close(async () => {
      try {
        await closeMongo();
      } finally {
        process.exit(0);
      }
    });
  };

  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));
}

main().catch((err) => {
  console.error("Startup failure:", err);
  process.exit(1);
});
```

---

### Key Vault (optional direct access)

Most deployments use **Key Vault references** set on the App Service, so your code simply reads `process.env.<NAME>`.
However, if your application needs to **read secrets directly from Key Vault** at runtime, use **Managed Identity**.

#### Expected environment variables
- `KEY_VAULT_URL` (example: `https://<vault-name>.vault.azure.net/`)
- `MY_SECRET_NAME` (or any secret name you need)

#### Node.js packages

```bash
npm install @azure/identity @azure/keyvault-secrets
```

#### Example: read a secret using Managed Identity

```js
// keyvault/readSecret.js
const { DefaultAzureCredential } = require("@azure/identity");
const { SecretClient } = require("@azure/keyvault-secrets");

async function readKeyVaultSecret(secretName) {
  const vaultUrl = process.env.KEY_VAULT_URL;
  if (!vaultUrl) {
    throw new Error("Missing required env var: KEY_VAULT_URL");
  }
  if (!secretName) {
    throw new Error("Missing secretName argument");
  }

  const credential = new DefaultAzureCredential();
  const client = new SecretClient(vaultUrl, credential);

  const secret = await client.getSecret(secretName);
  if (!secret.value) {
    throw new Error(`Secret returned without value: ${secretName}`);
  }
  return secret.value;
}

module.exports = { readKeyVaultSecret };
```

```js
// Example route (Express) - do not expose secrets in real endpoints
const express = require("express");
const { readKeyVaultSecret } = require("./keyvault/readSecret");

const app = express();
app.get("/api/health/keyvault", async (req, res) => {
  const secretName = process.env.MY_SECRET_NAME;
  await readKeyVaultSecret(secretName);
  res.status(200).json({ ok: true });
});
```

#### Required Azure permissions

The App Service managed identity must have Key Vault RBAC permissions, typically:
- `Key Vault Secrets User` (read secrets)

If Key Vault access fails in production, escalate to the Agilis operator to confirm:
- the managed identity is enabled on the App Service
- the RBAC assignment exists
- private endpoint/DNS path is in place

---

## Storage access model (IMPORTANT)

This environment is configured so backend services access Azure Storage using **Managed Identity + Azure RBAC** (Azure AD authentication).

### What this means for your application

- Do **not** use Storage Account keys or connection strings (Shared Key authentication).
- Do **not** expect a `STORAGE_ACCOUNT_KEY` value to exist.
- Use the Storage account URL/name (non-secret) and the Azure SDK credential chain (Managed Identity in App Service).

### Required Azure permissions (RBAC)

For the **Main API** App Service managed identity, the Agilis operator assigns:
- **Role:** `Storage Blob Data Contributor`
- **Scope:** Storage account (account-wide read/write/delete access to blobs)

If your app is denied access to Blob Storage (403/Authorization errors), escalate to the Agilis operator to confirm RBAC assignment.

### App settings you can assume exist (non-secret)

The App Service is configured with:
- `STORAGE_ACCOUNT_NAME`: Storage account name (e.g., `stagilisprodh5xc`)
- `STORAGE_ACCOUNT_URL`: Blob service endpoint (e.g., `https://<account>.blob.core.windows.net/`)

Your code should use these values to build blob/container URLs.

### Optional: generating SAS tokens (if required by your frontend)

If you need SAS tokens for direct browser uploads/downloads, use **User Delegation SAS** (Azure AD based), generated by the backend using its managed identity.
This avoids Storage keys and keeps tokens short-lived and scoped.

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

---

## SCM/Kudu (Advanced Tools) and why deployments can be blocked

Each App Service has a separate **SCM/Kudu** management endpoint used for deployments and advanced diagnostics:
- Main app site: `https://<app-name>.azurewebsites.net`
- **SCM/Kudu site**: `https://<app-name>.scm.azurewebsites.net`

Many deployment tools publish through the **SCM/Kudu site**, including:
- **VS Code “Azure App Service” extension Publish/Deploy**
- **ZIP deploy**
- Some CI/CD tasks depending on configuration

If your environment is hardened (recommended), the SCM/Kudu site may be **restricted** so that only approved networks can deploy.

---

### Option B: Deploy via VS Code (Azure App Service extension)

Use this option only if your organization allows developer workstation deployments. For HIPAA-aligned environments, CI/CD is usually preferred because it is more auditable and less dependent on changing home/ISP IP addresses.

#### B.1 Prerequisites
- Install **Visual Studio Code**
- Install the VS Code extension **“Azure App Service”** (Microsoft)
- You must have Azure permissions to deploy to the target App Service

#### B.2 If deployment fails: allowlist your IP on the SCM/Kudu site

**When you need this:** If you click Deploy/Publish in VS Code and see errors like **403 Forbidden**, **IP Forbidden**, or **SCM site restrictions**.

##### Step 1 — Determine your public IP
Use one of the following:
- In a browser, search “what is my IP” and copy the IPv4 address
- Or from a terminal:

```bash
curl ifconfig.me
```

##### Step 2 — Add an allow rule to the *SCM site* access restrictions (Azure Portal)
Repeat for each backend App Service you deploy to.

1. Azure Portal → **App Services** → select your backend App Service
2. Go to **Networking** → **Access restrictions**
3. Switch to the **SCM site** tab
4. If you see a toggle like **“Same restrictions as main site”**, ensure it is **OFF** (so SCM can have its own allowlist)
5. Click **+ Add rule**
6. Add an allow rule:
   - **Name:** `AllowClientDeployIP`
   - **Action:** Allow
   - **Priority:** `200` (any number lower than your DenyAll rule)
   - **Type:** IP Address
   - **IP address/CIDR:** `<YOUR_PUBLIC_IP>/32`
7. Ensure there is a deny-all rule present for SCM (common pattern):
   - **Name:** `DenyAll-SCM`
   - **Action:** Deny
   - **Priority:** `2147483647`
   - **IP address:** `0.0.0.0/0`

**Note:** If your ISP IP changes frequently, you should deploy from a stable network (VPN/corporate egress) or use CI/CD.

##### Step 3 — (Alternative) Add SCM allow rule using Azure CLI

```bash
RG="<RESOURCE_GROUP>"
APP="<APP_SERVICE_NAME>"
MY_IP="<YOUR_PUBLIC_IP>"

az webapp config access-restriction add \
  --resource-group "$RG" \
  --name "$APP" \
  --rule-name "AllowClientDeployIP" \
  --action Allow \
  --priority 200 \
  --ip-address "$MY_IP/32" \
  --scm-site true
```

#### B.3 Deploy from VS Code

1. Open VS Code
2. Sign in to Azure in VS Code:
   - View → **Command Palette** → run: **“Azure: Sign In”**
3. Open the backend project folder
4. Ensure your project builds and starts correctly (see “Application requirements” above)
5. In the VS Code sidebar, open **Azure** → **App Service**
6. Find the target App Service (provided by the Agilis operator)
7. Deploy:
   - Right-click the App Service → **Deploy to Web App…**
   - Select your workspace/folder to deploy when prompted
8. Wait for deployment to complete

**If it still fails:** confirm you added the allow rule under the **SCM site** tab, not just the main site tab.

### Option C: ZIP deploy using Azure CLI (manual)
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

### Option D: Portal upload (quick tests only)
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

### “Blob storage access fails (403 / AuthorizationPermissionMismatch)”
This environment uses **Managed Identity + RBAC** for Storage access (no account keys).

- Confirm your code is using Managed Identity credentials (Azure SDK default credential chain).
- Confirm you are using `STORAGE_ACCOUNT_URL`/`STORAGE_ACCOUNT_NAME` (non-secret config).
- Escalate to the Agilis operator to confirm the App Service managed identity has **Storage Blob Data Contributor** on the Storage account scope.

### “Deployment fails due to SCM site restrictions”
If SCM/advanced tools access restrictions are enabled, deployment may be blocked from your network.
- Escalate to Agilis operator to coordinate an approved deployment path (GitHub Actions, temporary allow-listing, etc.).


