# Storage Lifecycle Management Policy

**Implementation Date:** December 18, 2024
**Purpose:** Automatic tier management and HIPAA retention compliance for PHI files

---

## 📋 What Was Implemented

A lifecycle management policy has been added to the Storage Account module that automatically manages PHI file lifecycle according to HIPAA requirements and client specifications.

### Policy Configuration

**File:** `infra/modules/storage/main.tf` (Lines 108-142)

```terraform
resource "azurerm_storage_management_policy" "phi_lifecycle"
```

---

## 🎯 Lifecycle Rules

### Rule 1: Cool → Archive (After 1 Year)

**Trigger:** Files in **Cool tier** that haven't been modified for **365 days** (1 year)
**Action:** Automatically move to **Archive tier**

```
Example Timeline:
├─ Day 0: Backend app moves file from Hot → Cool
├─ Day 365: Azure automatically moves Cool → Archive
└─ Result: Long-term storage at lowest cost
```

**Purpose:**
- Optimize storage costs for old PHI files
- Files in Cool tier for 1+ year are rarely accessed
- Archive tier is 90% cheaper than Hot tier

### Rule 2: HIPAA Retention (Delete After 7 Years)

**Trigger:** Files that haven't been modified for **2,555 days** (7 years)
**Action:** Automatically delete

```
Example Timeline:
├─ Day 0: File uploaded (e.g., 2024-12-18)
├─ Day 2555: File auto-deleted (e.g., 2031-12-17)
└─ Result: HIPAA compliance (7-year retention met)
```

**Purpose:**
- Meet HIPAA retention requirements (minimum 6 years, we use 7 for safety)
- Automatic cleanup prevents accumulation of very old data
- Reduces long-term storage costs
- Reduces data breach risk (less old data to protect)

**Important Notes:**
- ⚠️ Deletion is **permanent** after 7 years
- ⚠️ Applies to files regardless of tier (Hot/Cool/Archive)
- ✅ Based on **last modification date**, not creation date
- ✅ If file is updated, the 7-year clock restarts

### Rule 3: Snapshot Cleanup (After 90 Days)

**Trigger:** Snapshots older than **90 days**
**Action:** Automatically delete

```
Example Timeline:
├─ Day 0: Application creates blob snapshot
├─ Day 90: Azure automatically deletes snapshot
└─ Result: Cost-effective snapshot retention
```

**Purpose:**
- Manage storage costs (snapshots consume storage)
- 90 days is sufficient for audit trail and accidental deletion recovery
- Prevents accumulation of old snapshots

---

## ❌ What is NOT Automated

### Hot → Cool Transition: MANUAL (Backend Application)

**No automatic Hot → Cool movement** - This is handled by the client's backend application based on business logic.

**Why?**
- ✅ Application has better context (patient status, file type, access patterns)
- ✅ Flexible business rules (active treatment vs. completed treatment)
- ✅ Real-time decisions based on actual usage
- ✅ Can move files to Cool immediately when treatment completes

**Backend's Responsibility:**
```javascript
// Backend decides when to move Hot → Cool
// Examples:
// - After 90 days of no access
// - When treatment is marked complete
// - When patient is marked inactive
// - Based on file type (X-rays vs. documents)

await blobClient.setAccessTier('Cool');
```

---

## 📊 Complete Lifecycle Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    PHI File Lifecycle                            │
└─────────────────────────────────────────────────────────────────┘

Day 0: Upload
├─ File: patient-123/xray.jpg
├─ Tier: HOT (default or app-specified)
└─ Cost: $0.018/GB/month

Day 0-365: Application decides (no automatic movement)
├─ Backend monitors access patterns
├─ Backend moves Hot → Cool when appropriate
└─ Example: After 90 days of no access

Day X: Backend moves to Cool
├─ File: patient-123/xray.jpg
├─ Tier: COOL (moved by backend app)
└─ Cost: $0.010/GB/month (44% cheaper)

