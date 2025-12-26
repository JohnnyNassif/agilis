# Frontend Deployment Guide

## Overview

This guide explains how to deploy your Angular frontend application (main app with embedded whiteboard and telehealth components) to Azure Static Web Apps.

**Important**: Since whiteboard and telehealth are embedded into the main Angular app, you only need to deploy **ONE application** - the main Angular app.

---

## Architecture

```
Internet
  ↓
Front Door (WAF) - https://fd-agilis-dev.azurefd.net
  ├─→ /api/* → App Service (Backend APIs)
  └─→ /* → Static Web App (Frontend - Your Angular App)
```

**Access Points**:
- **Frontend**: Access via Front Door URL (e.g., `https://fd-agilis-dev.azurefd.net`)
- **Backend APIs**: Access via Front Door URL with `/api` prefix (e.g., `https://fd-agilis-dev.azurefd.net/api/...`)

---

## Prerequisites

1. **Azure Static Web App** must be deployed via Terraform
2. **Angular CLI** installed (`npm install -g @angular/cli`)
3. **Azure Static Web Apps CLI** (optional, for easier deployment)
4. **Azure CLI** (optional, alternative deployment method)
5. **Node.js** and **npm** installed

---

## Step 1: Get Deployment Credentials

After Terraform deployment, retrieve the Static Web App deployment credentials:

### Option A: Using Terraform Output (Recommended)

```bash
cd infra/environments/dev

# Get Static Web App name
terraform output static_web_app_name

# Get Static Web App hostname
terraform output static_web_app_default_hostname

# Get deployment API key (sensitive - keep secure!)
terraform output static_web_app_api_key

# Get Front Door endpoint URL (for API calls)
terraform output frontdoor_endpoint_hostname
```

### Option B: Using Azure Portal

1. Go to Azure Portal → Static Web Apps
2. Find your Static Web App: `swa-agilis-dev`
3. Go to **Settings** → **Deployment tokens**
4. Copy the **Deployment token**

---

## Step 2: Configure Environment Variables

Before building, ensure your Angular app is configured to use the correct API endpoint.

### Update Angular Environment Files

**`src/environments/environment.prod.ts`**:

```typescript
export const environment = {
  production: true,
  apiUrl: 'https://fd-agilis-dev.azurefd.net/api', // Front Door endpoint + /api
  // Add other production environment variables
};
```

**`src/environments/environment.ts`** (for development):

```typescript
export const environment = {
  production: false,
  apiUrl: 'http://localhost:3000/api', // Local backend during development
  // Add other development environment variables
};
```

### Alternative: Use Static Web App App Settings

