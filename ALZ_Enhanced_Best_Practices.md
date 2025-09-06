# Azure Landing Zone - Enhanced Best Practices Analysis

## Executive Summary

Your updated setup introduces excellent practices with Azure Verified Modules, shared workflows, and GitHub Rulesets. This analysis provides comprehensive recommendations to optimize your implementation for enterprise-scale Azure Landing Zone management.

## Current Setup Analysis

### Repository Structure
- **Central ALZ Repository**: Platform-level infrastructure
- **Subscription-Specific Repos**: 6 environment repos with `-tf` suffix (ITS-DEV-tf, ITS-PROD-tf, BS-DEV-tf, BS-PROD-tf, DG-DEV-tf, DG-PROD-tf)
- **Shared Workflow Repository**: `Infrastructure/infra-ci-templates` for centralized CI/CD

### Platform Design
- Centralized platform with management, connectivity, security, identity, and corporate application landing zones
- Multi-subscription architecture following Microsoft's ALZ pattern
- Azure Verified Modules as building blocks

### CI/CD Implementation
- **GitHub Ruleset**: Enforces `terraform-ci-required` workflow for all `-tf` repositories
- **Shared Workflow**: Centralized CI/CD logic in `infra-ci-templates`
- **Caller Workflow**: Simple workflow that calls shared implementation

## 1. Repository Structure Recommendations

### Enhanced Multi-Repo Architecture (Recommended)

```
alz-platform/                           # Central platform repository
├── .github/
│   ├── workflows/
│   │   ├── platform-ci.yml
│   │   ├── platform-deploy.yml
│   │   └── cross-subscription-validation.yml
│   └── rulesets/
│       └── platform-ruleset.yml
├── modules/                            # Platform-specific modules
│   ├── management-groups/
│   ├── connectivity/
│   ├── identity/
│   └── security/
├── environments/
│   ├── management/
│   ├── connectivity/
│   └── security/
└── docs/

infra-ci-cd/                           # Centralized CI/CD repository
├── .github/workflows/
│   ├── terraform-ci.yml               # Shared Terraform CI workflow
│   ├── terraform-deploy.yml           # Shared deployment workflow
│   ├── platform-ci.yml                # Platform CI workflow
│   ├── platform-deploy.yml            # Platform deployment workflow
│   ├── security-scan.yml              # Security scanning workflow
│   ├── compliance-check.yml           # Compliance validation workflow
│   └── subscription-orchestrator.yml  # Orchestrates subscription workflows
├── scripts/
│   ├── terraform-setup.sh
│   ├── security-scan.sh
│   ├── compliance-validate.sh
│   └── validate-azure-modules.sh
├── configs/
│   ├── its-dev-config.yml
│   ├── its-prod-config.yml
│   ├── bs-dev-config.yml
│   ├── bs-prod-config.yml
│   ├── dg-dev-config.yml
│   └── dg-prod-config.yml
└── templates/
    ├── dev-ruleset-template.yml
    └── prod-ruleset-template.yml

company-its-dev-tf/                   # ITS Development subscription
├── .github/
│   └── rulesets/
│       └── dev-ruleset.yml           # Development-specific rules
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── modules/                           # Subscription-specific modules
├── policies/                          # Subscription-level policies
└── workloads/                         # Workload-specific configurations

company-its-prod-tf/                  # ITS Production subscription
├── .github/
│   └── rulesets/
│       └── prod-ruleset.yml          # Production-specific rules
├── environments/
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── modules/                           # Subscription-specific modules
├── policies/                          # Subscription-level policies
└── workloads/                         # Workload-specific configurations

# Similar structure for:
# company-bs-dev-tf, company-bs-prod-tf, company-dg-dev-tf, company-dg-prod-tf
```

### Repository Naming Convention
```
{organization}-{business-unit}-{environment}-tf
Examples:
- company-its-dev-tf
- company-its-prod-tf
- company-bs-dev-tf
- company-bs-prod-tf
- company-dg-dev-tf
- company-dg-prod-tf
```

## 2. Azure Verified Modules Best Practices

