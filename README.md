# Azure Landing Zone - Best Practices Implementation

This repository contains comprehensive best practices and implementation examples for Azure Landing Zone (ALZ) with GitHub Actions CI/CD pipeline.

## 📋 Overview

This implementation provides:
- **Multi-repository architecture** for better security isolation
- **Comprehensive CI/CD pipeline** with GitHub Actions
- **Terraform state management** with Azure backend
- **Security and compliance** monitoring
- **Drift detection** and automated remediation
- **Cost management** and budget alerts

## 🏗️ Repository Structure

```
alz-platform/                    # Central platform repository
├── .github/workflows/           # GitHub Actions workflows
├── modules/                     # Reusable Terraform modules
├── environments/                # Environment-specific configurations
│   ├── management/             # Management group hierarchy
│   ├── connectivity/           # Hub-spoke networking
│   ├── identity/               # Azure AD configurations
│   └── security/               # Security policies and initiatives
└── docs/                       # Documentation

alz-{business-unit}-{env}/      # Subscription-specific repositories
├── .github/workflows/          # Environment-specific workflows
├── environments/               # Environment configurations
│   ├── dev/                   # Development environment
│   └── prod/                  # Production environment
├── modules/                    # Subscription-specific modules
└── policies/                   # Subscription-level policies
```

## 🚀 Quick Start

### Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.6.0
- GitHub repository with Actions enabled
- Azure subscription with appropriate permissions

### 1. Repository Setup

1. **Create the central platform repository**:
   ```bash
   git clone https://github.com/your-org/alz-platform.git
   cd alz-platform
   ```

2. **Create subscription-specific repositories**:
   ```bash
   # For each subscription (ITS-DEV, ITS-PROD, BS-DEV, BS-PROD, DG-DEV, DG-PROD)
   git clone https://github.com/your-org/alz-its-dev.git
   git clone https://github.com/your-org/alz-its-prod.git
   # ... repeat for other subscriptions
   ```

### 2. Azure Setup

1. **Create service principals** for each subscription:
   ```bash
   # For each subscription
   az ad sp create-for-rbac \
     --name "alz-its-dev-sp" \
     --role "Contributor" \
     --scopes "/subscriptions/{subscription-id}" \
     --sdk-auth
   ```

2. **Create state storage accounts**:
   ```bash
   # Create resource group for state
   az group create --name rg-alz-state --location "East US"
   
   # Create storage account for each subscription
   az storage account create \
     --name stalzitsdevstate \
     --resource-group rg-alz-state \
     --location "East US" \
     --sku Standard_LRS
   
   # Create container
   az storage container create \
     --name tfstate \
     --account-name stalzitsdevstate
   ```

### 3. GitHub Secrets Configuration

Configure the following secrets in each repository:

#### Platform Repository Secrets
- `AZURE_CREDENTIALS`: Service principal credentials
- `INFRACOST_API_KEY`: Infracost API key for cost analysis
- `SLACK_WEBHOOK_URL`: Slack webhook for notifications

#### Subscription Repository Secrets
- `AZURE_CREDENTIALS`: Subscription-specific service principal
- `TF_STATE_RG`: Resource group name for state storage
- `TF_STATE_SA`: Storage account name for state
- `TF_STATE_CONTAINER`: Container name for state
- `TF_STATE_KEY`: State file key
- `PRODUCTION_APPROVERS`: Comma-separated list of approvers for production

### 4. Deploy Infrastructure

1. **Deploy platform first**:
   ```bash
   cd alz-platform
   terraform init
   terraform plan
   terraform apply
   ```

2. **Deploy subscription-specific infrastructure**:
   ```bash
   cd alz-its-dev
   terraform init
   terraform plan
   terraform apply
   ```

## 🔧 Configuration

### Environment Variables

Each environment requires specific configuration:

#### Development Environment
```hcl
environment = "dev"
budget_amount = 500
log_retention_days = 7
enable_ddos_protection = false
```

#### Production Environment
```hcl
environment = "prod"
budget_amount = 5000
log_retention_days = 90
enable_ddos_protection = true
```

### Customization

1. **Update variables** in `terraform.tfvars.example`
2. **Modify locals** in `locals.tf` for environment-specific configurations
3. **Add custom modules** in the `modules/` directory
4. **Update workflows** in `.github/workflows/` for specific requirements

## 🔒 Security

### Access Control

- **Repository-level permissions** with branch protection
- **Azure RBAC** for resource access
- **Service principal** authentication
- **Key Vault** for secret management

### Compliance

- **Azure Policy** enforcement
- **Security scanning** with TFSec and Checkov
- **Cost monitoring** with budget alerts
- **Drift detection** with automated remediation

## 📊 Monitoring

### Built-in Monitoring

- **Application Insights** for application monitoring
- **Log Analytics** for centralized logging
- **Network Watcher** for network monitoring
- **Cost Management** for budget tracking

### Alerts

- **Infrastructure drift** detection
- **Cost threshold** alerts
- **Security policy** violations
- **Deployment status** notifications

## 🔄 CI/CD Pipeline

### Pull Request Workflow

1. **Code formatting** check
2. **Terraform validation**
3. **Security scanning** (TFSec, Checkov)
4. **Cost analysis** (Infracost)
5. **Plan generation** and review

### Deployment Workflow

1. **Environment validation**
2. **Terraform plan** execution
3. **Manual approval** for production
4. **Infrastructure deployment**
5. **Post-deployment testing**
6. **Notification** of results

## 🛠️ Troubleshooting

### Common Issues

1. **State lock errors**:
   ```bash
   terraform force-unlock <lock-id>
   ```

2. **Permission errors**:
   - Verify service principal permissions
   - Check Azure RBAC assignments
   - Validate GitHub secrets

3. **Drift detection failures**:
   - Review Terraform plan output
   - Check for manual changes
   - Verify state file integrity

### Support

- **Documentation**: Check the `docs/` directory
- **Issues**: Create GitHub issues for bugs
- **Discussions**: Use GitHub discussions for questions

## 📚 Additional Resources

- [Azure Landing Zone Documentation](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure Policy Documentation](https://docs.microsoft.com/en-us/azure/governance/policy/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🏷️ Versioning

We use [Semantic Versioning](https://semver.org/) for versioning. For the versions available, see the tags on this repository.

## 👥 Authors

- **DevOps Team** - *Initial work* - [Your Organization](https://github.com/your-org)

## 🙏 Acknowledgments

- Microsoft Azure team for the Landing Zone guidance
- HashiCorp for Terraform
- GitHub for Actions
- The open-source community for various tools and libraries