You can also configure environment variables via Terraform (they'll be available as environment variables in your Angular app):

**In `infra/environments/dev/dev.auto.tfvars`**:

```hcl
static_web_app_app_settings = {
  "API_URL" = "https://fd-agilis-dev.azurefd.net/api"
  # Add other environment variables as needed
}
```

Then access them in your Angular app:

```typescript
// In your Angular service
const apiUrl = process.env['API_URL'] || 'https://fd-agilis-dev.azurefd.net/api';
```

---

## Step 3: Build Your Angular Application

Build your Angular app for production:

```bash
# Navigate to your Angular project root
cd /path/to/your/angular-project

# Install dependencies (if not already installed)
npm install

# Build for production
ng build --configuration production

# Or using npm script
npm run build -- --configuration production
```

**Output**: The build creates a `dist/` folder (or `dist/<your-app-name>/`) containing the compiled static files.

**Verify**: Check that `dist/` folder contains:
- `index.html`
- `main.js` (or similar bundled files)
- `styles.css` (or similar CSS files)
- `assets/` folder (if you have assets)

---

## Step 4: Deploy to Azure Static Web Apps

Choose one of the following deployment methods:

### Method A: Azure Static Web Apps CLI (Recommended)

#### Install Azure Static Web Apps CLI

```bash
npm install -g @azure/static-web-apps-cli
```

#### Deploy

```bash
# Replace <api-key> with the deployment token from Step 1
# Replace <dist-folder> with your actual dist folder path (e.g., dist/your-app-name)

swa deploy ./dist/<dist-folder> \
  --deployment-token <api-key> \
  --env production \
  --app-name swa-agilis-dev
```

**Example**:

```bash
swa deploy ./dist/agilis-app \
  --deployment-token abc123xyz789... \
  --env production \
  --app-name swa-agilis-dev
```

#### Verify Deployment

```bash
# Check deployment status
swa deploy --list \
  --deployment-token <api-key> \
  --app-name swa-agilis-dev
```

---

### Method B: Azure CLI

#### Install Azure CLI

Download from: https://aka.ms/installazurecliwindows

#### Login to Azure

```bash
az login
```

#### Deploy

```bash
# Set variables
SWA_NAME="swa-agilis-dev"
RG="rg-agilis-dev-core"
DEPLOYMENT_TOKEN="<api-key-from-step-1>"
DIST_FOLDER="./dist/<your-app-name>"

# Deploy
az staticwebapp deploy \
  --name $SWA_NAME \
  --resource-group $RG \
  --source-location $DIST_FOLDER \
  --token $DEPLOYMENT_TOKEN
```

---

### Method C: GitHub Actions (Automatic Deployment)

If your code is in GitHub, you can set up automatic deployments:

#### 1. Add Deployment Token as GitHub Secret

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `AZURE_STATIC_WEB_APPS_API_TOKEN`
5. Value: Paste the deployment token from Step 1
6. Click **Add secret**

#### 2. Create GitHub Actions Workflow

Create `.github/workflows/azure-static-web-apps.yml`:

```yaml
name: Azure Static Web Apps CI/CD

on:
  push:
    branches:
      - main
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches:
      - main

jobs:
  build_and_deploy_job:
    if: github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.action != 'closed')
    runs-on: ubuntu-latest
    name: Build and Deploy Job
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: true
          lfs: false
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm install
      
      - name: Build Angular app
        run: npm run build -- --configuration production
      
      - name: Build And Deploy
        id: builddeploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "/"
          output_location: "dist/<your-app-name>"

  close_pull_request_job:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    name: Close Pull Request Job
    steps:
      - name: Close Pull Request
        id: closepullrequest
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          action: "close"
```

**Note**: Replace `<your-app-name>` with your actual Angular app name.

#### 3. Push to GitHub

```bash
git add .github/workflows/azure-static-web-apps.yml
git commit -m "Add Azure Static Web Apps deployment workflow"
git push
```

Deployments will now happen automatically on every push to `main` branch.

---

## Step 5: Verify Deployment

### Check Deployment Status

1. **Azure Portal**:
   - Go to Azure Portal → Static Web Apps → `swa-agilis-dev`
   - Check **Deployment history** to see deployment status

2. **Front Door URL**:
   - Open browser: `https://fd-agilis-dev.azurefd.net`
   - Verify your Angular app loads correctly

### Test Frontend Functionality

1. **Main App**: Navigate to `https://fd-agilis-dev.azurefd.net`
2. **Whiteboard**: Navigate to `https://fd-agilis-dev.azurefd.net/whiteboard` (or your whiteboard route)
3. **Telehealth**: Navigate to `https://fd-agilis-dev.azurefd.net/telehealth` (or your telehealth route)
4. **API Calls**: Verify API calls work (check browser DevTools Network tab)

### Check Browser Console

Open browser DevTools (F12) and check:
- No JavaScript errors
- API calls are going to correct endpoint (`/api/...`)
- CORS errors (if any) - should be handled by Front Door

---

## Step 6: Update API Configuration (If Needed)

If your Angular app needs to call backend APIs, ensure the API URL is correctly configured:

### Option A: Environment Variables (Recommended)

Update `src/environments/environment.prod.ts`:

```typescript
export const environment = {
  production: true,
  apiUrl: 'https://fd-agilis-dev.azurefd.net/api', // Front Door + /api
};
```

### Option B: Static Web App App Settings

App settings may be managed by the Agilis operator via infrastructure-as-code. If you need to change frontend configuration (e.g., API base URL), request the change from the Agilis operator.

If you are explicitly instructed to manage Static Web App app settings via Terraform in your environment, update `infra/environments/dev/dev.auto.tfvars`:

```hcl
static_web_app_app_settings = {
  "API_URL" = "https://fd-agilis-dev.azurefd.net/api"
}
```

Then the Agilis operator will apply the infrastructure change.

---

## Troubleshooting

### Issue: Deployment Fails with "Invalid Token"

**Solution**:
- Verify the deployment token is correct (copy from Terraform output or Azure Portal)
- Ensure token hasn't expired (tokens don't expire, but check if Static Web App was recreated)

