# Azure Landing Zone - Best Practices Analysis & Recommendations

## Executive Summary

Your current setup follows a multi-repository approach with centralized platform management and environment-specific subscriptions. This analysis provides comprehensive recommendations for optimizing your Azure Landing Zone implementation.

## Current Setup Analysis

### Repository Structure
- **Central ALZ Repository**: Platform-level infrastructure
- **Subscription-Specific Repos**: 6 environment repos (ITS-DEV, ITS-PROD, BS-DEV, BS-PROD, DG-DEV, DG-PROD)
- **Additional**: Sandbox subscription

### Platform Design
- Centralized platform with management, connectivity, security, identity, and corporate application landing zones
- Multi-subscription architecture following Microsoft's ALZ pattern

## 1. Repository Structure Recommendations

### Option A: Current Multi-Repo Approach (Recommended)
```
alz-platform/                    # Central platform repository
├── .github/
│   └── workflows/
├── modules/                     # Reusable Terraform modules
├── environments/
│   ├── management/             # Management group hierarchy
│   ├── connectivity/           # Hub-spoke networking
│   ├── identity/               # Azure AD configurations
│   └── security/               # Security policies and initiatives
└── docs/

alz-its-dev/                    # ITS Development subscription
├── .github/workflows/
├── environments/
│   ├── dev/
│   └── shared/
├── modules/                    # Subscription-specific modules
└── policies/                   # Subscription-level policies

alz-its-prod/                   # ITS Production subscription
├── .github/workflows/
├── environments/
│   ├── prod/
│   └── shared/
├── modules/
└── policies/

# Similar structure for BS-DEV, BS-PROD, DG-DEV, DG-PROD
```

### Option B: Monorepo Approach (Alternative)
```
alz-monorepo/
├── .github/workflows/
├── platform/                   # Central platform code
├── subscriptions/
│   ├── its-dev/
│   ├── its-prod/
│   ├── bs-dev/
│   ├── bs-prod/
│   ├── dg-dev/
│   └── dg-prod/
├── modules/                    # Shared modules
└── docs/
```

**Recommendation**: Stick with **Option A (Multi-Repo)** for the following reasons:
- Better security isolation between environments
- Independent deployment cycles
- Easier access control and RBAC
- Reduced blast radius for changes
- Better compliance with separation of duties

## 2. GitHub Actions Workflows Design

### Central Platform Repository Workflows

#### `.github/workflows/terraform-ci.yml`
```yaml
name: Terraform CI
on:
  pull_request:
    branches: [main]
    paths:
      - '**/*.tf'
      - '**/*.tfvars'
      - '.github/workflows/terraform-ci.yml'

jobs:
  terraform-ci:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ~1.6.0
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
      
      - name: Terraform Init
        run: terraform init -backend=false
      
      - name: Terraform Validate
        run: terraform validate
      
      - name: Run TFSec
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          working_directory: .
      
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          framework: terraform
      
      - name: Run Infracost
        uses: infracost/infracost-gh-action@v0.12
        with:
          api_key: ${{ secrets.INFRACOST_API_KEY }}
          path: .
```

#### `.github/workflows/terraform-deploy.yml`
```yaml
name: Terraform Deploy
on:
  push:
    branches: [main]
    paths:
      - '**/*.tf'
      - '**/*.tfvars'
      - '.github/workflows/terraform-deploy.yml'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.ref == 'refs/heads/main' && 'production' || 'development' }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ~1.6.0
      
      - name: Terraform Init
        run: terraform init
        env:
          ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
      
      - name: Terraform Apply
        run: terraform apply tfplan
        if: github.ref == 'refs/heads/main'
```

### Subscription-Specific Repository Workflows

Each subscription repo should have similar workflows but with environment-specific configurations:

