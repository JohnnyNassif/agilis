# Custom Domain and DNS Setup

This guide explains how to connect your custom domain(s) (e.g., `portal.example.com`, `api.example.com`) to the Agilis platform.

**Important:**
- The client typically manages **DNS**.
- Infrastructure changes (Front Door / certificates / domain bindings) are performed by the **Agilis operator**.
- The client provides DNS records and completes domain validation steps as instructed.

---

## What domains are typically used

Common patterns:
- **Frontend (portal)**: `portal.example.com`
- **API** (optional): `api.example.com` or `portal.example.com/api`

Your platform uses Azure Front Door as the public entry point, so the recommended pattern is:
- Use **Front Door** for the primary public hostname.
- Route `/api/*` to the backend through Front Door.

---

## Inputs the client must provide to the Agilis operator

- The domain(s) you want to use (e.g., `portal.example.com`)
- Which DNS provider you use (Azure DNS, Cloudflare, GoDaddy, etc.)
- Who can create DNS records (name/email of DNS admin)

---

## Step 1 — DNS change request

The Agilis operator will provide the exact target hostnames/values. The client will create the required DNS record(s).

### Typical DNS record for Front Door (CNAME)

- **Record type**: CNAME
- **Name/host**: `portal` (for `portal.example.com`)
- **Value/target**: the Front Door endpoint hostname, e.g. `fd-<env>.azurefd.net`

**Notes:**
- You cannot use a CNAME at the DNS zone apex (`example.com`). Use a subdomain like `portal.example.com`.
- DNS propagation can take minutes to hours depending on TTL and provider.

---

## Step 2 — Domain validation (client + operator)

Azure will require domain ownership validation before enabling the custom domain on Front Door.

The Agilis operator will provide the required validation record. The client will create it in DNS (commonly a TXT record).

Wait for propagation, then confirm validation succeeds in Azure Portal (operator will finalize the binding).

---

## Step 3 — TLS certificate (operator)

Front Door can manage certificates automatically (recommended) once the custom domain is validated.

The operator will enable HTTPS on the custom domain and confirm:
- Certificate is issued
- HTTPS works
- HTTP redirects to HTTPS (if enabled)

---

## Step 4 — Verification

Once DNS + binding is complete, verify:

1) **Frontend loads**
- Open: `https://portal.example.com`

2) **API routes work through Front Door**
- If the API is served under `/api`, verify:
  - `https://portal.example.com/api/...`

3) **No direct backend access**
- The `*.azurewebsites.net` backend URL should be blocked (if access restrictions are enabled).

---

## Common issues

### “CNAME created but site still not working”
- DNS propagation delay (wait, then retry)
- Wrong record name (e.g., created `portal.example.com.example.com`)
- Wrong target hostname

### “HTTPS certificate not issued”
- Domain validation not complete
- DNS record not propagated
- Conflicting DNS records (multiple CNAME/TXT entries)

### “API works on `azurefd.net` but not on custom domain”
- Custom domain not linked to Front Door route(s)
- Route patterns missing `/api/*` mapping
- Escalate to the Agilis operator with:
  - custom domain name
  - Front Door hostname
  - failing URL(s) and timestamps






