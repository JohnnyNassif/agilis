# HIPAA Business Associate Agreement (BAA) Signing Guide (Client)

This document explains how to execute a HIPAA **Business Associate Agreement (BAA)** with Microsoft for Azure, and what the client should understand before signing.

**Disclaimer:** This is operational guidance, not legal advice. The client should review all terms with counsel/compliance leadership.

---

## What the Microsoft “BAA” is for Azure

Microsoft’s HIPAA BAA for Azure is generally provided **as part of Microsoft’s standard online terms**, specifically through Microsoft’s:
- **Microsoft Product Terms**, and
- **Microsoft Products and Services Data Protection Addendum (DPA)** / **Online Services Terms**

In other words, there is typically **no separate custom BAA document that Microsoft manually countersigns** for Azure. The BAA is incorporated into the standard contractual terms you accept for Microsoft cloud services.

---

## Before you sign: what you must confirm

### 1) Your Azure purchasing agreement type
Confirm how you purchase Azure:
- Microsoft Customer Agreement (MCA)
- Enterprise Agreement (EA)
- Cloud Solution Provider (CSP)

Your purchasing channel determines where you review/accept terms and how you obtain the BAA copy.

### 2) Services in scope for HIPAA
Confirm that the Azure services you use to store/process PHI are **in-scope** for HIPAA under Microsoft’s compliance offering.

### 3) Shared responsibility
Signing a BAA does **not** make the solution “automatically HIPAA compliant.” The client must also maintain administrative, technical, and physical safeguards (policies, access control, monitoring, incident response, training, etc.).

---

## How to execute the BAA (practical steps)

### Step 1 — Review Microsoft HIPAA offering documentation
Microsoft publishes guidance on HIPAA and Azure compliance offerings. Review:
- `https://learn.microsoft.com/en-us/azure/compliance/offerings/offering-hipaa-us`

This page explains how the BAA is provided and what services/commitments are included.

### Step 2 — Ensure your organization has accepted the required online terms
The client’s legal/procurement owner should confirm acceptance of:
- Microsoft Product Terms, and
- Microsoft Products and Services DPA / Online Services Terms

**Where to do this:** depends on whether the client uses MCA, EA, or CSP. If unsure, the client should contact their Microsoft account team or CSP partner for the exact “acceptance” workflow for their agreement type.

### Step 3 — Obtain a copy of the BAA language for your records
The client should download and store the relevant BAA/DPA language (for audit/compliance records). Typically:
- Microsoft provides compliance documentation via the **Microsoft Service Trust Portal** (access may require the correct tenant permissions).

If the client cannot access the Service Trust Portal or is uncertain which document applies, contact Microsoft support/account rep to obtain the correct copy for the client’s agreement.

---

## What information the client should prepare for signing (checklist)

- **Legal entity name** that owns the Azure subscription/tenant
- **Tenant ID** and **Subscription ID(s)** that will host PHI workloads
- **List of Azure services used** for PHI (at minimum: Storage, Key Vault, Cosmos DB, App Service, Front Door/WAF, Log Analytics/Sentinel)
- **Security contacts** (for incident coordination)
- **Retention requirements** (records retention policy, log retention expectations)
- **Internal HIPAA program artifacts** (risk assessment, policies, access reviews, incident response plan)

---

## Operational responsibilities after signing (high level)

The client should ensure the following are implemented and maintained:
- Least privilege access (Azure RBAC)
- Auditing/monitoring (Log Analytics, Sentinel, App Insights)
- Incident response process (see `INCIDENT_RESPONSE_AND_SECURITY_EVENTS.md`)
- Data retention policies (see `BACKUPS_AND_RECOVERY_EXPECTATIONS.md`)
- PHI hardening steps completed (see `SECURITY_HARDENING_AND_VERIFICATION.md` and shared checklists)

---

## When to escalate

If the client needs a “signed document” version or is being asked by a counterparty for a separately executed BAA:
- Engage Microsoft account representative and/or legal counsel.
- Confirm whether the standard DPA/Product Terms satisfy the requirement for the client’s procurement/compliance process.




