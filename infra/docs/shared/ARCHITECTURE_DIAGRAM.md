# Architecture Diagram - Multi-App Setup

**Visual representation of the 6-app architecture**

---

## 🌐 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         INTERNET (Public Traffic)                        │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                │ HTTPS (WAF Protected)
                                │
                ┌───────────────▼──────────────┐
                │   Azure Front Door (Premium)  │
                │   ✓ WAF (OWASP Top 10)       │
                │   ✓ DDoS Protection          │
                │   ✓ Custom Domains Support   │
                └───────────────┬──────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
           ┌────────▼────────┐    ┌────────▼────────┐
           │  Main Frontend  │    │   Main Backend  │
           │  (Static Web    │    │  (App Service)  │
           │   App)          │    │                 │
           │  Standard Tier  │    │  P1v3 (Prod)    │
           └────────┬────────┘    └────────┬────────┘
                    │                      │
                    │  iFrame Embeds       │  Shared Resources
                    │                      │
        ┌───────────┴───────────┐          │
        │                       │          │
┌───────▼────────┐    ┌────────▼────────┐ │
│   Whiteboard   │    │   Telehealth    │ │
│   Frontend     │    │   Frontend      │ │
│ (Static Web    │    │ (Static Web     │ │
│  App - Free)   │    │  App - Free)    │ │
└────────┬───────┘    └────────┬────────┘ │
         │                     │          │
         │ Direct Access       │          │
         │                     │          │
┌────────▼────────┐   ┌───────▼────────┐ │
│   Whiteboard    │   │   Telehealth   │ │
│   Backend       │   │   Backend      │ │
│ (App Service    │   │ (App Service   │ │
│   B1 - Minimal) │   │  B1 - Minimal) │ │
└────────┬────────┘   └───────┬────────┘ │
         │                    │          │
         └────────────────────┴──────────┘
                      │
         ┌────────────┴────────────┐
         │   Shared Resources      │
         │  (All Apps Access)      │
         │                         │
         │  ▪ Cosmos DB (MongoDB)  │
         │  ▪ Storage Account      │
         │  ▪ Key Vault            │
         │  ▪ Virtual Network      │
         │  ▪ Log Analytics        │
         │  ▪ Application Insights │
         └─────────────────────────┘
```

---

## 🔄 Data Flow: Main Portal

```
User Browser
    │
    │ 1. HTTPS Request
    ├──────────────────────────────────────────────┐
    │                                              │
    ▼                                              ▼