### Issue: 404 Errors on Routes

**Solution**:
- Static Web Apps needs a `routes.json` file for Angular routing
- Create `public/routes.json` in your Angular project:

```json
{
  "routes": [
    {
      "route": "/*",
      "serve": "/index.html",
      "statusCode": 200
    }
  ]
}
```

Or add to `angular.json`:

```json
{
  "projects": {
    "your-app": {
      "architect": {
        "build": {
          "options": {
            "assets": [
              {
                "glob": "routes.json",
                "input": "public",
                "output": "/"
              }
            ]
          }
        }
      }
    }
  }
}
```

### Issue: API Calls Fail (CORS Errors)

**Solution**:
- Front Door should handle CORS, but verify:
  - API calls use `/api` prefix (routed to backend)
  - Backend CORS is configured to allow Front Door origin
  - Check browser console for specific CORS error messages

### Issue: Environment Variables Not Available

**Solution**:
- Static Web App app settings are available as environment variables
- Access via `process.env['VARIABLE_NAME']` in Angular
- Or use Angular's `environment.ts` files (recommended)

### Issue: Build Fails

**Solution**:
- Check Node.js version (Angular requires Node.js 18+)
- Clear `node_modules` and reinstall: `rm -rf node_modules && npm install`
- Check Angular version compatibility
- Review build errors in terminal output

---

## Deployment Checklist

Before deploying:

- [ ] Terraform deployment completed successfully
- [ ] Static Web App created (`swa-agilis-dev`)
- [ ] Deployment token retrieved
- [ ] Front Door endpoint URL noted
- [ ] Angular app builds successfully (`ng build --prod`)
- [ ] `dist/` folder contains all necessary files
- [ ] Environment variables configured (API URL, etc.)
- [ ] `routes.json` file created (if using Angular routing)

After deploying:

- [ ] Deployment completed without errors
- [ ] Frontend accessible via Front Door URL
- [ ] All routes work (main app, whiteboard, telehealth)
- [ ] API calls work correctly
- [ ] No console errors in browser
- [ ] Check Azure Portal deployment history

---

## Quick Reference

### Get Deployment Info

```bash
cd infra/environments/dev

# Static Web App name
terraform output static_web_app_name

# Static Web App hostname
terraform output static_web_app_default_hostname

# Deployment token
terraform output static_web_app_api_key

# Front Door URL
terraform output frontdoor_endpoint_hostname
```

### Deploy Command (Quick)

```bash
swa deploy ./dist/<your-app-name> \
  --deployment-token $(terraform output -raw static_web_app_api_key) \
  --env production \
  --app-name $(terraform output -raw static_web_app_name)
```

### Access URLs

- **Frontend**: `https://fd-agilis-dev.azurefd.net` ✅ **USE THIS** (protected by Front Door WAF)
- **Backend API**: `https://fd-agilis-dev.azurefd.net/api/...` ✅ **USE THIS** (protected by Front Door WAF)
- **Static Web App Direct**: `https://swa-agilis-dev.azurestaticapps.net` ⚠️ **NOT RECOMMENDED** (bypasses Front Door, no WAF protection)
- **App Service Direct**: `https://app-agilis-dev-api-dev1.azurewebsites.net` ⚠️ **BLOCKED** (if IP restrictions enabled) or ⚠️ **NOT RECOMMENDED** (bypasses Front Door)

**Important**: Always use the Front Door URL (`https://fd-agilis-dev.azurefd.net`) to access your application. Direct URLs bypass security protections.

---

## Additional Resources

- [Azure Static Web Apps Documentation](https://docs.microsoft.com/azure/static-web-apps/)
- [Azure Static Web Apps CLI](https://github.com/Azure/static-web-apps-cli)
- [Angular Deployment Guide](https://angular.io/guide/deployment)
- [Front Door Documentation](https://docs.microsoft.com/azure/frontdoor/)

---

## Support

If you encounter issues:

1. Check Azure Portal → Static Web Apps → Deployment history
2. Review browser console for errors
3. Verify Terraform outputs are correct
4. Check Front Door routing configuration
5. Review this guide's troubleshooting section

For infrastructure issues, contact your infrastructure team.
For application issues, check your Angular application logs and configuration.

