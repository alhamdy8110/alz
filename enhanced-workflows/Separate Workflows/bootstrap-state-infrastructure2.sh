#!/bin/bash
# bootstrap-state-infrastructure2.sh
# Simple and Clear ALZ State Infrastructure Bootstrap
# Easy-to-understand version for quick setup

set -e

echo "🚀 ALZ State Infrastructure Bootstrap (Simple Version)"
echo "====================================================="
echo ""

# Configuration - Easy to modify
RESOURCE_GROUP="rg-alz-state"
LOCATION="East US"

echo "📋 Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo ""

# Step 1: Create Resource Group
echo "Step 1: Creating resource group..."
if az group show --name "$RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "✅ Resource group already exists"
else
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    echo "✅ Resource group created"
fi
echo ""

# Step 2: Create Platform State Storage
echo "Step 2: Creating platform state storage..."
PLATFORM_STORAGE="stalzplatformstate"

if az storage account show --name "$PLATFORM_STORAGE" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "✅ Platform storage account already exists"
else
    az storage account create \
        --name "$PLATFORM_STORAGE" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --https-only true \
        --min-tls-version TLS1_2
    echo "✅ Platform storage account created"
fi

# Create container for platform
az storage container create \
    --name "tfstate" \
    --account-name "$PLATFORM_STORAGE" \
    --public-access off >/dev/null 2>&1 || echo "✅ Platform container already exists"
echo ""

# Step 3: Create Subscription State Storage
echo "Step 3: Creating subscription state storage..."

# List of subscriptions to create
SUBSCRIPTIONS=(
    "its-dev"
    "its-prod" 
    "bs-dev"
    "bs-prod"
    "dg-dev"
    "dg-prod"
)

for sub in "${SUBSCRIPTIONS[@]}"; do
    STORAGE_NAME="stalz${sub}state"
    
    echo "  Creating storage for: $sub"
    
    if az storage account show --name "$STORAGE_NAME" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
        echo "    ✅ Storage account already exists"
    else
        az storage account create \
            --name "$STORAGE_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku Standard_LRS \
            --https-only true \
            --min-tls-version TLS1_2
        echo "    ✅ Storage account created"
    fi
    
    # Create container
    az storage container create \
        --name "tfstate" \
        --account-name "$STORAGE_NAME" \
        --public-access off >/dev/null 2>&1 || echo "    ✅ Container already exists"
done
echo ""

# Step 4: Show Results
echo "Step 4: Bootstrap Complete! 🎉"
echo "================================"
echo ""
echo "📝 What was created:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Platform Storage: $PLATFORM_STORAGE"
echo "  Subscription Storage Accounts:"
for sub in "${SUBSCRIPTIONS[@]}"; do
    echo "    - stalz${sub}state"
done
echo ""

echo "📋 Next Steps:"
echo "1. Copy the GitHub secrets below to your repositories"
echo "2. Test your workflows"
echo ""

echo "🔑 GitHub Secrets to Configure:"
echo ""
echo "Platform Repository (alz-platform):"
echo "TF_STATE_RG=$RESOURCE_GROUP"
echo "TF_STATE_SA=$PLATFORM_STORAGE"
echo "TF_STATE_CONTAINER=tfstate"
echo "TF_STATE_KEY=platform/terraform.tfstate"
echo ""

echo "Subscription Repositories:"
for sub in "${SUBSCRIPTIONS[@]}"; do
    STORAGE_NAME="stalz${sub}state"
    echo "$sub repository:"
    echo "TF_STATE_RG=$RESOURCE_GROUP"
    echo "TF_STATE_SA=$STORAGE_NAME"
    echo "TF_STATE_CONTAINER=tfstate"
    echo "TF_STATE_KEY=$sub/terraform.tfstate"
    echo ""
done

echo "✅ Bootstrap completed successfully!"
echo "🚀 You can now deploy your infrastructure using the workflows"