### Module Usage Strategy

#### 1. Centralized Module Registry
```hcl
# terraform.tf - Module source configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Use Azure Verified Modules
module "virtual_network" {
  source  = "Azure/vnet/azurerm"
  version = "~> 4.0"
  
  vnet_name           = local.vnet_name
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.address_space
  subnet_prefixes     = var.subnet_prefixes
  subnet_names        = var.subnet_names
  
  tags = local.common_tags
}

module "key_vault" {
  source  = "Azure/keyvault/azurerm"
  version = "~> 2.0"
  
  key_vault_name = local.key_vault_name
  location       = var.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = local.common_tags
}
```

#### 2. Module Version Management
```hcl
# versions.tf - Centralized version management
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Module version constraints
locals {
  module_versions = {
    vnet        = "~> 4.0"
    key_vault   = "~> 2.0"
    storage     = "~> 1.0"
    monitoring  = "~> 3.0"
    security    = "~> 2.0"
  }
}
```

#### 3. Module Validation Workflow
```yaml
# .github/workflows/module-validation.yml
name: Module Validation
on:
  pull_request:
    paths:
      - '**/*.tf'
      - '**/versions.tf'

jobs:
  module-validation:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Validate Azure Verified Modules
        run: |
          # Check for approved module sources
          grep -r "source.*Azure/" . --include="*.tf" | \
          grep -v "Azure/vnet\|Azure/keyvault\|Azure/storage\|Azure/monitoring" && \
          echo "❌ Unapproved Azure Verified Module detected" && exit 1
          
          echo "✅ All modules are approved Azure Verified Modules"
      
      - name: Check Module Versions
        run: |
          # Ensure all modules use version constraints
          grep -r "source.*Azure/" . --include="*.tf" | \
          grep -v "version.*=" && \
          echo "❌ Module version constraint missing" && exit 1
          
          echo "✅ All modules have version constraints"
```

### Module Governance

#### 1. Approved Module List
```yaml
# .github/approved-modules.yml
approved_modules:
  networking:
    - Azure/vnet/azurerm
    - Azure/network-security-group/azurerm
    - Azure/application-gateway/azurerm
  
  security:
    - Azure/keyvault/azurerm
    - Azure/security-center/azurerm
    - Azure/policy/azurerm
  
  storage:
    - Azure/storage/azurerm
    - Azure/storage-account/azurerm
  
  monitoring:
    - Azure/monitoring/azurerm
    - Azure/log-analytics/azurerm
    - Azure/application-insights/azurerm
  
  compute:
    - Azure/vm/azurerm
    - Azure/aks/azurerm
    - Azure/container-instances/azurerm
```

#### 2. Module Update Policy
```yaml
# .github/module-update-policy.yml
update_policy:
  major_versions:
    approval_required: true
    approvers: ["platform-team", "security-team"]
  
  minor_versions:
    approval_required: false
    auto_update: true
  
  patch_versions:
    approval_required: false
    auto_update: true
```

## 3. Centralized CI/CD Repository Approach

### Benefits of Centralized Approach

1. **Single Source of Truth**: All CI/CD logic in one place
2. **Easy Maintenance**: Update workflows once, affects all repositories
3. **Consistency**: Same workflow behavior across all subscriptions
4. **Reduced Duplication**: No repeated workflow files
5. **Better Governance**: Centralized control over CI/CD processes
6. **Easier Testing**: Test workflow changes in one place
7. **Simplified Onboarding**: New repositories just need rulesets

### Repository Structure

```
infra-ci-cd/                           # Centralized CI/CD management
├── .github/workflows/
│   ├── terraform-ci.yml               # Shared CI workflow
│   ├── terraform-deploy.yml           # Shared deployment workflow
│   ├── platform-ci.yml                # Platform CI workflow
│   ├── platform-deploy.yml            # Platform deployment workflow
│   └── subscription-orchestrator.yml  # Orchestrates subscription workflows
├── scripts/
├── configs/
└── templates/

# Subscription repositories (minimal)
company-its-dev-tf/
├── .github/rulesets/dev-ruleset.yml   # Only rulesets, no workflows
├── environments/dev/
├── modules/
└── policies/

company-its-prod-tf/
├── .github/rulesets/prod-ruleset.yml  # Only rulesets, no workflows
├── environments/prod/
├── modules/
└── policies/
```

