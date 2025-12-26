# Multi-App Architecture Documentation

**Date:** December 18, 2025  
**Purpose:** Support 3 frontends + 3 backends (Main Portal + Whiteboard + Telehealth)

---

## 🎯 Architecture Overview

Your Agilis Dental platform consists of **three separate applications**:

```
┌────────────────────────────────────────────────────────────────┐
│                   MAIN PORTAL APPLICATION                       │
│  Frontend: Angular SPA (main UI)                               │
│  Backend: Node.js API (patient management, appointments, etc.)  │
│  Hosting: Static Web App + App Service                         │
│  Access: Via Front Door (WAF protected)                        │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                 WHITEBOARD APPLICATION                          │
│  Frontend: Canvas/Drawing interface                             │
│  Backend: Node.js API (canvas data, drawings API)              │
│  Hosting: Static Web App + App Service                         │
│  Access: Direct URLs (embedded via iframe)                      │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                 TELEHEALTH APPLICATION                          │
│  Frontend: Video conferencing interface                         │
│  Backend: Node.js API (video/call management)                  │
│  Hosting: Static Web App + App Service                         │
│  Access: Direct URLs (embedded via iframe)                      │
└────────────────────────────────────────────────────────────────┘
```

---

## 📊 Resource Mapping

### Created Resources

| Component | Resource Name | SKU/Tier | Purpose |
|-----------|--------------|----------|---------|
| **Main Frontend** | `swa-agilis-{env}` | Free (dev) / Standard (prod) | Main portal UI |
| **Main Backend** | `app-agilis-{env}-api` | B1 (dev) / P1v3 (prod) | Main API |
| **Whiteboard Frontend** | `swa-agilis-{env}-whiteboard` | Free (all envs) | Whiteboard UI |
| **Whiteboard Backend** | `app-agilis-{env}-api-whiteboard` | B1 (all envs) | Whiteboard API |
| **Telehealth Frontend** | `swa-agilis-{env}-telehealth` | Free (all envs) | Telehealth UI |
| **Telehealth Backend** | `app-agilis-{env}-api-telehealth` | B1 (all envs) | Telehealth API |

### Shared Infrastructure

All 6 applications share:
- ✅ **Cosmos DB** - Single database with tenant isolation
- ✅ **Storage Account** - Single account for all PHI files
- ✅ **Key Vault** - Single vault for all secrets
- ✅ **Virtual Network** - All backends VNet-integrated
- ✅ **Log Analytics** - Centralized logging
- ✅ **Application Insights** - Shared telemetry
- ✅ **Front Door** - Only main app (WAF protection)

---

## 🌐 URLs and Access Patterns

### Development Environment

```
Main Portal (via Front Door - WAF protected):
├─ Frontend: https://fd-agilis-dev-<hash>.azurefd.net/
└─ Backend:  https://fd-agilis-dev-<hash>.azurefd.net/api/*

Whiteboard (direct access - embedded via iframe):
├─ Frontend: https://swa-agilis-dev-whiteboard.azurestaticapps.net/
└─ Backend:  https://app-agilis-dev-api-whiteboard.azurewebsites.net/

Telehealth (direct access - embedded via iframe):
├─ Frontend: https://swa-agilis-dev-telehealth.azurestaticapps.net/
└─ Backend:  https://app-agilis-dev-api-telehealth.azurewebsites.net/
```

### Production Environment

```
Main Portal (via Front Door - WAF protected):
├─ Frontend: https://fd-agilis-prod-<hash>.azurefd.net/
│            (or custom domain: https://portal.agilis.com)
└─ Backend:  https://fd-agilis-prod-<hash>.azurefd.net/api/*

Whiteboard (direct access - embedded via iframe):
├─ Frontend: https://swa-agilis-prod-whiteboard.azurestaticapps.net/
└─ Backend:  https://app-agilis-prod-api-whiteboard.azurewebsites.net/

Telehealth (direct access - embedded via iframe):
├─ Frontend: https://swa-agilis-prod-telehealth.azurestaticapps.net/
└─ Backend:  https://app-agilis-prod-api-telehealth.azurewebsites.net/
```