#### `.github/workflows/terraform-deploy-subscription.yml`
```yaml
name: Deploy to Subscription
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - prod
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'production' }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ~1.6.0
      
      - name: Configure Azure CLI
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Terraform Init
        run: terraform init
        working-directory: environments/${{ github.event.inputs.environment || 'prod' }}
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: environments/${{ github.event.inputs.environment || 'prod' }}
      
      - name: Terraform Apply
        run: terraform apply tfplan
        working-directory: environments/${{ github.event.inputs.environment || 'prod' }}
```

## 3. Branching Strategy

### GitFlow-Based Strategy

#### Platform Repository
```
main                    # Production-ready platform code
├── develop            # Integration branch for platform changes
├── feature/*          # Feature branches for new platform capabilities
├── hotfix/*           # Critical fixes for production
└── release/*          # Release preparation branches
```

#### Subscription Repositories
```
main                    # Production environment code
├── develop            # Development environment code
├── feature/*          # Feature branches
├── hotfix/*           # Critical production fixes
└── release/*          # Release preparation
```

### Branch Protection Rules
- Require pull request reviews (minimum 2 reviewers for production)
- Require status checks to pass
- Require branches to be up to date
- Restrict pushes to main branch
- Require linear history

## 4. Terraform State Management

### State Backend Configuration

#### Platform Repository
```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-alz-platform-state"
    storage_account_name = "stalzplatformstate"
    container_name       = "tfstate"
    key                  = "platform/terraform.tfstate"
  }
}
```

#### Subscription Repositories
```hcl
# environments/dev/backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-alz-its-dev-state"
    storage_account_name = "stalzitsdevstate"
    container_name       = "tfstate"
    key                  = "its-dev/terraform.tfstate"
  }
}
```

### State Management Best Practices
- **Separate state files** for each environment and subscription
- **State locking** enabled with Azure Blob Storage
- **State encryption** at rest and in transit
- **Access control** using Azure RBAC
- **State backup** and versioning enabled
- **Remote state data sources** for cross-subscription references

## 5. Security & RBAC Recommendations

### GitHub Repository Security

#### Repository-Level Permissions
```yaml
# Repository settings
- Admin: Platform team leads only
- Maintain: Senior DevOps engineers
- Write: DevOps engineers
- Triage: Junior engineers
- Read: All team members
```

#### Branch Protection
- Require pull request reviews
- Require status checks
- Require up-to-date branches
- Restrict pushes to main
- Require linear history

### Azure Security

#### Service Principal Configuration
```bash
# Create service principal for each subscription
az ad sp create-for-rbac \
  --name "alz-its-dev-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/{subscription-id}" \
  --sdk-auth
```

#### Key Vault Integration
```hcl
# Store secrets in Azure Key Vault
data "azurerm_key_vault_secret" "database_password" {
  name         = "database-password"
  key_vault_id = azurerm_key_vault.main.id
}
```

### Secret Management
- **GitHub Secrets**: Store Azure credentials and API keys
- **Azure Key Vault**: Store application secrets and certificates
- **Environment-specific secrets**: Separate Key Vaults per environment
- **Rotation policies**: Implement automatic secret rotation

## 6. Environment Promotion Strategy

### Promotion Pipeline

#### Development → Production Flow
1. **Feature Development**: Create feature branch from develop
2. **Development Testing**: Deploy to DEV environment
3. **Code Review**: Create PR to develop branch
4. **Integration Testing**: Deploy to DEV environment after merge
5. **Release Preparation**: Create release branch from develop
6. **Production Deployment**: Merge release branch to main
7. **Production Deployment**: Automated deployment to PROD

#### Automated Promotion Workflow
```yaml
name: Promote to Production
on:
  push:
    branches: [release/*]

jobs:
  promote:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Deploy to Production
        run: |
          # Deploy platform changes first
          # Then deploy subscription changes
          # Validate deployment
          # Run compliance checks
```

### Change Management
- **Change Advisory Board (CAB)** for production changes
- **Automated testing** at each promotion stage
- **Rollback procedures** documented and tested
- **Blue-green deployments** for critical services

## 7. Drift Prevention & Compliance