## 4. Enhanced Shared Workflow Implementation

### Centralized Shared Workflow
```yaml
# infra-ci-cd/.github/workflows/terraform-ci.yml
name: Terraform CI
on:
  workflow_call:
    inputs:
      repository:
        required: true
        type: string
      working_directory:
        required: false
        type: string
        default: '.'
      terraform_version:
        required: false
        type: string
        default: '1.6.0'
      enable_cost_analysis:
        required: false
        type: boolean
        default: true
      enable_security_scan:
        required: false
        type: boolean
        default: true
      enable_compliance_check:
        required: false
        type: boolean
        default: true
    secrets:
      INFRACOST_API_KEY:
        required: false
      AZURE_CREDENTIALS:
        required: true

env:
  TF_VERSION: ${{ inputs.terraform_version }}
  TF_LOG: INFO
  WORKING_DIR: ${{ inputs.working_directory }}

jobs:
  terraform-ci:
    name: 'Terraform CI'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
      pull-requests: write
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
          terraform_wrapper: false
      
      - name: Change to working directory
        run: |
          if [ "${{ env.WORKING_DIR }}" != "." ]; then
            cd "${{ env.WORKING_DIR }}"
            echo "WORKING_DIR=${{ env.WORKING_DIR }}" >> $GITHUB_ENV
          fi
      
      - name: Validate Azure Verified Modules
        run: |
          ./scripts/validate-azure-modules.sh
      
      - name: Terraform Format Check
        id: fmt
        run: |
          terraform fmt -check -recursive -diff
          echo "format_check_passed=$?" >> $GITHUB_OUTPUT
        continue-on-error: true
      
      - name: Terraform Init
        id: init
        run: |
          terraform init -backend=false
          echo "init_exit_code=$?" >> $GITHUB_OUTPUT
        continue-on-error: true
      
      - name: Terraform Validate
        id: validate
        run: |
          terraform validate
          echo "validate_exit_code=$?" >> $GITHUB_OUTPUT
        continue-on-error: true
      
      - name: Run Security Scan
        if: inputs.enable_security_scan
        run: |
          ./scripts/security-scan.sh
        continue-on-error: true
      
      - name: Run Compliance Check
        if: inputs.enable_compliance_check
        run: |
          ./scripts/compliance-check.sh
        continue-on-error: true
      
      - name: Run Cost Analysis
        if: inputs.enable_cost_analysis && secrets.INFRACOST_API_KEY
        run: |
          ./scripts/cost-analysis.sh
        continue-on-error: true
      
      - name: Run Terraform Plan
        id: plan
        run: |
          terraform plan -no-color -out=tfplan
          echo "plan_exit_code=$?" >> $GITHUB_OUTPUT
        continue-on-error: true
      
      - name: Generate PR Comment
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const output = `#### Terraform CI Results 🚀
            
            | Check | Status |
            |-------|--------|
            | Format | ${{ steps.fmt.outputs.format_check_passed == '0' ? '✅' : '❌' }} |
            | Init | ${{ steps.init.outputs.init_exit_code == '0' ? '✅' : '❌' }} |
            | Validate | ${{ steps.validate.outputs.validate_exit_code == '0' ? '✅' : '❌' }} |
            | Plan | ${{ steps.plan.outputs.plan_exit_code == '0' ? '✅' : '❌' }} |
            
            <details><summary>Show Plan</summary>
            
            \`\`\`terraform
            ${{ steps.plan.outputs.stdout }}
            \`\`\`
            
            </details>`;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })
        continue-on-error: true
      
      - name: Fail if critical steps failed
        if: |
          steps.fmt.outputs.format_check_passed != '0' ||
          steps.init.outputs.init_exit_code != '0' ||
          steps.validate.outputs.validate_exit_code != '0'
        run: |
          echo "❌ Critical Terraform CI steps failed"
          exit 1
