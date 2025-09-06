#!/bin/bash
# Script for comprehensive security scanning

set -e

echo "🔍 Running comprehensive security scan..."

# Check if Terraform files exist
if [ ! -f "*.tf" ]; then
    echo "❌ No Terraform files found"
    exit 1
fi

# Run TFSec
echo "🔍 Running TFSec security scan..."
if command -v tfsec &> /dev/null; then
    tfsec . --format sarif --out tfsec-results.sarif
    echo "✅ TFSec scan completed"
else
    echo "⚠️  TFSec not installed, skipping..."
fi

# Run Checkov
echo "🔍 Running Checkov security scan..."
if command -v checkov &> /dev/null; then
    checkov -d . --framework terraform --output sarif --output-file-path checkov-results.sarif
    echo "✅ Checkov scan completed"
else
    echo "⚠️  Checkov not installed, skipping..."
fi

# Run Trivy
echo "🔍 Running Trivy security scan..."
if command -v trivy &> /dev/null; then
    trivy config . --format sarif --output trivy-results.sarif
    echo "✅ Trivy scan completed"
else
    echo "⚠️  Trivy not installed, skipping..."
fi

# Custom security checks
echo "🔍 Running custom security checks..."

# Check for hardcoded secrets
echo "🔍 Checking for hardcoded secrets..."
SECRETS_FOUND=$(grep -r "password\|secret\|key" . --include="*.tf" | grep -v "variable\|output\|description" | grep "=" || true)

if [ -n "$SECRETS_FOUND" ]; then
    echo "❌ Potential hardcoded secrets found:"
    echo "$SECRETS_FOUND"
    exit 1
fi

# Check for public access
echo "🔍 Checking for public access configurations..."
PUBLIC_ACCESS=$(grep -r "public_access\|allow_public" . --include="*.tf" | grep "true" || true)

if [ -n "$PUBLIC_ACCESS" ]; then
    echo "⚠️  Public access configurations found:"
    echo "$PUBLIC_ACCESS"
fi

# Check for encryption
echo "🔍 Checking for encryption configurations..."
ENCRYPTION_CHECK=$(grep -r "encryption\|encrypt" . --include="*.tf" | grep "false" || true)

if [ -n "$ENCRYPTION_CHECK" ]; then
    echo "⚠️  Encryption disabled configurations found:"
    echo "$ENCRYPTION_CHECK"
fi

# Check for HTTPS enforcement
echo "🔍 Checking for HTTPS enforcement..."
HTTPS_CHECK=$(grep -r "enable_https_traffic_only" . --include="*.tf" | grep "false" || true)

if [ -n "$HTTPS_CHECK" ]; then
    echo "⚠️  HTTPS traffic only disabled configurations found:"
    echo "$HTTPS_CHECK"
fi

# Check for network security
echo "🔍 Checking for network security configurations..."
NETWORK_SECURITY=$(grep -r "network_security_group\|nsg" . --include="*.tf" | wc -l)

if [ "$NETWORK_SECURITY" -eq 0 ]; then
    echo "⚠️  No network security groups found"
fi

# Check for firewall rules
echo "🔍 Checking for firewall rules..."
FIREWALL_RULES=$(grep -r "firewall\|security_rule" . --include="*.tf" | wc -l)

if [ "$FIREWALL_RULES" -eq 0 ]; then
    echo "⚠️  No firewall rules found"
fi

# Check for access policies
echo "🔍 Checking for access policies..."
ACCESS_POLICIES=$(grep -r "access_policy\|rbac" . --include="*.tf" | wc -l)

if [ "$ACCESS_POLICIES" -eq 0 ]; then
    echo "⚠️  No access policies found"
fi

# Check for monitoring
echo "🔍 Checking for monitoring configurations..."
MONITORING=$(grep -r "monitoring\|log_analytics\|application_insights" . --include="*.tf" | wc -l)

if [ "$MONITORING" -eq 0 ]; then
    echo "⚠️  No monitoring configurations found"
fi

# Check for backup
echo "🔍 Checking for backup configurations..."
BACKUP=$(grep -r "backup\|retention" . --include="*.tf" | wc -l)

if [ "$BACKUP" -eq 0 ]; then
    echo "⚠️  No backup configurations found"
fi

# Check for compliance
echo "🔍 Checking for compliance configurations..."
COMPLIANCE=$(grep -r "policy\|compliance\|governance" . --include="*.tf" | wc -l)

if [ "$COMPLIANCE" -eq 0 ]; then
    echo "⚠️  No compliance configurations found"
fi

# Generate security report
echo "📊 Generating security report..."
cat > security-report.md << EOF
# Security Scan Report

## Scan Date
$(date)

## Summary
- TFSec: $(if [ -f "tfsec-results.sarif" ]; then echo "✅ Completed"; else echo "❌ Failed"; fi)
- Checkov: $(if [ -f "checkov-results.sarif" ]; then echo "✅ Completed"; else echo "❌ Failed"; fi)
- Trivy: $(if [ -f "trivy-results.sarif" ]; then echo "✅ Completed"; else echo "❌ Failed"; fi)

## Security Checks
- Hardcoded Secrets: $(if [ -z "$SECRETS_FOUND" ]; then echo "✅ None found"; else echo "❌ Found"; fi)
- Public Access: $(if [ -z "$PUBLIC_ACCESS" ]; then echo "✅ None found"; else echo "⚠️  Found"; fi)
- Encryption: $(if [ -z "$ENCRYPTION_CHECK" ]; then echo "✅ Enabled"; else echo "⚠️  Disabled"; fi)
- HTTPS Enforcement: $(if [ -z "$HTTPS_CHECK" ]; then echo "✅ Enabled"; else echo "⚠️  Disabled"; fi)
- Network Security: $(if [ "$NETWORK_SECURITY" -gt 0 ]; then echo "✅ Configured"; else echo "⚠️  Not configured"; fi)
- Firewall Rules: $(if [ "$FIREWALL_RULES" -gt 0 ]; then echo "✅ Configured"; else echo "⚠️  Not configured"; fi)
- Access Policies: $(if [ "$ACCESS_POLICIES" -gt 0 ]; then echo "✅ Configured"; else echo "⚠️  Not configured"; fi)
- Monitoring: $(if [ "$MONITORING" -gt 0 ]; then echo "✅ Configured"; else echo "⚠️  Not configured"; fi)
- Backup: $(if [ "$BACKUP" -gt 0 ]; then echo "✅ Configured"; else echo "⚠️  Not configured"; fi)
- Compliance: $(if [ "$COMPLIANCE" -gt 0 ]; then echo "✅ Configured"; else echo "⚠️  Not configured"; fi)

## Recommendations
1. Ensure all secrets are stored in Azure Key Vault
2. Enable encryption for all storage accounts
3. Enforce HTTPS traffic only
4. Configure network security groups
5. Set up monitoring and alerting
6. Enable backup and retention policies
7. Implement compliance policies
EOF

echo "✅ Security scan completed"
echo "📄 Security report generated: security-report.md"