┌─────────────────────┐                  ┌─────────────────────┐
│  Azure Front Door   │                  │  Azure Front Door   │
│  (WAF Check)        │                  │  (WAF Check)        │
└──────────┬──────────┘                  └──────────┬──────────┘
           │                                        │
           │ 2. Forward /*                          │ 3. Forward /api/*
           │                                        │
    ┌──────▼──────┐                          ┌─────▼─────┐
    │   Main      │                          │   Main    │
    │  Frontend   │ 4. API Call (AJAX)       │  Backend  │
    │  (Static    ├──────────────────────────►   (App    │
    │   Web App)  │                          │  Service) │
    └─────────────┘                          └─────┬─────┘
                                                   │
                                                   │ 5. Read/Write
                                                   │
                                        ┌──────────▼──────────┐
                                        │  Cosmos DB          │
                                        │  Storage Account    │
                                        │  (PHI Files)        │
                                        └─────────────────────┘
```

---

## 📱 Data Flow: Whiteboard (iFrame Embedded)

```
User Browser (Main Portal)
    │
    │ 1. Load Main Portal
    │
    ▼
┌─────────────────────┐
│   Main Frontend     │
│   (Renders iframe)  │
└──────────┬──────────┘
           │
           │ 2. <iframe src="whiteboard-url">
           │
    ┌──────▼──────┐
    │  Whiteboard │  3. Direct HTTPS (No Front Door)
    │  Frontend   ├────────────────────────────┐
    │  (Static    │                            │
    │   Web App)  │                            │
    └─────────────┘                            │
                                               │
                                        ┌──────▼─────┐
                                        │ Whiteboard │
                                        │  Backend   │
                                        │   (App     │
                                        │  Service)  │
                                        └──────┬─────┘
                                               │
                                        ┌──────▼──────┐
                                        │  Cosmos DB  │
                                        │  (Shared)   │
                                        └─────────────┘
```

**Key Points:**
- 🔹 Whiteboard is accessed **directly** (not via Front Door)
- 🔹 Embedded in Main Portal via `<iframe>`
- 🔹 Shares same Cosmos DB and Storage as Main App
- 🔹 Uses token-based auth (token passed from Main Portal)

---

## 🎥 Data Flow: Telehealth (iFrame Embedded)

```
User Browser (Main Portal)
    │
    │ 1. Load Main Portal
    │
    ▼
┌─────────────────────┐
│   Main Frontend     │
│   (Renders iframe)  │
└──────────┬──────────┘
           │
           │ 2. <iframe src="telehealth-url" allow="camera; microphone">
           │
    ┌──────▼──────┐
    │  Telehealth │  3. Direct HTTPS (No Front Door)
    │  Frontend   ├────────────────────────────┐
    │  (Static    │                            │
    │   Web App)  │                            │
    └─────────────┘                            │
                                               │
                                        ┌──────▼─────┐
                                        │ Telehealth │
                                        │  Backend   │
                                        │   (App     │
                                        │  Service)  │
                                        └──────┬─────┘
                                               │
                                        ┌──────▼──────┐
                                        │  Cosmos DB  │
                                        │  (Shared)   │
                                        └─────────────┘
```

**Key Points:**
- 🔹 Telehealth is accessed **directly** (not via Front Door)
- 🔹 Embedded in Main Portal via `<iframe>` with camera/mic permissions
- 🔹 Shares same Cosmos DB for call history/scheduling
- 🔹 Uses WebRTC for video streaming (P2P or TURN server)

---

## 🔐 Security Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                         Layer 1: Front Door WAF                  │
│  ▪ OWASP Top 10 Protection                                      │
│  ▪ Bot Protection                                               │
│  ▪ DDoS Mitigation                                              │
│  ▪ Rate Limiting                                                │
│  Applies to: Main Portal Only                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                    Layer 2: App Service (VNet)                   │
│  ▪ VNet Integration (all backends)                              │
│  ▪ Private Endpoints (Cosmos DB, Storage, Key Vault)           │
│  ▪ NSG Rules (deny all inbound except VNet)                    │
│  Applies to: All 3 Backends                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                  Layer 3: Authentication & Authorization         │
│  ▪ Azure AD / JWT Tokens                                        │
│  ▪ Tenant Isolation (multi-tenancy)                             │
│  ▪ RBAC (Role-Based Access Control)                             │
│  Applies to: All Applications                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                     Layer 4: Data Encryption                     │
│  ▪ TLS 1.2+ (in-transit)                                        │
│  ▪ AES-256 (at-rest for Cosmos DB, Storage)                    │
│  ▪ Infrastructure Encryption (Storage double encryption)        │
│  ▪ Key Vault for secrets                                        │
│  Applies to: All Data                                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Resource Naming Convention

```
Environment: prod
Prefix: agilis

Resources Created:
├─ Resource Group
│  └─ rg-agilis-prod-core
│
├─ Main Portal
│  ├─ swa-agilis-prod                    (Static Web App)
│  └─ app-agilis-prod-api                (App Service)
│
├─ Whiteboard
│  ├─ swa-agilis-prod-whiteboard         (Static Web App)
│  └─ app-agilis-prod-api-whiteboard     (App Service)
│
├─ Telehealth
│  ├─ swa-agilis-prod-telehealth         (Static Web App)
│  └─ app-agilis-prod-api-telehealth     (App Service)
│
├─ Shared Resources
│  ├─ vnet-agilis-prod                   (Virtual Network)
│  ├─ nsg-agilis-prod-app                (NSG - App Subnet)
│  ├─ nsg-agilis-prod-data               (NSG - Data Subnet)
│  ├─ cosmos-agilis-prod                 (Cosmos DB)
│  ├─ st-agilis-prod-<random>            (Storage Account)
│  ├─ kv-agilis-prod-<random>            (Key Vault)
│  ├─ law-agilis-prod                    (Log Analytics)
│  ├─ appi-agilis-prod                   (App Insights)
│  └─ fd-agilis-prod-<hash>              (Front Door)
```

---

## 🎯 Traffic Routing (Production)

### Main Portal (via Front Door)

```
Custom Domain: portal.agilis.com
├─ /* → Main Frontend (Static Web App)
└─ /api/* → Main Backend (App Service)
```

### Whiteboard (Direct Access)

```
Default URL: swa-agilis-prod-whiteboard.azurestaticapps.net
Backend API: app-agilis-prod-api-whiteboard.azurewebsites.net

Embedded in Main Portal:
<iframe src="https://swa-agilis-prod-whiteboard.azurestaticapps.net?token=xxx&tenantId=yyy">
```

### Telehealth (Direct Access)

```
Default URL: swa-agilis-prod-telehealth.azurestaticapps.net
Backend API: app-agilis-prod-api-telehealth.azurewebsites.net

Embedded in Main Portal:
<iframe src="https://swa-agilis-prod-telehealth.azurestaticapps.net?token=xxx&tenantId=yyy"
        allow="camera; microphone; display-capture">
```

---

## 📊 Cost Breakdown (Production)

```
┌──────────────────────┬──────────┬──────────┬─────────────┐
│ Resource             │ SKU      │ Quantity │ Est. Cost   │
├──────────────────────┼──────────┼──────────┼─────────────┤
│ Main Frontend        │ Standard │ 1        │ ~$25/month  │
│ Main Backend         │ P1v3     │ 1        │ ~$110/month │
│ Whiteboard Frontend  │ Free     │ 1        │ $0          │
│ Whiteboard Backend   │ B1       │ 1        │ ~$13/month  │
│ Telehealth Frontend  │ Free     │ 1        │ $0          │
│ Telehealth Backend   │ B1       │ 1        │ ~$13/month  │
│ Front Door Premium   │ Premium  │ 1        │ ~$35/month  │
│ Cosmos DB            │ Autoscale│ 1        │ ~$50-200/mo │
│ Storage Account      │ ZRS      │ 1        │ ~$20/month  │
│ Key Vault            │ Standard │ 1        │ ~$5/month   │
│ Log Analytics        │ Pay-as-go│ 1        │ ~$10/month  │
│ Application Insights │ Pay-as-go│ 1        │ ~$10/month  │
├──────────────────────┴──────────┴──────────┼─────────────┤
│ TOTAL (6 Apps + Infrastructure)            │ ~$291-441/mo│
└────────────────────────────────────────────┴─────────────┘
```

**Note:** Cosmos DB cost varies based on RU/s usage (50-200 RU/s autoscale)

---

## 🔧 Scaling Strategy

### Main Backend (High Load)
- **Current:** P1v3 (2 cores, 8GB RAM)
- **Scale Up:** P2v3, P3v3 (more CPU/RAM)
- **Scale Out:** Increase instance count (2-10 instances)

### Whiteboard Backend (Low Load)
- **Current:** B1 (1 core, 1.75GB RAM)
- **Scale Up:** B2, B3 if needed (unlikely)
- **Scale Out:** Typically not needed

### Telehealth Backend (Low Load)
- **Current:** B1 (1 core, 1.75GB RAM)
- **Scale Up:** S1/S2 if WebRTC signaling grows
- **Scale Out:** Typically not needed

### Cosmos DB (Shared)
- **Current:** Autoscale (400-4000 RU/s)
- **Scale:** Automatically scales based on load
- **Manual:** Increase max RU/s if hitting limits

---

**Last Updated:** December 18, 2025  
**Document Version:** 1.0  
**Status:** Production-Ready