```

### Centralized Orchestrator Workflow
```yaml
# infra-ci-cd/.github/workflows/subscription-orchestrator.yml
name: Subscription Orchestrator
on:
  repository_dispatch:
    types: [terraform-ci, terraform-deploy]
  workflow_dispatch:
    inputs:
      repository:
        description: 'Source repository'
        required: true
        type: string
      environment:
        description: 'Environment'
        required: true
        type: choice
        options:
          - dev
          - prod
      action:
        description: 'Action to perform'
        required: true
        type: choice
        options:
          - ci
          - deploy

jobs:
  terraform-ci:
    if: github.event.inputs.action == 'ci' || github.event_name == 'repository_dispatch'
    uses: ./.github/workflows/terraform-ci.yml
    with:
      repository: ${{ github.event.inputs.repository }}
      working_directory: "environments/${{ github.event.inputs.environment }}"
      terraform_version: '1.6.0'
      enable_cost_analysis: true
      enable_security_scan: true
      enable_compliance_check: true
    secrets:
      INFRACOST_API_KEY: ${{ secrets.INFRACOST_API_KEY }}
      AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}

  terraform-deploy:
    if: github.event.inputs.action == 'deploy' || github.event_name == 'repository_dispatch'
    uses: ./.github/workflows/terraform-deploy.yml
    with:
      repository: ${{ github.event.inputs.repository }}
      working_directory: "environments/${{ github.event.inputs.environment }}"
      terraform_version: '1.6.0'
    secrets:
      AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
      TF_STATE_RG: ${{ secrets.TF_STATE_RG }}
      TF_STATE_SA: ${{ secrets.TF_STATE_SA }}
      TF_STATE_CONTAINER: ${{ secrets.TF_STATE_CONTAINER }}
      TF_STATE_KEY: ${{ secrets.TF_STATE_KEY }}
```

## 5. GitHub Ruleset Configuration

### Environment-Specific Rulesets

#### Development Repository Rules
```yaml
# .github/rulesets/dev-ruleset.yml
name: "Development Repository Rules"
enforcement: "active"
target: "branch"
conditions:
  repository_name:
    - pattern: "*-dev-tf"
rules:
  - type: "pull_request"
    parameters:
      required_approving_review_count: 1  # Lower approval for dev
      dismiss_stale_reviews_on_push: true
      require_code_owner_review: false
      require_last_push_approval: true
      required_review_thread_resolution: true

#### Production Repository Rules
```yaml
# .github/rulesets/prod-ruleset.yml
name: "Production Repository Rules"
enforcement: "active"
target: "branch"
conditions:
  repository_name:
    - pattern: "*-prod-tf"
rules:
  - type: "pull_request"
    parameters:
      required_approving_review_count: 3  # Higher approval for prod
      dismiss_stale_reviews_on_push: true
      require_code_owner_review: true
      require_last_push_approval: true
      required_review_thread_resolution: true
  
  - type: "required_status_checks"
    parameters:
      required_status_checks:
        - context: "terraform-ci"
          integration_id: null
        - context: "security-scan"
          integration_id: null
        - context: "compliance-check"
          integration_id: null
      strict_required_status_checks_policy: true
  
  - type: "non_fast_forward"
  
  - type: "required_linear_history"
  
  - type: "required_deployments"
    parameters:
      required_deployment_environments:
        - "development"
        - "staging"
  
  - type: "required_signatures"
  
  - type: "pull_request"
    parameters:
      required_approving_review_count: 1
      dismiss_stale_reviews_on_push: true
      require_code_owner_review: false
      require_last_push_approval: true
      required_review_thread_resolution: true
    conditions:
      ref_name:
        - pattern: "feature/*"
        - pattern: "hotfix/*"
```

## 6. Terraform State Management Strategy

