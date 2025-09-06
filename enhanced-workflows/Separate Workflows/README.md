# Simplified Terraform CI/CD Templates

This directory contains the simplified Terraform CI/CD templates that eliminate complex environment detection and use direct parameter passing.

## Architecture Overview

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
├── environments/dev/
├── modules/
└── policies/

company-its-prod-tf/
├── .github/rulesets/
│   └── prod-ruleset.yml              # Triggers deploy via GitHub Ruleset
├── environments/prod/
├── modules/
└── policies/
```

## How It Works

### **1. Direct Parameter Passing**

The workflows use direct parameter passing instead of complex environment detection:

```bash
# CI Template Inputs
working_directory: "environments/dev"  # or "environments/prod"
terraform_version: "1.6.0"
enable_security_scan: true
enable_compliance_check: true
enable_cost_analysis: true

# Deploy Template Inputs
working_directory: "environments/dev"  # or "environments/prod"
terraform_version: "1.6.0"
environment: "dev"  # or "prod"
```

### **2. Workflow Flow**

#### **CI Flow:**
1. **Pull Request** created in `company-its-dev-tf`
2. **GitHub Ruleset** triggers workflow in `infra-ci-cd`
3. **terraform-ci-required.yml** runs in `infra-ci-cd`
4. **terraform-ci-required.yml** calls `infra-ci-templates/.github/workflows/terraform-ci-template.yml@main`
5. **terraform-ci-template.yml** runs with specified `working_directory`
6. **Terraform CI** executes in the specified directory

#### **Deploy Flow:**
1. **Push to main** in `company-its-prod-tf`
2. **terraform-deploy-required.yml** runs in `infra-ci-cd`
3. **terraform-deploy-required.yml** calls `infra-ci-templates/.github/workflows/terraform-deploy-template.yml@main`
4. **terraform-deploy-template.yml** runs with specified `working_directory` and `environment`
5. **Terraform Deploy** executes in the specified directory and environment

## Workflow Files

### **Template Workflows (in infra-ci-templates)**

#### **terraform-ci-template.yml**
- **Purpose**: CI template that can be called by any repository
- **Trigger**: `workflow_call` (called by other workflows)
- **Inputs**: `working_directory`, `terraform_version`, security/compliance flags
- **Features**: Format, validate, security scan, compliance check, cost analysis

#### **terraform-deploy-template.yml**
- **Purpose**: Deploy template that can be called by any repository
- **Trigger**: `workflow_call` (called by other workflows)
- **Inputs**: `working_directory`, `terraform_version`, `environment`
- **Features**: Terraform init, plan, apply, post-deployment tests

### **Caller Workflows (in infra-ci-cd)**

#### **terraform-ci-required.yml**
- **Purpose**: Calls the CI template from infra-ci-templates
- **Trigger**: Pull requests on Terraform files (via GitHub Ruleset)
- **Action**: Calls `infra-ci-templates/.github/workflows/terraform-ci-template.yml@main`
- **Parameters**: Passes `working_directory` and other inputs

#### **terraform-deploy-required.yml**
- **Purpose**: Calls the deploy template from infra-ci-templates
- **Trigger**: Push to main branch
- **Action**: Calls `infra-ci-templates/.github/workflows/terraform-deploy-template.yml@main`
- **Parameters**: Passes `working_directory`, `environment`, and other inputs

## Usage Examples

### **Manual Trigger via GitHub CLI**

```bash
# Trigger CI for development repository
gh workflow run terraform-ci-required.yml -f working_directory=environments/dev

# Trigger deploy for production repository
gh workflow run terraform-deploy-required.yml -f working_directory=environments/prod -f environment=prod
```

### **Manual Trigger via GitHub UI**

1. Go to `infra-ci-cd` repository
2. Navigate to Actions → Workflows
3. Select `terraform-ci-required` or `terraform-deploy-required`
4. Click "Run workflow"
5. Enter parameters:
   - `working_directory`: `environments/dev` or `environments/prod`
   - `environment`: `dev` or `prod` (for deploy only)
6. Click "Run workflow"

### **Automatic Trigger**

- **CI**: Automatically triggered on pull requests via GitHub Ruleset
- **Deploy**: Automatically triggered on push to main via GitHub Ruleset

## Benefits

### **1. Simplified Architecture**
- ❌ No complex environment detection jobs
- ❌ No job dependencies
- ✅ Direct parameter passing
- ✅ Single job per workflow

### **2. Better Performance**
- ✅ No separate detection job overhead
- ✅ Faster workflow execution
- ✅ Reduced complexity
- ✅ Easier to debug

### **3. Clear Parameter Control**
- ✅ Explicit `working_directory` parameter
- ✅ Explicit `environment` parameter
- ✅ No hidden detection logic
- ✅ Predictable behavior

### **4. Centralized Management**
- ✅ All caller workflows in `infra-ci-cd`
- ✅ All templates in `infra-ci-templates`
- ✅ Subscription repos only have rulesets
- ✅ Single source of truth

### **5. Easier Maintenance**
- ✅ Simpler workflow structure
- ✅ No complex outputs/inputs
- ✅ Direct parameter mapping
- ✅ Clear separation of concerns

## Configuration

### **Repository Structure**
```
alz-platform/                          # Central platform repository
├── .github/workflows/                 # Platform workflows
├── modules/                           # Reusable Terraform modules
├── environments/                      # Platform configurations
│   ├── management/                   # Management group hierarchy
│   ├── connectivity/                 # Hub-spoke networking
│   ├── identity/                     # Azure AD configurations
│   └── security/                     # Security policies and initiatives
└── docs/                             # Documentation

