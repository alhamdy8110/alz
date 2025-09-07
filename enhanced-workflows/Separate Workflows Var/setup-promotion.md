# Cross-Repository Promotion Setup Guide

This guide explains how to set up automated code promotion from development to production repositories in your ALZ setup.

## 🎯 **Overview**

The promotion system automatically promotes code from `company-its-dev-tf` to `company-its-prod-tf` after successful deployment, ensuring safe and traceable production deployments.

## 🏗️ **Architecture**

```
Dev Repository (company-its-dev-tf)
    ↓ (Successful Deployment)
Promotion Workflow
    ↓ (Code Sync + Environment Updates)
Prod Repository (company-its-prod-tf)
    ↓ (Triggered by Push)
Production Deployment Workflow
    ↓ (With Approval Gates)
Production Infrastructure
```

## 📋 **Setup Steps**

### **Step 1: Create Personal Access Token**

1. **Go to GitHub Settings**
   - Navigate to Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Create New Token**
   - Click "Generate new token (classic)"
   - Name: `ALZ-Promotion-Token`
   - Expiration: `90 days` (recommended)
   - Scopes:
     - ✅ `repo` (Full control of private repositories)
     - ✅ `workflow` (Update GitHub Action workflows)

3. **Copy Token**
   - Save the token securely (you won't see it again)

### **Step 2: Configure Dev Repository**

#### **Add Repository Variables:**
```
PROD_REPOSITORY = your-org/company-its-prod-tf
```

#### **Add Repository Secrets:**
```
PROMOTION_TOKEN = <your-personal-access-token>
```

#### **Add Promotion Workflow:**
- Copy `promote-to-prod.yml` to `.github/workflows/`
- The workflow will trigger automatically after successful dev deployments

### **Step 3: Configure Production Repository**

#### **Add Repository Variables:**
```
ENVIRONMENT = prod
TF_STATE_RG = rg-alz-state
TF_STATE_SA = stalzitsprodstate
TF_STATE_CONTAINER = tfstate
TF_STATE_KEY = its-prod/terraform.tfstate
```

#### **Add Repository Secrets:**
```
AZURE_CREDENTIALS = <your-azure-service-principal-json>
PRODUCTION_APPROVERS = senior-devops,platform-lead
SLACK_WEBHOOK_URL = <your-slack-webhook-url>
INFRACOST_API_KEY = <your-infracost-api-key>
```

#### **Add Production Deployment Workflow:**
- Copy `production-deploy.yml` to `.github/workflows/`
- This workflow handles production deployments with approval gates

### **Step 4: Set Up GitHub Environments**

#### **In Dev Repository:**
Create environment: `promotion`
- No protection rules needed
- Used for promotion workflow

#### **In Prod Repository:**
Create environments:

**`production-approval`:**
- Required reviewers: `senior-devops`, `platform-lead`
- Wait timer: `5 minutes`
- Prevent self-review: `true`

**`production`:**
- Required reviewers: `senior-devops`, `platform-lead`
- Wait timer: `10 minutes`
- Prevent self-review: `true`

### **Step 5: Configure Branch Protection**

#### **In Production Repository:**
```
Branch: main
Protection Rules:
  ✅ Require a pull request before merging
  ✅ Require status checks to pass before merging
  ✅ Require branches to be up to date before merging
  ✅ Restrict pushes that create files
  ✅ Require linear history
  ✅ Include administrators
  ✅ Allow force pushes: Never
  ✅ Allow deletions: Never

Required Status Checks:
  ✅ terraform-ci-required
  ✅ security-scan
  ✅ production-deploy
```

## 🔄 **How It Works**

### **1. Development Flow**
```
1. Developer pushes to company-its-dev-tf/main
   ↓
2. terraform-deploy-required workflow runs
   ↓
3. Dev infrastructure deployed successfully
   ↓
4. promote-to-prod workflow triggers automatically
```

### **2. Promotion Flow**
```
1. Promotion workflow checks out dev repository
   ↓
2. Gets latest commit information
   ↓
3. Checks out production repository
   ↓
4. Syncs Terraform files from dev to prod
   ↓
5. Updates environment-specific configuration
   ↓
6. Creates promotion commit with detailed message
   ↓
7. Pushes to production repository
   ↓
8. Creates deployment issue for tracking
```

### **3. Production Deployment Flow**
```
1. Push to company-its-prod-tf/main triggers production-deploy
   ↓
2. Pre-deployment checks validate configuration
   ↓
3. Manual approval required (if not promotion commit)
   ↓
4. Terraform deployment with production environment
   ↓
5. Post-deployment tests and notifications
```

## 🔧 **Configuration Examples**

### **Dev Repository (company-its-dev-tf)**

#### **terraform.tfvars:**
```hcl
environment = "dev"
name_prefix = "dev"
budget_amount = 500
log_retention_days = 7
enable_ddos_protection = false
```

#### **Variables:**
```
PROD_REPOSITORY = your-org/company-its-prod-tf
```

#### **Secrets:**
```
PROMOTION_TOKEN = ghp_xxxxxxxxxxxxxxxxxxxx
```

### **Production Repository (company-its-prod-tf)**

#### **terraform.tfvars (after promotion):**
```hcl
environment = "prod"
name_prefix = "prod"
budget_amount = 5000
log_retention_days = 90
enable_ddos_protection = true
```

#### **Variables:**
```
ENVIRONMENT = prod
TF_STATE_RG = rg-alz-state
TF_STATE_SA = stalzitsprodstate
TF_STATE_CONTAINER = tfstate
TF_STATE_KEY = its-prod/terraform.tfstate
```

## 🎯 **Promotion Commit Message**

The promotion workflow creates detailed commit messages:

```
🚀 Promote from dev to production

Source: your-org/company-its-dev-tf@abc123def456
Original commit: Add new networking module
Author: john.doe
Date: 2024-01-15 10:30:00 +0000
Promoted by: devops-bot
Promotion date: 2024-01-15 10:35:00 UTC

Changes:
- Updated Terraform configuration for production
- Adjusted environment-specific variables
- Enabled production security features
- Updated resource naming conventions
```

## 🔒 **Security Features**

### **1. Token Security**
- Fine-grained personal access token
- Limited to required repositories
- Regular rotation (90 days)

### **2. Approval Gates**
- Manual approval for non-promotion commits
- Required reviewers for production
- Wait timers to prevent rushed deployments

### **3. Audit Trail**
- Detailed commit messages
- GitHub issues for tracking
- Complete deployment history

### **4. Environment Isolation**
- Separate repositories for dev/prod
- Environment-specific configurations
- Isolated state management

## 🚨 **Troubleshooting**

### **Common Issues:**

#### **1. Promotion Token Permissions**
```
Error: Resource not accessible by integration
```
**Solution:** Ensure token has `repo` and `workflow` scopes

#### **2. Repository Not Found**
```
Error: Repository not found
```
**Solution:** Check `PROD_REPOSITORY` variable format: `owner/repo-name`

#### **3. Environment Variables Missing**
```
Error: Environment variable not found
```
**Solution:** Verify all required variables are set in repository settings

#### **4. Approval Gates Not Working**
```
Error: Environment protection rules not applied
```
**Solution:** Check environment configuration and required reviewers

## 📊 **Monitoring and Notifications**

### **1. GitHub Issues**
- Automatic issue creation for each promotion
- Pre-deployment checklist
- Deployment tracking

### **2. Slack Notifications**
- Promotion success/failure
- Deployment status updates
- Approval requests

### **3. Audit Logs**
- Complete promotion history
- Deployment tracking
- Change attribution

## 🎉 **Benefits**

### **✅ Automated Promotion**
- No manual code copying
- Consistent environment updates
- Reduced human error

### **✅ Safety and Compliance**
- Approval gates for production
- Audit trail for all changes
- Environment isolation

### **✅ Traceability**
- Detailed commit messages
- Source tracking
- Change attribution

### **✅ Flexibility**
- Manual override capabilities
- Emergency deployment options
- Rollback procedures

## 📋 **Best Practices**

1. **Test Promotion Flow** in staging environment first
2. **Monitor First Few Deployments** closely
3. **Keep Promotion Token Secure** and rotate regularly
4. **Review Promotion Commits** before production deployment
5. **Maintain Audit Trail** for compliance requirements
6. **Have Rollback Plan** ready for emergencies

This setup ensures **safe, automated, and traceable** code promotion from development to production! 🎯
