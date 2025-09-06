# ALZ State Infrastructure Bootstrap Guide

This guide explains how to manually bootstrap the Terraform state infrastructure for your Azure Landing Zone (ALZ) implementation using the **Manual Bootstrap + Pipeline Management** approach.

## 🎯 **Why Manual Bootstrap?**

### **❌ Problems with Pipeline-Based State Creation:**
- **Chicken and Egg Problem**: You need state storage to run Terraform, but you're trying to create state storage with Terraform
- **Bootstrap Problem**: First deployment has no state backend, subsequent deployments need the state backend
- **Risk of State Loss**: If state infrastructure fails, you lose all state with no recovery mechanism

### **✅ Benefits of Manual Bootstrap:**
- **No Circular Dependencies**: State infrastructure exists before Terraform runs
- **Reliable Bootstrap**: One-time setup that's predictable and recoverable
- **Pipeline Focus**: Pipelines focus on infrastructure management, not state creation
- **Better Security**: Manual control over critical state infrastructure

## 🚀 **Bootstrap Process**

### **Prerequisites**

1. **Azure CLI installed and configured**
   ```bash
   az --version
   az login
   ```

2. **Appropriate Azure permissions**
   - Contributor role on the target subscription
   - Ability to create resource groups and storage accounts

3. **Access to your ALZ repositories**
   - `alz-platform` repository
   - Subscription repositories (`company-its-dev-tf`, `company-its-prod-tf`, etc.)

### **Step 1: Run the Bootstrap Script**

1. **Make the script executable:**
   ```bash
   chmod +x bootstrap-state-infrastructure.sh
   ```

2. **Run the bootstrap script:**
   ```bash
   ./bootstrap-state-infrastructure.sh
   ```

3. **Monitor the output:**
   The script will create:
   - Resource group: `rg-alz-state`
   - Platform state storage: `stalzplatformstate`
   - Subscription state storage accounts for each environment

### **Step 2: Configure GitHub Secrets**

After the bootstrap script completes, configure the following secrets in your GitHub repositories:

#### **Platform Repository (alz-platform) Secrets:**
```
TF_STATE_RG=rg-alz-state
TF_STATE_SA=stalzplatformstate
TF_STATE_CONTAINER=tfstate
TF_STATE_KEY=platform/terraform.tfstate
```

#### **Subscription Repository Secrets:**

**ITS Dev Repository (company-its-dev-tf):**
```
TF_STATE_RG=rg-alz-state
TF_STATE_SA=stalzitsdevstate
TF_STATE_CONTAINER=tfstate
TF_STATE_KEY=its-dev/terraform.tfstate
```

**ITS Prod Repository (company-its-prod-tf):**
```
TF_STATE_RG=rg-alz-state
TF_STATE_SA=stalzitsprodstate
TF_STATE_CONTAINER=tfstate
TF_STATE_KEY=its-prod/terraform.tfstate
```

**BS Dev Repository (company-bs-dev-tf):**
```
TF_STATE_RG=rg-alz-state
TF_STATE_SA=stalzbsdevstate
TF_STATE_CONTAINER=tfstate
TF_STATE_KEY=bs-dev/terraform.tfstate
```

**BS Prod Repository (company-bs-prod-tf):**
```
TF_STATE_RG=rg-alz-state
TF_STATE_SA=stalzbsprodstate
TF_STATE_CONTAINER=tfstate
TF_STATE_KEY=bs-prod/terraform.tfstate
```

**DG Dev Repository (company-dg-dev-tf):**
```
TF_STATE_RG=rg-alz-state
TF_STATE_SA=stalzdgdevstate
TF_STATE_CONTAINER=tfstate
TF_STATE_KEY=dg-dev/terraform.tfstate
```

**DG Prod Repository (company-dg-prod-tf):**
```
TF_STATE_RG=rg-alz-state
TF_STATE_SA=stalzdgprodstate
TF_STATE_CONTAINER=tfstate
TF_STATE_KEY=dg-prod/terraform.tfstate
```

### **Step 3: Test Your Workflows**

1. **Test Platform Deployment:**
   ```bash
   # In alz-platform repository
   gh workflow run terraform-deploy.yml
   ```

2. **Test Subscription Deployment:**
   ```bash
   # In each subscription repository
   gh workflow run terraform-deploy-required.yml
   ```

3. **Test CI Workflows:**
   ```bash
   # Create a test pull request to trigger CI
   gh pr create --title "Test CI workflow" --body "Testing CI workflow"
   ```