---

## 💻 Frontend Integration (iFrame Embedding)

### Main Portal HTML

```html
<!-- Main Portal: src/app/whiteboard/whiteboard.component.html -->
<div class="whiteboard-container">
  <iframe 
    [src]="whiteboardUrl"
    sandbox="allow-scripts allow-same-origin allow-forms"
    allow="clipboard-write"
    title="Interactive Whiteboard"
    class="whiteboard-iframe">
  </iframe>
</div>

<!-- Main Portal: src/app/telehealth/telehealth.component.html -->
<div class="telehealth-container">
  <iframe 
    [src]="telehealthUrl"
    sandbox="allow-scripts allow-same-origin allow-forms"
    allow="camera; microphone; display-capture"
    title="Telehealth Video Call"
    class="telehealth-iframe">
  </iframe>
</div>
```

### Angular Component

```typescript
// main-portal/src/app/whiteboard/whiteboard.component.ts
import { Component, OnInit } from '@angular/core';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { environment } from '../../environments/environment';

@Component({
  selector: 'app-whiteboard',
  templateUrl: './whiteboard.component.html',
  styleUrls: ['./whiteboard.component.css']
})
export class WhiteboardComponent implements OnInit {
  whiteboardUrl: SafeResourceUrl;

  constructor(private sanitizer: DomSanitizer) {}

  ngOnInit() {
    // Get whiteboard URL from environment config
    const url = environment.whiteboardUrl;
    
    // Pass tenant context via URL parameters
    const tenantId = this.getTenantId();
    const patientId = this.getCurrentPatientId();
    
    const fullUrl = `${url}?tenantId=${tenantId}&patientId=${patientId}`;
    this.whiteboardUrl = this.sanitizer.bypassSecurityTrustResourceUrl(fullUrl);
  }

  private getTenantId(): string {
    // Get from your tenant service
    return localStorage.getItem('tenantId') || '';
  }

  private getCurrentPatientId(): string {
    // Get from route or state
    return this.route.snapshot.params['patientId'] || '';
  }
}
```

### Environment Configuration

```typescript
// main-portal/src/environments/environment.ts
export const environment = {
  production: false,
  apiUrl: 'https://fd-agilis-dev.azurefd.net/api',
  whiteboardUrl: 'https://swa-agilis-dev-whiteboard.azurestaticapps.net',
  telehealthUrl: 'https://swa-agilis-dev-telehealth.azurestaticapps.net'
};

// main-portal/src/environments/environment.prod.ts
export const environment = {
  production: true,
  apiUrl: 'https://portal.agilis.com/api',
  whiteboardUrl: 'https://swa-agilis-prod-whiteboard.azurestaticapps.net',
  telehealthUrl: 'https://swa-agilis-prod-telehealth.azurestaticapps.net'
};
```

---

## 🔐 Security Considerations

### CORS Configuration

Each backend needs CORS configured to allow iframe embedding:

```javascript
// whiteboard-backend/server.js
const cors = require('cors');

app.use(cors({
  origin: [
    'https://fd-agilis-dev.azurefd.net',
    'https://fd-agilis-prod.azurefd.net',
    'https://portal.agilis.com'  // Production custom domain
  ],
  credentials: true
}));
```

### Content Security Policy (CSP)

Main Portal should allow iframes from whiteboard/telehealth:

```typescript
// main-portal: Set CSP headers
const csp = {
  'frame-src': [
    'https://swa-agilis-dev-whiteboard.azurestaticapps.net',
    'https://swa-agilis-dev-telehealth.azurestaticapps.net',
    'https://swa-agilis-prod-whiteboard.azurestaticapps.net',
    'https://swa-agilis-prod-telehealth.azurestaticapps.net'
  ]
};
```

### Authentication Token Sharing

