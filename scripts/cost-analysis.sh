#!/bin/bash
# Script for cost analysis using Infracost

set -e

echo "🔍 Running cost analysis..."

# Check if Terraform files exist
if [ ! -f "*.tf" ]; then
    echo "❌ No Terraform files found"
    exit 1
fi

# Check if Infracost is installed
if ! command -v infracost &> /dev/null; then
    echo "⚠️  Infracost not installed, skipping cost analysis..."
    exit 0
fi

# Check if Infracost API key is set
if [ -z "$INFRACOST_API_KEY" ]; then
    echo "⚠️  INFRACOST_API_KEY not set, skipping cost analysis..."
    exit 0
fi

# Run Infracost breakdown
echo "🔍 Running Infracost breakdown..."
infracost breakdown --path . --format json --out infracost-breakdown.json

# Run Infracost diff
echo "🔍 Running Infracost diff..."
infracost diff --path . --format json --out infracost-diff.json

# Generate cost report
echo "📊 Generating cost report..."
cat > cost-report.md << EOF
# Cost Analysis Report

## Scan Date
$(date)

## Summary
- Infracost Breakdown: $(if [ -f "infracost-breakdown.json" ]; then echo "✅ Completed"; else echo "❌ Failed"; fi)
- Infracost Diff: $(if [ -f "infracost-diff.json" ]; then echo "✅ Completed"; else echo "❌ Failed"; fi)

## Cost Breakdown
\`\`\`json
$(cat infracost-breakdown.json)
\`\`\`

## Cost Diff
\`\`\`json
$(cat infracost-diff.json)
\`\`\`

## Recommendations
1. Review resource sizing and optimize where possible
2. Consider reserved instances for predictable workloads
3. Implement auto-scaling to reduce costs during low usage
4. Use spot instances for non-critical workloads
5. Monitor and alert on cost thresholds
6. Implement cost allocation tags
7. Review and optimize storage classes
8. Consider Azure Hybrid Benefit for eligible resources
EOF

echo "✅ Cost analysis completed"
echo "📄 Cost report generated: cost-report.md"

