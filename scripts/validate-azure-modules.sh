#!/bin/bash
# Script to validate Azure Verified Modules usage

set -e

echo "🔍 Validating Azure Verified Modules usage..."

# Check if Terraform files exist
if [ ! -f "*.tf" ]; then
    echo "❌ No Terraform files found"
    exit 1
fi

# Approved Azure Verified Modules
APPROVED_MODULES=(
    "Azure/vnet/azurerm"
    "Azure/keyvault/azurerm"
    "Azure/storage/azurerm"
    "Azure/monitoring/azurerm"
    "Azure/security-center/azurerm"
    "Azure/policy/azurerm"
    "Azure/vm/azurerm"
    "Azure/aks/azurerm"
    "Azure/network-security-group/azurerm"
    "Azure/application-gateway/azurerm"
    "Azure/container-instances/azurerm"
    "Azure/log-analytics/azurerm"
    "Azure/application-insights/azurerm"
)

# Check for Azure Verified Modules
echo "📋 Checking for Azure Verified Modules..."
AZURE_MODULES=$(grep -r "source.*Azure/" . --include="*.tf" | grep -o "Azure/[^\"']*" | sort -u)

if [ -z "$AZURE_MODULES" ]; then
    echo "❌ No Azure Verified Modules found"
    exit 1
fi

echo "✅ Found Azure Verified Modules:"
echo "$AZURE_MODULES"

# Check for unapproved modules
echo "🔍 Checking for unapproved modules..."
UNAPPROVED_MODULES=()

while IFS= read -r module; do
    if [[ ! " ${APPROVED_MODULES[@]} " =~ " ${module} " ]]; then
        UNAPPROVED_MODULES+=("$module")
    fi
done <<< "$AZURE_MODULES"

if [ ${#UNAPPROVED_MODULES[@]} -gt 0 ]; then
    echo "❌ Unapproved Azure Verified Modules detected:"
    printf '%s\n' "${UNAPPROVED_MODULES[@]}"
    echo ""
    echo "Approved modules are:"
    printf '%s\n' "${APPROVED_MODULES[@]}"
    exit 1
fi

# Check for version constraints
echo "🔍 Checking for version constraints..."
MODULES_WITHOUT_VERSION=$(grep -r "source.*Azure/" . --include="*.tf" | grep -v "version.*=")

if [ -n "$MODULES_WITHOUT_VERSION" ]; then
    echo "❌ Modules without version constraints found:"
    echo "$MODULES_WITHOUT_VERSION"
    exit 1
fi

# Check for proper module structure
echo "🔍 Checking module structure..."
MALFORMED_MODULES=$(grep -r "module.*{" . --include="*.tf" | grep -v "source.*=")

if [ -n "$MALFORMED_MODULES" ]; then
    echo "❌ Malformed module definitions found:"
    echo "$MALFORMED_MODULES"
    exit 1
fi

# Check for required module attributes
echo "🔍 Checking for required module attributes..."
REQUIRED_ATTRIBUTES=("source" "version")

for module in $AZURE_MODULES; do
    module_name=$(echo "$module" | cut -d'/' -f2)
    
    for attr in "${REQUIRED_ATTRIBUTES[@]}"; do
        if ! grep -r "module.*$module_name" . --include="*.tf" | grep -q "$attr.*="; then
            echo "❌ Module $module_name missing required attribute: $attr"
            exit 1
        fi
    done
done

# Check for security best practices
echo "🔍 Checking security best practices..."

# Check for hardcoded secrets
if grep -r "password\|secret\|key" . --include="*.tf" | grep -v "variable\|output\|description" | grep -q "="; then
    echo "⚠️  Potential hardcoded secrets found"
fi

# Check for proper tagging
if ! grep -r "tags.*=" . --include="*.tf" | grep -q "Environment\|Project\|Owner"; then
    echo "⚠️  Required tags missing"
fi

# Check for HTTPS enforcement
if ! grep -r "enable_https_traffic_only.*=.*true" . --include="*.tf"; then
    echo "⚠️  HTTPS traffic only not enforced"
fi

# Check for monitoring
if ! grep -r "monitoring.*=" . --include="*.tf" | grep -q "true"; then
    echo "⚠️  Monitoring not enabled"
fi

echo "✅ Azure Verified Modules validation completed successfully"
echo ""
echo "📊 Summary:"
echo "- Found $(echo "$AZURE_MODULES" | wc -l) Azure Verified Modules"
echo "- All modules are approved"
echo "- All modules have version constraints"
echo "- Module structure is valid"
echo "- Security best practices checked"