```typescript
// Main Portal: Pass auth token to iframe apps
const whiteboardUrl = `${environment.whiteboardUrl}?token=${authToken}&tenantId=${tenantId}`;

// Whiteboard App: Receive and validate token
const urlParams = new URLSearchParams(window.location.search);
const token = urlParams.get('token');
const tenantId = urlParams.get('tenantId');

// Validate token with backend
validateToken(token, tenantId);
```

---

## 💰 Cost Breakdown

### Development Environment

| Resource | SKU | Monthly Cost | Notes |
|----------|-----|--------------|-------|
| Main Frontend | Free | $0 | Static Web App Free tier |
| Main Backend | B1 | ~$13 | Basic tier |
| Whiteboard Frontend | Free | $0 | Static Web App Free tier |
| Whiteboard Backend | B1 | ~$13 | Shared with main (same plan)* |
| Telehealth Frontend | Free | $0 | Static Web App Free tier |
| Telehealth Backend | B1 | ~$13 | Shared with main (same plan)* |
| **Total Apps** | | **~$13-39** | Depends on App Service Plan sharing |

*Note: Multiple App Services can share the same App Service Plan, reducing costs.

### Production Environment

| Resource | SKU | Monthly Cost | Notes |
|----------|-----|--------------|-------|
| Main Frontend | Standard | ~$25 | Static Web App Standard tier |
| Main Backend | P1v3 | ~$110 | Premium tier (production SLA) |
| Whiteboard Frontend | Free | $0 | Low load - Free sufficient |
| Whiteboard Backend | B1 | ~$13 | Minimal tier for low load |
| Telehealth Frontend | Free | $0 | Low load - Free sufficient |
| Telehealth Backend | B1 | ~$13 | Minimal tier for low load |
| **Total Apps** | | **~$161** | Optimized for production |

**Total Infrastructure Cost (Production):**
- Apps: ~$161/month
- Front Door Premium: ~$35/month
- Cosmos DB: ~$50-200/month (depends on RU/s)
- Storage + Key Vault + Monitoring: ~$50/month
- **Grand Total: ~$300-450/month**

---

## 📋 Deployment Guide

### After `terraform apply`

You'll receive these outputs:

```bash
terraform output

# Main Portal
static_web_app_default_hostname = "swa-agilis-prod.azurestaticapps.net"
static_web_app_api_key = "<sensitive>"
app_service_name = "app-agilis-prod-api"

# Whiteboard
static_web_app_whiteboard_default_hostname = "swa-agilis-prod-whiteboard.azurestaticapps.net"
static_web_app_whiteboard_api_key = "<sensitive>"
app_service_whiteboard_name = "app-agilis-prod-api-whiteboard"

# Telehealth
static_web_app_telehealth_default_hostname = "swa-agilis-prod-telehealth.azurestaticapps.net"
static_web_app_telehealth_api_key = "<sensitive>"
app_service_telehealth_name = "app-agilis-prod-api-telehealth"

# Front Door
frontdoor_endpoint_hostname = "fd-agilis-prod-<hash>.azurefd.net"
```

### Deploy Frontend Apps

```bash
# Main Portal
cd main-portal
npm run build:prod
az staticwebapp deploy \
  --name swa-agilis-prod \
  --api-key $(terraform output -raw static_web_app_api_key)

# Whiteboard
cd whiteboard-frontend
npm run build:prod
az staticwebapp deploy \
  --name swa-agilis-prod-whiteboard \
  --api-key $(terraform output -raw static_web_app_whiteboard_api_key)

# Telehealth
cd telehealth-frontend
npm run build:prod
az staticwebapp deploy \
  --name swa-agilis-prod-telehealth \
  --api-key $(terraform output -raw static_web_app_telehealth_api_key)
```

### Deploy Backend APIs