### Multi-Repository State Architecture
```hcl
# backend.tf - Environment-specific backend configuration
terraform {
  backend "azurerm" {
    # Backend configuration provided via command line
    # This allows for environment-specific state storage
  }
}

# State management configuration
locals {
  state_config = {
    platform = {
      resource_group_name  = "rg-alz-platform-state"
      storage_account_name = "stalzplatformstate"
      container_name       = "tfstate"
      key                  = "platform/terraform.tfstate"
    }
    its_dev = {
      resource_group_name  = "rg-alz-its-dev-state"
      storage_account_name = "stalzitsdevstate"
      container_name       = "tfstate"
      key                  = "its-dev/terraform.tfstate"
    }
    its_prod = {
      resource_group_name  = "rg-alz-its-prod-state"
      storage_account_name = "stalzitsprodstate"
      container_name       = "tfstate"
      key                  = "its-prod/terraform.tfstate"
    }
    # Similar configuration for other subscriptions
  }
}
```

### State Management Scripts
```bash
#!/bin/bash
# scripts/setup-state-backend.sh

set -e

ENVIRONMENT=${1:-dev}
SUBSCRIPTION=${2:-its}

# Set backend configuration
RESOURCE_GROUP="rg-alz-${SUBSCRIPTION}-${ENVIRONMENT}-state"
STORAGE_ACCOUNT="stalz${SUBSCRIPTION}${ENVIRONMENT}state"
CONTAINER="tfstate"
KEY="${SUBSCRIPTION}-${ENVIRONMENT}/terraform.tfstate"

# Initialize Terraform with backend
terraform init \
  -backend-config="resource_group_name=${RESOURCE_GROUP}" \
  -backend-config="storage_account_name=${STORAGE_ACCOUNT}" \
  -backend-config="container_name=${CONTAINER}" \
  -backend-config="key=${KEY}"

echo "✅ Terraform backend configured for ${SUBSCRIPTION}-${ENVIRONMENT}"
```

## 7. Secrets Management and RBAC Strategy

### Azure Key Vault Integration
```hcl
# key-vault.tf - Centralized secrets management
resource "azurerm_key_vault" "main" {
  name                = "kv-${local.name_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = false
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true
  purge_protection_enabled        = var.environment == "prod"
  
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.main.id]
  }
  
  tags = local.common_tags
}

# Key Vault Access Policies
resource "azurerm_key_vault_access_policy" "github_actions" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.github_actions_object_id
  
  key_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
  ]
  
  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
  ]
  
  certificate_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
  ]
}
```

### GitHub Secrets Management
```yaml
# .github/workflows/secrets-management.yml
name: Secrets Management
on:
  workflow_dispatch:
    inputs:
      action:
        description: 'Action to perform'
        required: true
        type: choice
        options:
          - sync
          - rotate
          - validate

jobs:
  secrets-management:
    runs-on: ubuntu-latest
    steps:
      - name: Sync secrets from Key Vault
        if: github.event.inputs.action == 'sync'
        run: |
          # Sync secrets from Azure Key Vault to GitHub
          az keyvault secret list --vault-name ${{ secrets.KEY_VAULT_NAME }} --query "[].name" -o tsv | \
          while read secret_name; do
            secret_value=$(az keyvault secret show --vault-name ${{ secrets.KEY_VAULT_NAME }} --name $secret_name --query "value" -o tsv)
            echo "::add-mask::$secret_value"
            # Update GitHub secret (requires GitHub CLI)
            gh secret set $secret_name --body "$secret_value"
          done
      
      - name: Rotate secrets
        if: github.event.inputs.action == 'rotate'
        run: |
          # Rotate secrets in Key Vault
          ./scripts/rotate-secrets.sh
      
      - name: Validate secrets
        if: github.event.inputs.action == 'validate'
        run: |
          # Validate all secrets are accessible
          ./scripts/validate-secrets.sh
```

## 8. Environment Promotion Strategy