## 🔧 **Enhanced Workflow Features**

### **State Management Features Added:**

1. **State File Health Check**
   - Monitors state file size and age
   - Alerts if state file exceeds 100MB
   - Provides visibility into state file status

2. **Automatic State Backup**
   - Creates timestamped backups before apply operations
   - Enables recovery from failed deployments
   - Prevents state loss during operations

3. **State Locking**
   - Uses Azure AD authentication for state locking
   - Prevents concurrent modifications
   - Ensures state consistency

4. **State Drift Detection**
   - Detects changes between desired and actual state
   - Provides early warning of configuration drift
   - Helps maintain infrastructure consistency

5. **Detailed Plan Output**
   - Uses `-detailed-exitcode` for better plan handling
   - Distinguishes between no changes, changes, and errors
   - Provides clear feedback on plan results

## 🛠️ **Troubleshooting**

### **Common Issues:**

1. **Storage Account Already Exists**
   ```
   ⚠️ Storage account stalzplatformstate already exists, skipping...
   ```
   **Solution**: This is normal if you've run the script before. The script will skip existing resources.

2. **Permission Denied**
   ```
   ❌ Failed to create resource group rg-alz-state
   ```
   **Solution**: Ensure you have Contributor role on the subscription and are logged in with `az login`.

3. **State File Not Found**
   ```
   ℹ️ No existing state file to backup (first deployment)
   ```
   **Solution**: This is normal for first deployments. The backup step will be skipped.

4. **State Drift Detected**
   ```
   ⚠️ Changes detected - potential drift found
   ```
   **Solution**: Review the plan output to understand what changed and why.

### **Recovery Procedures:**

1. **State File Corruption:**
   ```bash
   # Restore from backup
   az storage blob copy start \
     --source-container tfstate \
     --source-blob platform/terraform.tfstate.backup.20241201-143022 \
     --destination-container tfstate \
     --destination-blob platform/terraform.tfstate \
     --account-name stalzplatformstate
   ```

2. **State Lock Issues:**
   ```bash
   # Force unlock (use with caution)
   terraform force-unlock <lock-id>
   ```

3. **Re-run Bootstrap:**
   ```bash
   # If you need to recreate state infrastructure
   ./bootstrap-state-infrastructure.sh
   ```

## 📋 **Verification Checklist**

After completing the bootstrap process, verify:

- [ ] Resource group `rg-alz-state` exists
- [ ] All storage accounts are created and accessible
- [ ] All containers are created with proper permissions
- [ ] GitHub secrets are configured in all repositories
- [ ] Platform deployment workflow runs successfully
- [ ] Subscription deployment workflows run successfully
- [ ] CI workflows run successfully on pull requests
- [ ] State files are created after first deployment
- [ ] State backups are created before apply operations

## 🔄 **Maintenance**

### **Regular Tasks:**

1. **Monitor State File Sizes**
   - Check state file sizes monthly
   - Investigate if any exceed 100MB
   - Consider state refactoring if needed

2. **Review State Backups**
   - Clean up old backups (older than 90 days)
   - Verify backup integrity
   - Test restore procedures

3. **Update Security Settings**
   - Review storage account access policies
   - Update service principal permissions
   - Rotate access keys if needed

## 🎉 **Next Steps**

After successful bootstrap:

1. **Deploy Platform Infrastructure**
   - Run the platform deployment workflow
   - Verify all platform resources are created
   - Test platform functionality

2. **Deploy Subscription Infrastructure**
   - Deploy each subscription environment
   - Verify cross-subscription connectivity
   - Test workload deployments

3. **Set Up Monitoring**
   - Configure state file monitoring
   - Set up drift detection alerts
   - Implement backup verification

4. **Document Your Setup**
   - Update team documentation
   - Create runbooks for common tasks
   - Train team members on the new process

## 📚 **Additional Resources**

- [Terraform Azure Backend Documentation](https://www.terraform.io/docs/language/settings/backends/azurerm.html)
- [Azure Storage Account Security Best Practices](https://docs.microsoft.com/en-us/azure/storage/common/storage-security-guide)
- [GitHub Secrets Management](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Terraform State Management Best Practices](https://www.terraform.io/docs/language/state/index.html)

---

**Note**: This bootstrap process is a one-time setup. Once completed, all subsequent infrastructure deployments will use the established state management system through your CI/CD pipelines.
