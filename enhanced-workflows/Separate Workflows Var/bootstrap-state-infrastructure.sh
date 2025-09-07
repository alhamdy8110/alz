#!/bin/bash
# bootstrap-state-infrastructure.sh
# Manual Bootstrap Script for ALZ State Infrastructure
# Run this script ONCE to create the state storage infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="rg-alz-state"
LOCATION="East US"
CONTAINER_NAME="tfstate"

# Platform state storage
PLATFORM_STORAGE="stalzplatformstate"

# Subscription state storage accounts
SUBSCRIPTIONS=("its-dev" "its-prod" "bs-dev" "bs-prod" "dg-dev" "dg-prod")

echo -e "${BLUE}🚀 Starting ALZ State Infrastructure Bootstrap${NC}"
echo -e "${BLUE}================================================${NC}"

# Function to create storage account
create_storage_account() {
    local storage_name=$1
    local subscription=$2
    
    echo -e "${YELLOW}📦 Creating storage account: $storage_name${NC}"
    
    # Check if storage account already exists
    if az storage account show --name "$storage_name" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Storage account $storage_name already exists, skipping...${NC}"
        return 0
    fi
    
    # Create storage account
    az storage account create \
        --name "$storage_name" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --access-tier Hot \
        --https-only true \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --enable-hierarchical-namespace false \
        --tags Environment=shared Purpose=terraform-state Subscription="$subscription"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Storage account $storage_name created successfully${NC}"
    else
        echo -e "${RED}❌ Failed to create storage account $storage_name${NC}"
        exit 1
    fi
}

# Function to create storage container
create_storage_container() {
    local storage_name=$1
    
    echo -e "${YELLOW}📁 Creating storage container: $CONTAINER_NAME${NC}"
    
    # Check if container already exists
    if az storage container show --name "$CONTAINER_NAME" --account-name "$storage_name" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Container $CONTAINER_NAME already exists in $storage_name, skipping...${NC}"
        return 0
    fi
    
    # Create container
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$storage_name" \
        --public-access off
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Container $CONTAINER_NAME created successfully in $storage_name${NC}"
    else
        echo -e "${RED}❌ Failed to create container $CONTAINER_NAME in $storage_name${NC}"
        exit 1
    fi
}

# Function to enable soft delete
enable_soft_delete() {
    local storage_name=$1
    
    echo -e "${YELLOW}🔄 Enabling soft delete for $storage_name${NC}"
    
    az storage blob service-properties update \
        --account-name "$storage_name" \
        --delete-retention-days 30 \
        --enable-delete-retention true
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Soft delete enabled for $storage_name${NC}"
    else
        echo -e "${YELLOW}⚠️  Failed to enable soft delete for $storage_name (non-critical)${NC}"
    fi
}

# Step 1: Create resource group
echo -e "${BLUE}📋 Step 1: Creating resource group${NC}"
if az group show --name "$RESOURCE_GROUP" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Resource group $RESOURCE_GROUP already exists, skipping...${NC}"
else
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Resource group $RESOURCE_GROUP created successfully${NC}"
    else
        echo -e "${RED}❌ Failed to create resource group $RESOURCE_GROUP${NC}"
        exit 1
    fi
fi

# Step 2: Create platform state storage
echo -e "${BLUE}📋 Step 2: Creating platform state storage${NC}"
create_storage_account "$PLATFORM_STORAGE" "platform"
create_storage_container "$PLATFORM_STORAGE"
enable_soft_delete "$PLATFORM_STORAGE"

# Step 3: Create subscription state storage
echo -e "${BLUE}📋 Step 3: Creating subscription state storage${NC}"
for sub in "${SUBSCRIPTIONS[@]}"; do
    STORAGE_NAME="stalz${sub}state"
    echo -e "${BLUE}Creating state storage for subscription: $sub${NC}"
    create_storage_account "$STORAGE_NAME" "$sub"
    create_storage_container "$STORAGE_NAME"
    enable_soft_delete "$STORAGE_NAME"
done

# Step 4: Generate GitHub Variables configuration
echo -e "${BLUE}📋 Step 4: Generating GitHub Variables configuration${NC}"
echo -e "${GREEN}🎉 State infrastructure bootstrap complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "${YELLOW}1. Configure the following GitHub Variables in your repositories:${NC}"
echo ""
echo -e "${BLUE}Platform Repository (alz-platform) Variables:${NC}"
echo "ENVIRONMENT=platform"
echo "TF_STATE_RG=$RESOURCE_GROUP"
echo "TF_STATE_SA=$PLATFORM_STORAGE"
echo "TF_STATE_CONTAINER=$CONTAINER_NAME"
echo "TF_STATE_KEY=platform/terraform.tfstate"
echo ""
echo -e "${BLUE}Subscription Repository Variables:${NC}"
for sub in "${SUBSCRIPTIONS[@]}"; do
    STORAGE_NAME="stalz${sub}state"
    echo -e "${YELLOW}$sub repository:${NC}"
    echo "ENVIRONMENT=$sub"
    echo "TF_STATE_RG=$RESOURCE_GROUP"
    echo "TF_STATE_SA=$STORAGE_NAME"
    echo "TF_STATE_CONTAINER=$CONTAINER_NAME"
    echo "TF_STATE_KEY=$sub/terraform.tfstate"
    echo ""
done

echo -e "${YELLOW}2. Configure GitHub Secrets (sensitive data):${NC}"
echo -e "${BLUE}All repositories need these secrets:${NC}"
echo "AZURE_CREDENTIALS=<your-azure-service-principal-json>"
echo "PRODUCTION_APPROVERS=senior-devops,platform-lead"
echo "SLACK_WEBHOOK_URL=<your-slack-webhook-url>"
echo "INFRACOST_API_KEY=<your-infracost-api-key>"
echo ""

echo -e "${YELLOW}3. Test your workflows with manual triggers${NC}"
echo -e "${YELLOW}4. Verify state files are created correctly${NC}"
echo ""
echo -e "${GREEN}🎉 Bootstrap process completed successfully!${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "${YELLOW}💡 Remember: Variables are for non-sensitive config, Secrets are for sensitive data!${NC}"
