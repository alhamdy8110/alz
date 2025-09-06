#!/bin/bash
# Script for compliance validation

set -e

echo "🔍 Running compliance validation..."

# Check if Terraform files exist
if [ ! -f "*.tf" ]; then
    echo "❌ No Terraform files found"
    exit 1
fi

# Compliance standards to check
COMPLIANCE_STANDARDS=("CIS" "NIST" "SOC2" "ISO27001")

# CIS Compliance Checks
echo "🔍 Checking CIS compliance..."

# Check for required tags
echo "🔍 Checking for required tags..."
REQUIRED_TAGS=("Environment" "Project" "Owner" "CostCenter" "Compliance")

for tag in "${REQUIRED_TAGS[@]}"; do
    if ! grep -r "tags.*=" . --include="*.tf" | grep -q "$tag"; then
        echo "❌ Required tag missing: $tag"
        exit 1
    fi
done

# Check for resource naming conventions
echo "🔍 Checking resource naming conventions..."
NAMING_VIOLATIONS=$(grep -r "resource.*{" . --include="*.tf" | grep -v "rg-\|vnet-\|kv-\|st" || true)

if [ -n "$NAMING_VIOLATIONS" ]; then
    echo "⚠️  Potential naming convention violations:"
    echo "$NAMING_VIOLATIONS"
fi

# Check for encryption
echo "🔍 Checking encryption configurations..."
ENCRYPTION_VIOLATIONS=$(grep -r "encryption.*=" . --include="*.tf" | grep "false" || true)

if [ -n "$ENCRYPTION_VIOLATIONS" ]; then
    echo "❌ Encryption disabled configurations found:"
    echo "$ENCRYPTION_VIOLATIONS"
    exit 1
fi

# NIST Compliance Checks
echo "🔍 Checking NIST compliance..."

# Check for access controls
echo "🔍 Checking access controls..."
ACCESS_CONTROLS=$(grep -r "access_policy\|rbac\|role_assignment" . --include="*.tf" | wc -l)

if [ "$ACCESS_CONTROLS" -eq 0 ]; then
    echo "❌ No access controls found"
    exit 1
fi

# Check for audit logging
echo "🔍 Checking audit logging..."
AUDIT_LOGGING=$(grep -r "log_analytics\|application_insights\|monitoring" . --include="*.tf" | wc -l)

if [ "$AUDIT_LOGGING" -eq 0 ]; then
    echo "❌ No audit logging found"
    exit 1
fi

# Check for network segmentation
echo "🔍 Checking network segmentation..."
NETWORK_SEGMENTATION=$(grep -r "subnet\|network_security_group" . --include="*.tf" | wc -l)

if [ "$NETWORK_SEGMENTATION" -eq 0 ]; then
    echo "❌ No network segmentation found"
    exit 1
fi

# SOC2 Compliance Checks
echo "🔍 Checking SOC2 compliance..."

# Check for availability
echo "🔍 Checking availability configurations..."
AVAILABILITY=$(grep -r "availability\|redundancy\|backup" . --include="*.tf" | wc -l)

if [ "$AVAILABILITY" -eq 0 ]; then
    echo "⚠️  No availability configurations found"
fi

# Check for processing integrity
echo "🔍 Checking processing integrity..."
PROCESSING_INTEGRITY=$(grep -r "validation\|integrity\|checksum" . --include="*.tf" | wc -l)

if [ "$PROCESSING_INTEGRITY" -eq 0 ]; then
    echo "⚠️  No processing integrity configurations found"
fi

# Check for confidentiality
echo "🔍 Checking confidentiality configurations..."
CONFIDENTIALITY=$(grep -r "encryption\|key_vault\|secret" . --include="*.tf" | wc -l)

if [ "$CONFIDENTIALITY" -eq 0 ]; then
    echo "❌ No confidentiality configurations found"
    exit 1
fi

# ISO27001 Compliance Checks
echo "🔍 Checking ISO27001 compliance..."

# Check for information security management
echo "🔍 Checking information security management..."
SECURITY_MANAGEMENT=$(grep -r "security_center\|policy\|governance" . --include="*.tf" | wc -l)

if [ "$SECURITY_MANAGEMENT" -eq 0 ]; then
    echo "⚠️  No information security management configurations found"
fi

# Check for risk management
echo "🔍 Checking risk management..."
RISK_MANAGEMENT=$(grep -r "risk\|threat\|vulnerability" . --include="*.tf" | wc -l)

if [ "$RISK_MANAGEMENT" -eq 0 ]; then
    echo "⚠️  No risk management configurations found"
fi

# Check for incident management
echo "🔍 Checking incident management..."
INCIDENT_MANAGEMENT=$(grep -r "alert\|notification\|incident" . --include="*.tf" | wc -l)

if [ "$INCIDENT_MANAGEMENT" -eq 0 ]; then
    echo "⚠️  No incident management configurations found"
fi

# Generate compliance report
echo "📊 Generating compliance report..."
cat > compliance-report.md << EOF
# Compliance Validation Report

## Scan Date
$(date)

## Compliance Standards Checked
$(printf '%s\n' "${COMPLIANCE_STANDARDS[@]}")

## CIS Compliance
- Required Tags: $(if [ -z "$REQUIRED_TAGS" ]; then echo "✅ All present"; else echo "❌ Missing"; fi)
- Resource Naming: $(if [ -z "$NAMING_VIOLATIONS" ]; then echo "✅ Compliant"; else echo "⚠️  Violations found"; fi)
- Encryption: $(if [ -z "$ENCRYPTION_VIOLATIONS" ]; then echo "✅ Enabled"; else echo "❌ Disabled"; fi)

## NIST Compliance
- Access Controls: $(if [ "$ACCESS_CONTROLS" -gt 0 ]; then echo "✅ Configured"; else echo "❌ Not configured"; fi)
- Audit Logging: $(if [ "$AUDIT_LOGGING" -gt 0 ]; then echo "✅ Configured"; else echo "❌ Not configured"; fi)
- Network Segmentation: $(if [ "$NETWORK_SEGMENTATION" -gt 0 ]; then echo "✅ Configured"; else echo "❌ Not configured"; fi)

## SOC2 Compliance
- Availability: $(if [ "$AVAILABILITY" -gt 0 ]; then echo "✅ Configured"; else echo "⚠️  Not configured"; fi)
- Processing Integrity: $(if [ "$PROCESSING_INTEGRITY" -gt 0 ]; then echo "✅ Configured"; else echo "⚠️  Not configured"; fi)
- Confidentiality: $(if [ "$CONFIDENTIALITY" -gt 0 ]; then echo "✅ Configured"; else echo "❌ Not configured"; fi)

## ISO27001 Compliance
- Information Security Management: $(if [ "$SECURITY_MANAGEMENT" -gt 0 ]; then echo "✅ Configured"; else echo "⚠️  Not configured"; fi)
- Risk Management: $(if [ "$RISK_MANAGEMENT" -gt 0 ]; then echo "✅ Configured"; else echo "⚠️  Not configured"; fi)
- Incident Management: $(if [ "$INCIDENT_MANAGEMENT" -gt 0 ]; then echo "✅ Configured"; else echo "⚠️  Not configured"; fi)

## Recommendations
1. Ensure all required tags are present
2. Follow resource naming conventions
3. Enable encryption for all resources
4. Configure access controls and RBAC
5. Set up audit logging and monitoring
6. Implement network segmentation
7. Configure availability and backup
8. Set up security management policies
9. Implement risk management controls
10. Configure incident management and alerting
EOF

echo "✅ Compliance validation completed"
echo "📄 Compliance report generated: compliance-report.md"

