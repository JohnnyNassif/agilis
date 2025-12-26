# Microsoft Sentinel Guide (Client)

This guide explains how to use **Microsoft Sentinel** for security monitoring: how to confirm it’s working, how to triage incidents, and how to run basic investigations.

**Important:** Infrastructure configuration is managed by the Agilis operator. The client uses Sentinel for visibility and incident handling.

---

## Prerequisites

- You have Azure Portal access to:
  - **Microsoft Sentinel**
  - The **Log Analytics workspace** used by Sentinel
- You have permissions to view incidents and run queries (ask your admin/operator if you see access denied).

---

## Where to access Sentinel

In Azure Portal:
1. Search: **Microsoft Sentinel**
2. Select the Sentinel instance (it is attached to a Log Analytics workspace)
3. Use these core areas:
   - **Incidents**
   - **Analytics**
   - **Logs**
   - **Data connectors** (if available in your tenant experience)

---

## What “healthy” looks like

### 1) Incidents
- You see new incidents appear over time (not necessarily daily)
- Incidents have:
  - severity
  - tactics/techniques (sometimes)
  - entities (IP, host, account) when available

### 2) Analytics rules
- Rules are **Enabled**
- Rule executions are happening (depending on rule schedule)
- When rules trigger, they generate **alerts/incidents**

### 3) Data ingestion
- Sentinel depends on data arriving in Log Analytics (tables populated).
- Some sources appear as “connectors”; others arrive via **diagnostic settings**.

**Note:** In this platform, many resource logs (Key Vault, Storage, Cosmos, Front Door diagnostics) are sent via Azure diagnostic settings into Log Analytics. Sentinel rules query those Log Analytics tables.

---

## Daily/weekly operational workflow

### Step 1 — Review incidents
Sentinel → **Incidents**
- Sort by **Severity** and **Created time**
- Start with **High** and **Medium**

For each incident:
- Read the summary
- Review involved entities (IP, accounts, URLs)
- Check if it correlates with a known release window (see `RELEASE_PROCESS_AND_SUPPORT.md`)

### Step 2 — Triage and assign
- Set **Owner**
- Set **Status**: New → Active → Closed
- Add a short note: what was observed + next action

### Step 3 — Investigate using Logs (KQL)
Sentinel → **Logs**
- Use KQL queries (examples below)

---

## Basic KQL queries (copy/paste starting points)

### 1) Recent Sentinel incidents (overview)
```kusto
SecurityIncident
| sort by TimeGenerated desc
| take 50
```

### 2) Recent Azure activity (control-plane changes)
```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| sort by TimeGenerated desc
| take 200
```

### 3) Key Vault audit activity (if enabled)
Many Key Vault events arrive in `AzureDiagnostics` depending on diagnostic configuration.
```kusto
AzureDiagnostics
| where TimeGenerated > ago(24h)
| where ResourceProvider == "MICROSOFT.KEYVAULT"
| sort by TimeGenerated desc
| take 200
```

### 4) Front Door / WAF signals (if enabled)
Front Door WAF logs commonly appear in either a dedicated table or `AzureDiagnostics` depending on configuration.
Start broad:
```kusto
search "FrontDoor" or "WAF"
| where TimeGenerated > ago(24h)
| take 200
```

---

## Validation (how to confirm Sentinel is working)

Use a non-invasive approach:
1. Confirm data is present in Log Analytics (tables returning results).
2. Confirm at least one analytics rule is **Enabled**.
3. Confirm incidents appear historically (even if none are new today).

If you need a controlled “test”, coordinate with the Agilis operator so the test is safe and time-boxed.

---

## Escalation to Agilis operator

When you escalate a Sentinel-related issue, include:
- Incident ID / name
- Severity
- Time range (UTC)
- Entities involved (IP, account, host)
- Screenshots of:
  - incident summary
  - analytics rule (name + enabled status)
  - relevant Logs query results

Use `INCIDENT_RESPONSE_AND_SECURITY_EVENTS.md` for the standard escalation package.




