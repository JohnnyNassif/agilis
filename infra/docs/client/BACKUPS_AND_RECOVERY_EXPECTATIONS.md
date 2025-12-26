# Backups and Recovery Expectations (Client)

This document explains what is backed up, retention expectations, and how to request a restore.

**Important:** Infrastructure and platform configuration is managed by the Agilis operator. The client’s role is to understand expectations and request restores when needed.

---

## What is covered

### Cosmos DB (Mongo API)
- Cosmos DB backups are configured in infrastructure.
- Backup mode is either:
  - **Continuous** (point‑in‑time restore), or
  - **Periodic** (scheduled backups with a fixed retention window)

**Current infrastructure behavior (reference):**
- If continuous backups are enabled: restore uses a **point-in-time** workflow.
- If periodic backups are enabled: backups run every **240 minutes** with **8 hours** retention.

---

### Storage Account (PHI files)
- Storage uses a lifecycle policy for long-term retention and cost management.
- Policy expectations include:
  - archive movement for old files
  - deletion after long retention (example: 7 years) depending on policy configuration

**Important:** Deletions performed by lifecycle policy are intended and may be permanent. Confirm retention requirements before production use.

---

### Key Vault (secrets)
- Key Vault typically uses **soft delete** to protect against accidental deletion.
- Secret recovery depends on whether soft delete and purge protection are enabled in the environment.

---

### Logs and monitoring data
- Operational logs live in Log Analytics / Application Insights.
- Retention depends on workspace configuration and any regulatory requirements the client chooses.

---

## Recovery objectives (targets)

These should be confirmed during onboarding:
- **RPO (Recovery Point Objective):** target data loss window (e.g., minutes/hours)
- **RTO (Recovery Time Objective):** target time to restore service (e.g., hours)

---

## How to request a restore (client)

When a restore is needed, send the following to the Agilis operator:

### 1) Restore request details
- **Environment:** dev / prod
- **Resource type:** Cosmos DB / Storage / Key Vault / Other
- **Severity:** normal / urgent / emergency
- **Incident start time (UTC):**
- **Desired restore time (UTC):** (for point‑in‑time requests)

### 2) Scope
- What data is affected (tenant/customer, user IDs, time range)
- What functionality is impacted

### 3) Verification plan (client)
- What to validate after restore (key screens, API calls, file download/upload, etc.)
- Who will sign off that recovery is successful

---

## Notes on restores (high level)

### Cosmos DB
- Continuous backup restores are point‑in‑time (to a specified timestamp).
- Restores may create a new account/restore target depending on Azure restore mechanics; the operator will coordinate cutover.

### Storage
- File recovery depends on how deletion occurred:
  - application deletion
  - lifecycle policy deletion
  - soft delete / snapshots (if enabled)

### Key Vault
- If a secret was deleted and soft delete is enabled, it may be recoverable.

---

## Recommended client operational practice

- Define RPO/RTO targets for production.
- Perform a **planned restore test** after go-live (and periodically after).
- Treat lifecycle policy deletions as permanent unless a separate legal hold process is defined.