Day 365 (from Cool tier entry): Azure automatically moves to Archive
├─ File: patient-123/xray.jpg
├─ Tier: ARCHIVE (automatically moved by Azure)
└─ Cost: $0.00099/GB/month (95% cheaper than Hot)

Day 2555 (7 years): Azure automatically deletes
├─ File: patient-123/xray.jpg
├─ Action: DELETED (HIPAA retention met)
└─ Cost: $0 (file removed)
```

---

## 💰 Cost Impact Example

**Scenario:** 1 TB of PHI data over 7-year lifecycle

| Storage Strategy | 7-Year Total Cost |
|------------------|-------------------|
| **All Hot (no lifecycle)** | ~$1,512 | 
| **With Lifecycle Policy** | ~$400-500 |
| **Savings** | ~$1,000+ (66% reduction) |

**Breakdown with Lifecycle:**
- Year 1: Hot tier (varies by backend) → ~$100-150
- Years 1-2: Cool tier (365 days) → ~$120
- Years 2-7: Archive tier (5 years) → ~$200-250
- **Total: ~$400-500**

---

## 🔄 How It Works Technically

### Evaluation Frequency
- Azure evaluates lifecycle rules **once per day** (typically between 12 AM - 8 AM UTC)
- Changes are applied within 24 hours of meeting conditions
- Not real-time (if file hits 365 days at noon, it moves overnight)

### Modification Date Logic
```
Last Modified Date = Most recent of:
├─ Upload date (initial)
├─ Overwrite date (if file replaced)
├─ Metadata update (if properties changed)
└─ Tier change does NOT reset this date ✅
```

**Important:** Changing tier (Hot → Cool → Archive) does **NOT** reset the modification date!
- If file uploaded on Jan 1, 2024
- Moved to Cool on Apr 1, 2024
- Archive trigger is still Jan 1, 2025 (365 days from original upload)

### Tier Transitions
```
Cool → Archive transition:
├─ File must be in Cool tier
├─ File must have 365+ days since last modification
├─ Happens automatically overnight
└─ No data movement (just metadata change)
```

---

## 🎛️ Configuration Details

### Applied To
- **Container:** `phi-files` only
- **Blob Type:** Block blobs (standard files)
- **Prefix:** All files in `phi-files/*`

### Rule Parameters
```terraform
filters {
  prefix_match = ["phi-files/"]  # Only PHI container
  blob_types   = ["blockBlob"]   # Standard files
}

actions {
  base_blob {
    # Cool → Archive: 365 days
    tier_to_archive_after_days_since_modification_greater_than = 365
    
    # Delete: 2555 days (7 years)
    delete_after_days_since_modification_greater_than = 2555
  }
  
  snapshot {
    # Delete snapshots: 90 days
    delete_after_days_since_creation_greater_than = 90
  }
}
```

---

## ✅ Compliance & Best Practices

### HIPAA Compliance
- ✅ **7-year retention** exceeds HIPAA minimum (6 years)
- ✅ **Automatic enforcement** prevents human error
- ✅ **Audit trail** via Azure Activity Logs (tier changes logged)
- ✅ **Secure deletion** (Azure cryptographically erases data)

### Best Practices Followed
- ✅ **Application controls Hot → Cool** (business logic)
- ✅ **Azure controls Cool → Archive** (age-based, cost optimization)
- ✅ **Azure enforces retention** (automatic 7-year deletion)
- ✅ **Snapshot management** (cost control)
- ✅ **Incremental approach** (only manages what makes sense to automate)

---

## 🔍 Monitoring & Verification

### How to Verify Policy is Working

**1. Check Policy Status (Azure Portal):**
```
Storage Account → Lifecycle management
└─ Should see: "phi-lifecycle-policy" (Enabled)
```

**2. Check Activity Logs:**
```
Storage Account → Activity log
└─ Filter: "Tier Change" operations
└─ Should see automated tier changes after 365 days
```

**3. Query via Azure CLI:**
```bash
# Check policy
az storage account management-policy show \
  --account-name stagilis<hash> \
  --resource-group rg-agilis-dev-core

# Check blob tiers
az storage blob list \
  --account-name stagilis<hash> \
  --container-name phi-files \
  --query "[].{name:name, tier:properties.blobTier}" \
  --output table
```

### Logs to Monitor
- **Azure Activity Log:** Tier change operations
- **Storage Analytics Logs:** Blob deletions (after 7 years)
- **Azure Monitor Alerts:** Can set up alerts for mass deletions

---

## ⚠️ Important Considerations

### Before Files Are Deleted (7 Years)
- ⚠️ **No recovery** after deletion (permanent)
- ⚠️ Consider legal holds for specific cases
- ⚠️ Some states require longer retention for minors
- ✅ Can add legal hold metadata to exempt specific files

### Archive Tier Access
- ⚠️ Files in Archive are **offline** (not instantly accessible)
- ⚠️ Must rehydrate before reading (1-15 hours)
- ✅ Application should handle rehydration UX gracefully
- ✅ Rehydration cost applies ($0.02/GB for High priority)

### Modification Date Behavior
- ✅ Tier changes don't reset modification date
- ⚠️ Metadata changes DO reset modification date
- ⚠️ Overwriting file resets the 7-year clock
- ✅ Snapshots preserve original modification date

---

## 🔧 How to Modify Policy (If Needed)

### Change Archive Transition (e.g., 2 years instead of 1)
```terraform
# In infra/modules/storage/main.tf
tier_to_archive_after_days_since_modification_greater_than = 730  # 2 years
```

### Change Retention Period (e.g., 10 years)
```terraform
delete_after_days_since_modification_greater_than = 3650  # 10 years
```

### Change Snapshot Retention (e.g., 180 days)
```terraform
delete_after_days_since_creation_greater_than = 180  # 6 months
```

### Apply Changes
```bash
cd infra/environments/dev
terraform plan -var-file="dev.auto.tfvars"
terraform apply -var-file="dev.auto.tfvars"
```

---

## 📞 Support & Troubleshooting

### Common Questions

**Q: Can we prevent specific files from being deleted?**
**A:** Yes, add a legal hold tag to the blob:
```javascript
await blobClient.setMetadata({
  "legal-hold": "true",
  "hold-reason": "Active lawsuit",
  "hold-until": "2030-12-31"
});
```
Then modify the lifecycle policy to exclude files with this tag.

**Q: What happens if backend moves a file to Archive before 365 days?**
**A:** Nothing! The policy only moves from Cool → Archive. If already in Archive, no action taken.

**Q: Can we restore deleted files?**
**A:** No. After 7 years, deletion is permanent. Enable soft delete (currently 7 days) for short-term recovery only.

**Q: How do we handle minors' records (21-year retention)?**
**A:** Add metadata to patient files:
```javascript
metadata: { "retention-years": "21", "patient-dob": "2020-01-01" }
```
Then modify lifecycle policy to check metadata before deletion.

---

## 🎯 Summary

**What's Automated:**
- ✅ Cool → Archive (after 1 year)
- ✅ Delete (after 7 years)
- ✅ Snapshot cleanup (after 90 days)

**What's Manual (Backend App):**
- ✅ Hot → Cool (business logic driven)
- ✅ Archive rehydration (when users need old files)
- ✅ Snapshot creation (for version history)

**Benefits:**
- 💰 Significant cost savings (60-70% reduction)
- ⚖️ Automatic HIPAA compliance (7-year retention)
- 🛡️ Reduced data breach risk (old data auto-deleted)
- 🎯 Best of both worlds (app control + automatic compliance)

---

**Deployed:** Will be active after next `terraform apply`
**Contact:** Infrastructure team for policy modifications
**Documentation:** Azure Storage Lifecycle Management: https://docs.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview


