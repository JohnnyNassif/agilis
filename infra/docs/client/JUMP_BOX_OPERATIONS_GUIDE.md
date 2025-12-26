# Jump Box (Bastion VM) Operations Guide (Client)

This guide explains how to use the **Windows jump box** (accessed via **Azure Bastion**) to:
- connect to the Storage Account using **Azure Storage Explorer**
- read secrets from **Azure Key Vault**
- connect to **Cosmos DB (Mongo API)** using a database IDE (recommended: **MongoDB Compass**)

**Why a jump box:** After public access is disabled on data services (Storage/Key Vault/Cosmos), access is intended to happen from inside the Azure VNet. The jump box provides that secure “inside the network” workstation.

**Important:** Infrastructure (Terraform) is managed by the Agilis operator. The client uses the jump box for approved operational tasks.

---

## What you need from the Agilis operator

Before you start, request:
- **Resource group name**
- **Jump VM name**
- **Bastion host name** (if you will connect via portal)
- **VM local admin username**
- **VM password** (or confirmation that you should use a portal password reset)
- **Key Vault name**
- **Cosmos DB account name** (Mongo API)
- **Storage account name**

---

## Step 1 — Connect to the jump VM using Azure Bastion

In Azure Portal:
1. Go to **Virtual Machines** → select the jump VM (name usually contains `jmp`)
2. Click **Connect** → **Bastion**
3. Enter the **username** and **password** provided by the Agilis operator
4. Connect (browser-based RDP)

**Tip:** If connection fails, confirm the VM is **Running** and the Bastion resource is present in the environment.

---

## Step 2 — Sign in to Azure from the VM (recommended)

Open **PowerShell** on the jump VM and run:

```powershell
az login
az account set --subscription "<SUBSCRIPTION_ID>"
```

If you are instructed to use the VM managed identity (operator-controlled), use:

```powershell
az login --identity
```

---

## Step 3 — Read secrets from Azure Key Vault (from the VM)

### A) Using Azure CLI (recommended)

```powershell
$VAULT="<KEY_VAULT_NAME>"

# Example: Cosmos connection string
az keyvault secret show --vault-name $VAULT --name "cosmos-connection-string" --query value -o tsv

# Example: Storage account name
az keyvault secret show --vault-name $VAULT --name "storage-account-name" --query value -o tsv

# Example: Storage account key (if used)
az keyvault secret show --vault-name $VAULT --name "storage-account-key" --query value -o tsv
```

### B) Using Azure Portal (if allowed)
Key Vault may be restricted to private access; portal access depends on environment policy. Prefer CLI from the jump VM.

---

## Step 4 — Connect to the Storage Account using Azure Storage Explorer

### Install Azure Storage Explorer (first time only)
1. Download and install **Microsoft Azure Storage Explorer** (Windows)
2. Launch Storage Explorer

### Recommended sign-in
1. In Storage Explorer: **Account Management** → **Add an account**
2. Sign in with your Azure AD user that has storage permissions (provided/approved by the Agilis operator)

### Browse the storage account
1. Expand your subscription
2. Expand **Storage Accounts**
3. Select the storage account name provided by the operator
4. Navigate to **Blob Containers** and browse contents

**If you cannot see the account:**
- You may not have the necessary Azure RBAC role (e.g., Storage Blob Data Reader/Contributor)
- Ask the Agilis operator to confirm your access level and scope

---

## Step 5 — Connect to Cosmos DB (Mongo API) using MongoDB Compass (recommended)

### Install MongoDB Compass (first time only)
1. Install **MongoDB Compass** on the jump VM

### Get the connection string from Key Vault
From PowerShell on the VM:

```powershell
$VAULT="<KEY_VAULT_NAME>"
$COSMOS_CONN = az keyvault secret show --vault-name $VAULT --name "cosmos-connection-string" --query value -o tsv
$COSMOS_CONN
```

### Connect from MongoDB Compass
1. Open MongoDB Compass
2. Paste the connection string
3. Ensure TLS/SSL is enabled (Cosmos Mongo requires TLS)
4. Connect

### Quick DNS verification (recommended if connect fails)
In PowerShell:

```powershell
nslookup <COSMOS_ACCOUNT_NAME>.mongo.cosmos.azure.com
```

Expected: a **private IP** response (if private DNS is configured and public access is disabled).

---

## Troubleshooting

### “Cannot reach Storage/Key Vault/Cosmos”
- Confirm you are doing the operation **from the jump VM** (not your local machine)
- Confirm private DNS resolution from the VM using `nslookup`
- Escalate to the Agilis operator if DNS resolves to a public IP or the private endpoint is unhealthy

### “Key Vault secret show returns access denied”
- Your user (or the VM identity) does not have Key Vault permissions
- Ask the Agilis operator to confirm the approved access model for the client

### “MongoDB Compass auth fails”
- Ensure you’re using the correct connection string (from Key Vault)
- Confirm the account allows key-based authentication (operator-managed setting)

---

## Security notes (must follow)

- Treat the VM password and any Key Vault secret values as **sensitive**.
- Do not copy PHI to your local machine unless explicitly approved by policy.
- Install only approved tools on the jump VM.
- Log out and close the Bastion session when finished.

---

## Appendix: Tool installation links (official)

Recommended tools for the jump VM:

- **Azure CLI (Windows)**: [Install Azure CLI on Windows](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows)
- **Azure Storage Explorer**: [Azure Storage Explorer](https://azure.microsoft.com/en-us/products/storage/storage-explorer/)
- **MongoDB Compass**: [Download MongoDB Compass](https://www.mongodb.com/try/download/compass)
- **Visual Studio Code** (optional editor): [Download VS Code](https://code.visualstudio.com/Download)
- **Windows Terminal** (optional): [Microsoft Store: Windows Terminal](https://aka.ms/terminal)

If the jump VM allows `winget`, you can also install some tools from PowerShell (examples):

```powershell
winget install -e --id Microsoft.AzureCLI
winget install -e --id Microsoft.VisualStudioCode
```