### Promotion Pipeline
```yaml
# .github/workflows/promote-environment.yml
name: Promote Environment
on:
  workflow_dispatch:
    inputs:
      source_environment:
        description: 'Source environment'
        required: true
        type: choice
        options:
          - dev
          - staging
      target_environment:
        description: 'Target environment'
        required: true
        type: choice
        options:
          - staging
          - prod
      business_unit:
        description: 'Business unit'
        required: true
        type: choice
        options:
          - its
          - bs
          - dg

jobs:
  promote:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.target_environment }}
    
    steps:
      - name: Checkout source repository
        uses: actions/checkout@v4
        with:
          repository: ${{ github.repository_owner }}/alz-${{ github.event.inputs.business_unit }}-${{ github.event.inputs.source_environment }}-tf
          token: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Validate source environment
        run: |
          # Validate source environment is stable
          ./scripts/validate-environment.sh ${{ github.event.inputs.source_environment }}
      
      - name: Create promotion branch
        run: |
          git checkout -b promote-${{ github.event.inputs.source_environment }}-to-${{ github.event.inputs.target_environment }}
      
      - name: Update environment configuration
        run: |
          # Update environment-specific configurations
          ./scripts/update-environment-config.sh ${{ github.event.inputs.target_environment }}
      
      - name: Create pull request
        uses: actions/github-script@v7
        with:
          script: |
            const pr = await github.rest.pulls.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `Promote ${{ github.event.inputs.source_environment }} to ${{ github.event.inputs.target_environment }}`,
              head: 'promote-${{ github.event.inputs.source_environment }}-to-${{ github.event.inputs.target_environment }}',
              base: 'main',
              body: `## Environment Promotion
              
              **Source**: ${{ github.event.inputs.source_environment }}
              **Target**: ${{ github.event.inputs.target_environment }}
              **Business Unit**: ${{ github.event.inputs.business_unit }}
              
              ### Changes
              - Updated environment configuration
              - Promoted infrastructure changes
              
              ### Approval Required
              This promotion requires approval from:
              - Platform Team Lead
              - Security Team Lead
              - Business Unit Owner`
            });
            
            console.log(`Created PR #${pr.data.number}`);
```

## 9. Compliance and Security Enforcement

### Comprehensive Security Scanning
```yaml
# Infrastructure/infra-ci-templates/.github/workflows/security-scan.yml
name: Security Scan
on:
  workflow_call:
    inputs:
      working_directory:
        required: false
        type: string
        default: '.'
    secrets:
      AZURE_CREDENTIALS:
        required: true

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: '1.6.0'
      
      - name: Configure Azure CLI
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Run TFSec
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          working_directory: ${{ inputs.working_directory }}
          soft_fail: true
          format: sarif
          output_file_path: tfsec-results.sarif
      
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: ${{ inputs.working_directory }}
          framework: terraform
          soft_fail: true
          output_format: sarif
          output_file_path: checkov-results.sarif
      
      - name: Run Trivy
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'config'
          scan-ref: ${{ inputs.working_directory }}
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload security results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: |
            tfsec-results.sarif
            checkov-results.sarif
            trivy-results.sarif
```

### Compliance Validation
```yaml
# Infrastructure/infra-ci-templates/.github/workflows/compliance-check.yml
name: Compliance Check
on:
  workflow_call:
    inputs:
      working_directory:
        required: false
        type: string
        default: '.'
      compliance_standards:
        required: false
        type: string
        default: 'CIS,NIST,SOC2'

jobs:
  compliance-check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: '1.6.0'
      
      - name: Run Compliance Check
        run: |
          # Check for compliance violations
          ./scripts/compliance-check.sh ${{ inputs.working_directory }} ${{ inputs.compliance_standards }}
      
      - name: Generate Compliance Report
        run: |
          ./scripts/generate-compliance-report.sh
      
      - name: Upload Compliance Report
        uses: actions/upload-artifact@v3
        with:
          name: compliance-report
          path: compliance-report.html