```bash
# Main Backend
cd main-backend
az webapp up \
  --name app-agilis-prod-api \
  --resource-group rg-agilis-prod-core

# Whiteboard Backend
cd whiteboard-backend
az webapp up \
  --name app-agilis-prod-api-whiteboard \
  --resource-group rg-agilis-prod-core

# Telehealth Backend
cd telehealth-backend
az webapp up \
  --name app-agilis-prod-api-telehealth \
  --resource-group rg-agilis-prod-core
```

---

## 🧪 Testing Guide

### Test Main Portal

```bash
# Test main portal loads
curl https://fd-agilis-prod-<hash>.azurefd.net/

# Test main API
curl https://fd-agilis-prod-<hash>.azurefd.net/api/health
```

### Test Whiteboard (Direct Access)

```bash
# Test whiteboard frontend loads
curl https://swa-agilis-prod-whiteboard.azurestaticapps.net/

# Test whiteboard API
curl https://app-agilis-prod-api-whiteboard.azurewebsites.net/api/health
```

### Test Telehealth (Direct Access)

```bash
# Test telehealth frontend loads
curl https://swa-agilis-prod-telehealth.azurestaticapps.net/

# Test telehealth API
curl https://app-agilis-prod-api-telehealth.azurewebsites.net/api/health
```

### Test iFrame Embedding

1. Open main portal in browser
2. Navigate to whiteboard section
3. Verify iframe loads whiteboard app
4. Check browser console for CORS errors
5. Test data flows between main app and iframe

---

## 🎯 Key Design Decisions

### Why Separate Static Web Apps?

**Decision:** Create separate Static Web Apps for each frontend

**Reasoning:**
- ✅ Independent deployments (no need to redeploy main app for whiteboard changes)
- ✅ Separate deployment keys (better security)
- ✅ Independent scaling
- ✅ Clear separation of concerns

### Why Separate App Services?

**Decision:** Create separate App Services for each backend

**Reasoning:**
- ✅ Independent scaling (whiteboard/telehealth need less resources)
- ✅ Cost optimization (B1 tier sufficient for low-load apps)
- ✅ Fault isolation (whiteboard crash doesn't affect main app)
- ✅ Independent deployment cycles

### Why iFrame Instead of Micro-Frontend Framework?

**Decision:** Use iframes for embedding whiteboard/telehealth

**Reasoning:**
- ✅ Complete isolation (CSS/JS doesn't conflict)
- ✅ Security boundary (sandboxing)
- ✅ Technology independence (can use different frameworks)
- ✅ Simpler implementation (no complex module federation)

### Why Only Main App Behind Front Door?

**Decision:** Only route main portal through Front Door, direct URLs for iframe apps

**Reasoning:**
- ✅ Cost savings (only one app needs WAF Premium)
- ✅ Main app handles PHI (needs maximum protection)
- ✅ Whiteboard/telehealth are utility tools (lower risk)
- ✅ Simpler routing (no path rewriting needed)

---

## 🚀 Future Enhancements

### Option 1: Add All Apps Behind Front Door

If you want all apps behind WAF:

```terraform
# Add routes to Front Door module
/whiteboard/* → Whiteboard Frontend
/whiteboard/api/* → Whiteboard Backend
/telehealth/* → Telehealth Frontend
/telehealth/api/* → Telehealth Backend
```

**Benefits:**
- All apps behind WAF
- Single domain (no CORS issues)
- Consistent white-label experience

**Costs:**
- More complex routing
- Path rewriting needed

### Option 2: Separate Front Door Instances

Create separate Front Doors for each app:

**Benefits:**
- Complete isolation
- Independent WAF policies

**Costs:**
- 3x Front Door costs (~$105/month)
- More complex management

---

## 📚 Additional Resources

- **Frontend Deployment:** See `FRONTEND_DEPLOYMENT_GUIDE.md`
- **Storage Lifecycle:** See `STORAGE_LIFECYCLE_POLICY.md`
- **White-Label Setup:** See main review documentation

---

**Last Updated:** December 18, 2025  
**Maintained By:** Infrastructure Team