infra-ci-cd/                           # Centralized caller workflows
infra-ci-templates/                    # Centralized templates
company-its-dev-tf/                   # Development subscription
company-its-prod-tf/                  # Production subscription
company-bs-dev-tf/                    # Business unit dev
company-bs-prod-tf/                   # Business unit prod
company-dg-dev-tf/                    # Data governance dev
company-dg-prod-tf/                   # Data governance prod
```

### **State Management Architecture**

This implementation uses the **Manual Bootstrap + Pipeline Management** approach:

1. **Manual Bootstrap**: State infrastructure is created manually using the provided script
2. **Pipeline Management**: All infrastructure deployments use the established state system

#### **State Storage Structure**
```
rg-alz-state/                          # Central state resource group
├── stalzplatformstate                 # Platform state storage account
│   └── tfstate/
│       └── platform/terraform.tfstate # Single platform state
├── stalzitsdevstate                   # ITS Dev state storage account
│   └── tfstate/
│       └── its-dev/terraform.tfstate  # ITS Dev state
├── stalzitsprodstate                  # ITS Prod state storage account
│   └── tfstate/
│       └── its-prod/terraform.tfstate # ITS Prod state
├── stalzbsdevstate                    # BS Dev state storage account
│   └── tfstate/
│       └── bs-dev/terraform.tfstate   # BS Dev state
├── stalzbsprodstate                   # BS Prod state storage account
│   └── tfstate/
│       └── bs-prod/terraform.tfstate  # BS Prod state
├── stalzdgdevstate                    # DG Dev state storage account
│   └── tfstate/
│       └── dg-dev/terraform.tfstate   # DG Dev state
└── stalzdgprodstate                   # DG Prod state storage account
    └── tfstate/
        └── dg-prod/terraform.tfstate  # DG Prod state
```

### **Required Secrets (in infra-ci-cd)**
- `INFRACOST_API_KEY`: For cost analysis
- `AZURE_CREDENTIALS`: Azure service principal
- `TF_STATE_RG`: Terraform state resource group
- `TF_STATE_SA`: Terraform state storage account
- `TF_STATE_CONTAINER`: Terraform state container
- `TF_STATE_KEY`: Terraform state key
- `PRODUCTION_APPROVERS`: Production approvers list
- `SLACK_WEBHOOK_URL`: Slack notifications

### **Required Secrets (in infra-ci-templates)**
- `INFRACOST_API_KEY`: For cost analysis
- `AZURE_CREDENTIALS`: Azure service principal
- `TF_STATE_RG`: Terraform state resource group
- `TF_STATE_SA`: Terraform state storage account
- `TF_STATE_CONTAINER`: Terraform state container
- `TF_STATE_KEY`: Terraform state key
- `PRODUCTION_APPROVERS`: Production approvers list
- `SLACK_WEBHOOK_URL`: Slack notifications

### **Required Secrets (in subscription repositories)**
- `GITHUB_TOKEN`: For GitHub Ruleset (usually auto-provided)

## Migration from Old Approach

### **Step 1: Update infra-ci-templates Repository**
1. Replace `terraform-ci.yml` with `terraform-ci-template.yml`
2. Replace `terraform-deploy.yml` with `terraform-deploy-template.yml`
3. Configure secrets
4. Test with manual triggers

### **Step 2: Update infra-ci-cd Repository**
1. Add `terraform-ci-required.yml`
2. Add `terraform-deploy-required.yml`
3. Configure secrets
4. Test with manual triggers

### **Step 3: Update Subscription Repositories**
1. Remove old workflow files
2. Update GitHub Rulesets to point to `infra-ci-cd` workflows
3. Test with pull requests

### **Step 4: Cleanup**
1. Remove old orchestrator workflow
2. Remove redundant workflow files
3. Update documentation

## Troubleshooting

### **Working Directory Not Found**
```
❌ Working directory not found: environments/dev
```

**Solution**: Ensure the target repository has the correct directory structure and the `working_directory` parameter is set correctly.

### **Template Call Failed**
```
❌ Workflow call failed
```

**Solution**: Check that the template repository exists and the workflow file path is correct.

### **Environment Parameter Missing**
```
❌ Environment parameter is required for deploy
```

**Solution**: Ensure the `environment` parameter is passed to the deploy template.

### **GitHub Ruleset Not Triggering**
```
❌ GitHub Ruleset not triggering workflow
```

**Solution**: Check that the GitHub Ruleset is configured correctly and points to the right workflow in `infra-ci-cd`.

## State Management Best Practices

### **Enhanced State Management Features**

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

### **Bootstrap Process**

1. **Run Bootstrap Script**: Execute `bootstrap-state-infrastructure.sh` once to create state infrastructure
2. **Configure GitHub Secrets**: Set up state parameters in all repositories
3. **Test Workflows**: Verify all workflows function correctly
4. **Deploy Infrastructure**: Use pipelines to deploy your infrastructure

See [BOOTSTRAP_GUIDE.md](./BOOTSTRAP_GUIDE.md) for detailed bootstrap instructions.

## Best Practices

1. **Parameter Passing**: Always specify explicit parameters instead of relying on detection
2. **Directory Structure**: Maintain consistent directory structure across repositories
3. **Secrets Management**: Use environment-specific secrets in both `infra-ci-cd` and `infra-ci-templates`
4. **State Management**: Use manual bootstrap for state infrastructure, pipelines for infrastructure management
5. **Testing**: Test workflows with manual triggers first before enabling automatic triggers
6. **Monitoring**: Monitor workflow execution and failures in both repositories
7. **Documentation**: Keep this README updated with changes
8. **Centralization**: Keep all caller workflows in `infra-ci-cd` and all templates in `infra-ci-templates`
9. **Simplicity**: Prefer direct parameter passing over complex detection logic
10. **State Security**: Use Azure AD authentication and proper access controls for state management
