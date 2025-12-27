# Architecture Diagram - Multi-App Setup (Client-Facing)

This document provides a client-facing, high-level view of the Agilis Azure platform.

---

## High-level architecture (public entry)

```
Internet
  |
  | HTTPS (WAF protected)
  v
Azure Front Door (WAF)
  |
  +--> Frontend traffic (/*) -> Static Web App(s)
  |
  +--> API traffic (/api/*)  -> Backend App Service(s)
```

Notes:
- Azure Front Door is the recommended public entry point (custom domain supported).
- Backend App Services are hardened to accept traffic only from Front Door (including SCM/Kudu).

---

## Data flow: portal -> API -> data services

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
    │  Frontend   │ 4. API Call              │  Backend  │
    │  (SWA)      ├──────────────────────────► (AppSvc)  │
    └─────────────┘                          └─────┬─────┘
                                                   │
                                                   │ 5. Read/Write
                                                   │
                                        ┌──────────▼──────────┐
                                        │  Data services      │
                                        │  - Cosmos DB (Mongo)│
                                        │  - Storage (blobs)  │
                                        │  - Key Vault        │
                                        └─────────────────────┘
```

---

## Multi-app note (portal, whiteboard, telehealth)

Some environments include multiple frontends/backends (e.g., Portal, Whiteboard, Telehealth).
These may be embedded (iframe) or separate apps depending on the client implementation.

Security posture remains the same:
- Prefer **Front Door** as the public entry point.
- Keep backend App Services restricted to Front Door.

---

## Security layers (summary)

```
Layer 1: Front Door / WAF
  - OWASP protections, bot mitigation, rate limiting (configuration dependent)

Layer 2: Network isolation
  - App Service VNet integration
  - Private endpoints for data services (Cosmos/Storage/Key Vault)
  - NSG controls and flow logs (where enabled)

Layer 3: Identity and access
  - Azure RBAC for management access
  - Managed identities for service-to-service access

Layer 4: Encryption and secrets
  - TLS 1.2+ in transit
  - Encryption at rest (including infrastructure encryption where configured)
  - Secrets in Key Vault (or Key Vault references into App Service)
```

---

## Naming and sizing

Resource names, SKUs, and exact sizing vary by environment. The client should treat these as implementation details and request current values from the Agilis operator if needed.

