# Terraform CI/CD Templates with Variables (Best Practice)

This directory contains the **improved** Terraform CI/CD templates that use **GitHub Variables** instead of secrets for non-sensitive configuration, following best practices.

## 🔄 **Key Changes from Original**

### **✅ What Changed:**
- **TF_STATE_*** parameters moved from `secrets` to `vars`
- **Better debugging** - state config visible in logs
- **Easier management** - change values in GitHub UI
- **Industry best practice** - non-sensitive config as variables

### **✅ What Stayed the Same:**
- **AZURE_CREDENTIALS** remains as secret (sensitive)
- **All functionality** preserved
- **Same workflow logic** and features

## 🏗️ **Architecture Overview**

### **Repository Structure**
```
infra-ci-cd/                           # Centralized CI/CD caller workflows
├── .github/workflows/
│   ├── terraform-ci-required.yml     # Calls CI template
│   └── terraform-deploy-required.yml # Calls deploy template
└── scripts/

infra-ci-templates/                    # Centralized CI/CD templates
├── .github/workflows/
│   ├── terraform-ci-template.yml     # CI template logic
│   ├── terraform-deploy-template.yml # Deploy template logic
│   └── platform-*.yml                # Platform workflows
├── scripts/
└── configs/

# Subscription repositories (minimal)
company-its-dev-tf/
├── .github/rulesets/
│   └── dev-ruleset.yml               # Triggers CI via GitHub Ruleset
├── main.tf
├── variables.tf
├── terraform.tfvars
├── modules/
└── policies/

company-its-prod-tf/
├── .github/rulesets/
│   └── prod-ruleset.yml              # Triggers deploy via GitHub Ruleset
├── main.tf
├── variables.tf
├── terraform.tfvars
├── modules/
└── policies/
```

## 🔧 **Configuration Management**

### **GitHub Variables (Non-Sensitive)**
Set these in **Repository Settings → Secrets and Variables → Actions → Variables**:

#### **Dev Repositories:**
```
ENVIRONMENT = dev
TF_STATE_RG = rg-alz-state
TF_STATE_SA = stalzitsdevstate
TF_STATE_CONTAINER = tfstate
TF_STATE_KEY = its-dev/terraform.tfstate
```

#### **Prod Repositories:**
```
ENVIRONMENT = prod
TF_STATE_RG = rg-alz-state
TF_STATE_SA = stalzitsprodstate
TF_STATE_CONTAINER = tfstate
TF_STATE_KEY = its-prod/terraform.tfstate
```

### **GitHub Secrets (Sensitive)**
Set these in **Repository Settings → Secrets and Variables → Actions → Secrets**:

```
AZURE_CREDENTIALS = {"clientId":"...","clientSecret":"...","subscriptionId":"...","tenantId":"..."}
PRODUCTION_APPROVERS = senior-devops,platform-lead
SLACK_WEBHOOK_URL = https://hooks.slack.com/services/...
INFRACOST_API_KEY = your-infracost-api-key
```

## 🚀 **Workflow Usage**

### **Deploy Workflow**
```yaml
# Uses variables for state configuration
jobs:
  terraform:
    uses: infra-ci-templates/.github/workflows/terraform-deploy-template.yml@main
    with:
      working_directory: ${{ inputs.working_directory || '.' }}
      terraform_version: '1.6.0'
      environment: ${{ vars.ENVIRONMENT }}  # ✅ Uses variable
    secrets:
      AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}  # ✅ Keeps as secret
```

### **CI Workflow**
```yaml
# Uses variables for state configuration
jobs:
  terraform:
    uses: infra-ci-templates/.github/workflows/terraform-ci-template.yml@main
    with:
      working_directory: ${{ inputs.working_directory || '.' }}
      terraform_version: '1.6.0'
      enable_security_scan: true
      enable_compliance_check: true
      enable_cost_analysis: true
    secrets:
      AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}  # ✅ Keeps as secret
      INFRACOST_API_KEY: ${{ secrets.INFRACOST_API_KEY }}  # ✅ Keeps as secret
```

## 🎯 **Benefits of Using Variables**

### **1. Better Debugging**
```yaml
# ✅ VISIBLE: Can see state config in workflow logs
echo "State config: ${{ vars.TF_STATE_SA }}"
# Output: State config: stalzitsdevstate
```

```yaml
# ❌ HIDDEN: Secrets are masked in logs
echo "State config: ${{ secrets.TF_STATE_SA }}"
# Output: State config: ***
```

### **2. Easier Management**
- ✅ **Change in GitHub UI** - no code changes needed
- ✅ **Visible values** - easy to verify configuration
- ✅ **No deployment** required for config changes

### **3. Industry Best Practice**
- ✅ **Non-sensitive config** as variables
- ✅ **Sensitive data** as secrets
- ✅ **Clear separation** of concerns

### **4. Better Security**
- ✅ **Only sensitive data** is encrypted
- ✅ **Non-sensitive config** is visible for debugging
- ✅ **Proper access controls** maintained

## 📋 **Migration Guide**

### **From Secrets to Variables:**

#### **Step 1: Update Repository Variables**
1. Go to **Repository Settings → Secrets and Variables → Actions**
2. **Add Variables** (not secrets):
   - `ENVIRONMENT`
   - `TF_STATE_RG`
   - `TF_STATE_SA`
   - `TF_STATE_CONTAINER`
   - `TF_STATE_KEY`

#### **Step 2: Update Workflows**
1. **Replace** `${{ secrets.TF_STATE_* }}` with `${{ vars.TF_STATE_* }}`
2. **Keep** `${{ secrets.AZURE_CREDENTIALS }}` as secret
3. **Test** workflows with new configuration

#### **Step 3: Remove Old Secrets**
1. **Delete** old TF_STATE_* secrets (after testing)
2. **Keep** AZURE_CREDENTIALS and other sensitive secrets

## 🔍 **Template Changes**

### **terraform-deploy-template.yml**
```yaml
# ✅ CHANGED: Uses variables for state config
- name: Terraform Init with State Locking
  run: |
    terraform init \
      -backend-config="resource_group_name=${{ vars.TF_STATE_RG }}" \
      -backend-config="storage_account_name=${{ vars.TF_STATE_SA }}" \
      -backend-config="container_name=${{ vars.TF_STATE_CONTAINER }}" \
      -backend-config="key=${{ vars.TF_STATE_KEY }}"
```

### **terraform-ci-template.yml**
```yaml
# ✅ CHANGED: Uses variables for state config
- name: Terraform Init with Backend (for State Validation)
  run: |
    terraform init \
      -backend-config="resource_group_name=${{ vars.TF_STATE_RG }}" \
      -backend-config="storage_account_name=${{ vars.TF_STATE_SA }}" \
      -backend-config="container_name=${{ vars.TF_STATE_CONTAINER }}" \
      -backend-config="key=${{ vars.TF_STATE_KEY }}"
```

## 🎉 **Summary**

This improved version follows **industry best practices** by:

1. **Using variables** for non-sensitive configuration
2. **Keeping secrets** for sensitive data only
3. **Improving debugging** capabilities
4. **Simplifying management** of configuration
5. **Following security** best practices

**Use this version** for better maintainability and debugging! 🎯