### Drift Detection
```yaml
name: Drift Detection
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  drift-detection:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Terraform Plan
        run: terraform plan -detailed-exitcode
        continue-on-error: true
      
      - name: Notify on Drift
        if: failure()
        uses: 8398a7/action-slack@v3
        with:
          status: failure
          text: 'Infrastructure drift detected!'
```

### Compliance Monitoring
- **Azure Policy**: Enforce organizational standards
- **Azure Security Center**: Continuous security monitoring
- **Cost Management**: Budget alerts and cost optimization
- **Compliance Score**: Track compliance with standards

### Policy as Code
```hcl
# policies/security-policies.tf
resource "azurerm_policy_definition" "require_https" {
  name         = "require-https"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require HTTPS"
  
  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field = "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly"
          equals = "false"
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}
```

## 8. Repository Consolidation Analysis

### Multi-Repo Approach (Current - Recommended)

#### Advantages
- **Security Isolation**: Better separation of concerns
- **Independent Deployments**: Each subscription can deploy independently
- **Access Control**: Granular permissions per repository
- **Reduced Blast Radius**: Changes affect only specific environments
- **Compliance**: Easier to meet regulatory requirements
- **Team Autonomy**: Different teams can own different repositories

#### Disadvantages
- **Code Duplication**: Similar code across repositories
- **Synchronization**: Keeping modules in sync across repos
- **Complexity**: More repositories to manage

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

### Hybrid Approach (Best of Both Worlds)
- **Central Platform Repository**: Shared modules and policies
- **Subscription Repositories**: Environment-specific configurations
- **Module Registry**: Private Terraform module registry for shared modules
- **Cross-Repository Dependencies**: Use Git submodules or module registry

## 9. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- [ ] Set up repository structure
- [ ] Implement basic GitHub Actions workflows
- [ ] Configure Terraform state backends
- [ ] Set up basic security policies

### Phase 2: CI/CD Pipeline (Weeks 3-4)
- [ ] Implement comprehensive CI workflows
- [ ] Set up automated testing
- [ ] Configure deployment workflows
- [ ] Implement drift detection

### Phase 3: Security & Compliance (Weeks 5-6)
- [ ] Implement RBAC and access controls
- [ ] Set up Azure Key Vault integration
- [ ] Configure compliance monitoring
- [ ] Implement policy as code

### Phase 4: Optimization (Weeks 7-8)
- [ ] Implement cost optimization
- [ ] Set up monitoring and alerting
- [ ] Document procedures
- [ ] Train team members

## 10. Monitoring & Observability

### Infrastructure Monitoring
```hcl
# monitoring.tf
resource "azurerm_monitor_action_group" "alz_alerts" {
  name                = "alz-alerts"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "alz-alerts"

  email_receiver {
    name          = "devops-team"
    email_address = "devops@company.com"
  }
}

resource "azurerm_monitor_metric_alert" "cost_alert" {
  name                = "cost-alert"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_subscription.main.id]
  description         = "Cost threshold exceeded"

  criteria {
    metric_namespace = "Microsoft.Consumption/budgets"
    metric_name      = "Cost"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 1000
  }

  action {
    action_group_id = azurerm_monitor_action_group.alz_alerts.id
  }
}
```

### Deployment Monitoring
- **GitHub Actions**: Monitor workflow success/failure
- **Azure Monitor**: Track resource health and performance
- **Cost Management**: Monitor spending and budget compliance
- **Security Center**: Track security posture and compliance

## Conclusion

Your current multi-repository approach is well-aligned with Azure Landing Zone best practices. The recommendations above will help you:

1. **Improve Security**: Better isolation and access controls
2. **Enhance Reliability**: Comprehensive CI/CD and drift detection
3. **Ensure Compliance**: Policy as code and monitoring
4. **Optimize Operations**: Automated deployments and monitoring
5. **Scale Effectively**: Structured approach that grows with your organization

The key is to implement these recommendations incrementally, starting with the foundation and building up to more advanced features. This approach will minimize risk while providing immediate value.