```

## 10. Repository Consolidation Analysis

### Multi-Repo Approach (Current - Recommended)

#### Advantages
- **Security Isolation**: Better separation between environments
- **Independent Deployments**: Each subscription can deploy independently
- **Granular Access Control**: Fine-grained permissions per repository
- **Reduced Blast Radius**: Changes affect only specific environments
- **Compliance**: Easier to meet regulatory requirements
- **Team Autonomy**: Different teams can own different repositories
- **Scalability**: Easy to add new subscriptions or business units

#### Disadvantages
- **Code Duplication**: Similar code across repositories
- **Synchronization**: Keeping modules in sync across repos
- **Management Complexity**: More repositories to manage

### Monorepo Approach (Alternative)

#### Advantages
- **Code Reuse**: Shared modules and configurations
- **Atomic Changes**: Cross-subscription changes in single commit
- **Simplified Management**: Single repository to maintain
- **Consistency**: Easier to maintain consistency across environments

#### Disadvantages
- **Security Risk**: Broader access to all environments
- **Deployment Complexity**: More complex deployment orchestration
- **Access Control**: Harder to implement fine-grained permissions
- **Blast Radius**: Changes can affect multiple environments

### Recommendation: Keep Multi-Repo Approach

**Rationale**:
1. **Security**: Better isolation between production and development
2. **Compliance**: Easier to meet regulatory requirements
3. **Team Structure**: Aligns with typical organizational structure
4. **Risk Management**: Reduces impact of changes
5. **Scalability**: Easier to scale as organization grows
6. **Azure Verified Modules**: Better suited for multi-repo approach

### Hybrid Approach (Best of Both Worlds)
- **Central Platform Repository**: Shared modules and policies
- **Subscription Repositories**: Environment-specific configurations
- **Shared CI/CD Templates**: Centralized workflow logic
- **Module Registry**: Private Terraform module registry for shared modules
- **Cross-Repository Dependencies**: Use Git submodules or module registry

## 11. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- [ ] Set up enhanced repository structure
- [ ] Implement shared workflow templates
- [ ] Configure GitHub Rulesets
- [ ] Set up Azure Verified Modules usage

### Phase 2: CI/CD Pipeline (Weeks 3-4)
- [ ] Implement comprehensive CI workflows
- [ ] Set up automated testing and validation
- [ ] Configure deployment workflows
- [ ] Implement drift detection

### Phase 3: Security & Compliance (Weeks 5-6)
- [ ] Implement comprehensive security scanning
- [ ] Set up compliance validation
- [ ] Configure Azure Key Vault integration
- [ ] Implement RBAC and access controls

### Phase 4: Optimization (Weeks 7-8)
- [ ] Implement cost optimization
- [ ] Set up monitoring and alerting
- [ ] Document procedures
- [ ] Train team members

## 12. Monitoring and Observability

### Infrastructure Monitoring
```hcl
# monitoring.tf - Comprehensive monitoring setup
resource "azurerm_monitor_action_group" "alz_alerts" {
  name                = "ag-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "alz-alerts"
  
  email_receiver {
    name          = "devops-team"
    email_address = "devops@company.com"
  }
  
  webhook_receiver {
    name        = "slack-webhook"
    service_uri = var.slack_webhook_url
  }
}

# Cost monitoring
resource "azurerm_consumption_budget_resource_group" "main" {
  name              = "budget-${local.name_prefix}"
  resource_group_id = azurerm_resource_group.main.id
  
  amount     = var.budget_amount
  time_grain = "Monthly"
  
  time_period {
    start_date = "2024-01-01T00:00:00Z"
  }
  
  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    
    contact_emails = ["devops@company.com"]
  }
}
```

## Conclusion

Your updated setup with Azure Verified Modules, shared workflows, and GitHub Rulesets is excellent and follows enterprise best practices. The recommendations above will help you:

1. **Optimize Azure Verified Modules Usage**: Centralized governance and validation
2. **Enhance Shared Workflows**: More comprehensive CI/CD with better error handling
3. **Improve Security**: Comprehensive scanning and compliance validation
4. **Streamline State Management**: Environment-specific state with proper isolation
5. **Ensure Compliance**: Automated compliance checking and reporting
6. **Scale Effectively**: Structured approach that grows with your organization

The key is to implement these recommendations incrementally, starting with the foundation and building up to more advanced features. This approach will minimize risk while providing immediate value.
