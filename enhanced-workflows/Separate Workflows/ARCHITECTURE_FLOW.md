# Architecture Flow Diagram

## Simplified Centralized CI/CD Approach

### **CI Flow**

```
┌─────────────────────────────────────────────────────────────────┐
│                    CI FLOW                                      │
└─────────────────────────────────────────────────────────────────┘

1. Developer creates Pull Request
   ┌─────────────────┐
   │ company-its-    │
   │ dev-tf          │
   │ (PR created)    │
   └─────────────────┘
           │
           ▼
2. GitHub Ruleset triggers
   ┌─────────────────┐
   │ GitHub Ruleset  │
   │ (in dev repo)   │
   └─────────────────┘
           │
           ▼
3. terraform-ci-required.yml runs
   ┌─────────────────┐
   │ infra-ci-cd     │
   │ terraform-ci-   │
   │ required.yml    │
   └─────────────────┘
           │
           ▼
4. Calls terraform-ci-template.yml
   ┌─────────────────┐
   │ infra-ci-       │
   │ templates       │
   │ terraform-ci-   │
   │ template.yml    │
   └─────────────────┘
           │
           ▼
5. Terraform CI runs
   ┌─────────────────┐
   │ working_dir:    │
   │ environments/   │
   │ dev/            │
   └─────────────────┘
```

### **Deploy Flow**

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPLOY FLOW                                  │
└─────────────────────────────────────────────────────────────────┘

1. Code merged to main
   ┌─────────────────┐
   │ company-its-    │
   │ prod-tf         │
   │ (push to main)  │
   └─────────────────┘
           │
           ▼
2. terraform-deploy-required.yml runs
   ┌─────────────────┐
   │ infra-ci-cd     │
   │ terraform-deploy│
   │ -required.yml   │
   └─────────────────┘
           │
           ▼
3. Calls terraform-deploy-template.yml
   ┌─────────────────┐
   │ infra-ci-       │
   │ templates       │
   │ terraform-deploy│
   │ -template.yml   │
   └─────────────────┘
           │
           ▼
4. Terraform Deploy runs
   ┌─────────────────┐
   │ environment:    │
   │ prod            │
   │ working_dir:    │
   │ environments/   │
   │ prod/           │
   └─────────────────┘
```

### **Repository Structure**

```
┌─────────────────────────────────────────────────────────────────┐
│                    REPOSITORY STRUCTURE                        │
└─────────────────────────────────────────────────────────────────┘

infra-ci-cd/                           # Centralized CI/CD caller workflows
├── .github/workflows/
│   ├── terraform-ci-required.yml     # ← Calls CI template
│   └── terraform-deploy-required.yml # ← Calls deploy template
└── scripts/

infra-ci-templates/                    # Centralized CI/CD templates
├── .github/workflows/
│   ├── terraform-ci-template.yml     # ← CI template logic
│   └── terraform-deploy-template.yml # ← Deploy template logic
└── scripts/

company-its-dev-tf/                   # Development repository
├── .github/rulesets/
│   └── dev-ruleset.yml               # ← Triggers CI via GitHub Ruleset
├── environments/dev/                  # ← Terraform files here
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
└── modules/

company-its-prod-tf/                  # Production repository
├── .github/rulesets/
│   └── prod-ruleset.yml              # ← Triggers deploy via GitHub Ruleset
├── environments/prod/                 # ← Terraform files here
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
└── modules/
```

### **Key Improvements**

```
┌─────────────────────────────────────────────────────────────────┐
│                    KEY IMPROVEMENTS                             │
└─────────────────────────────────────────────────────────────────┘

❌ OLD APPROACH (Complex Detection):
┌─────────────────┐
│ Separate Job:   │
│ - detect-       │
│   environment   │
│ - Job           │
│   dependency    │
│ - Complex       │
│   outputs       │
└─────────────────┘

✅ NEW APPROACH (Simplified):
┌─────────────────┐
│ Direct Input:   │
│ - working_      │
│   directory     │
│ - environment   │
│ - Single job    │
│ - No detection  │
│   complexity    │
└─────────────────┘

Benefits:
✅ No separate detection job
✅ No job dependencies
✅ Simpler workflow structure
✅ Direct parameter passing
✅ Easier to understand
✅ Better performance
✅ Reduced complexity
```

### **Usage Examples**

```
┌─────────────────────────────────────────────────────────────────┐
│                    USAGE EXAMPLES                               │
└─────────────────────────────────────────────────────────────────┘

1. Automatic Trigger (Pull Request):
   ┌─────────────────┐
   │ PR created in   │
   │ company-its-    │
   │ dev-tf          │
   └─────────────────┘
           │
           ▼
   ┌─────────────────┐
   │ GitHub Ruleset  │
   │ triggers CI     │
   └─────────────────┘

2. Manual Trigger (GitHub CLI):
   ┌─────────────────┐
   │ gh workflow run │
   │ terraform-ci-   │
   │ required.yml    │
   │ -f working_     │
   │ directory=      │
   │ environments/   │
   │ dev/            │
   └─────────────────┘
           │
           ▼
   ┌─────────────────┐
   │ CI runs with    │
   │ specified dir   │
   └─────────────────┘

3. Manual Trigger (GitHub UI):
   ┌─────────────────┐
   │ Select workflow │
   │ Enter working   │
   │ directory       │
   │ Click "Run"     │
   └─────────────────┘
           │
           ▼
   ┌─────────────────┐
   │ Workflow runs   │
   │ with specified  │
   │ parameters      │
   └─────────────────┘
```
