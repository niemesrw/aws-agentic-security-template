#!/bin/bash

# Setup Environment Variables for CDK Deployment
# This script helps configure environment variables for the Agentic Security project

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env.local"

echo "🔧 Setting up environment configuration for Agentic Security"
echo "Project root: $PROJECT_ROOT"

# Create .env.local if it doesn't exist
if [ ! -f "$ENV_FILE" ]; then
    echo "📝 Creating .env.local from template..."
    cp "$PROJECT_ROOT/.env.example" "$ENV_FILE"
    echo "✅ Created $ENV_FILE"
else
    echo "📄 Found existing $ENV_FILE"
fi

# Get AWS account info
echo ""
echo "🔍 Detecting AWS configuration..."

if command -v aws &> /dev/null; then
    # Try to get account ID
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
    if [ -n "$ACCOUNT_ID" ]; then
        echo "✅ AWS Account ID: $ACCOUNT_ID"
        
        # Update .env.local with detected account
        if ! grep -q "CDK_DEFAULT_ACCOUNT=" "$ENV_FILE"; then
            echo "CDK_DEFAULT_ACCOUNT=$ACCOUNT_ID" >> "$ENV_FILE"
        else
            sed -i.bak "s/^#\s*CDK_DEFAULT_ACCOUNT=.*/CDK_DEFAULT_ACCOUNT=$ACCOUNT_ID/" "$ENV_FILE"
            sed -i.bak "s/^CDK_DEFAULT_ACCOUNT=.*/CDK_DEFAULT_ACCOUNT=$ACCOUNT_ID/" "$ENV_FILE"
        fi
    else
        echo "⚠️  Could not detect AWS Account ID. Please run 'aws configure' or 'aws sso login'"
    fi
    
    # Try to get default region
    DEFAULT_REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")
    echo "✅ AWS Region: $DEFAULT_REGION"
    
    # Update .env.local with detected region
    if ! grep -q "CDK_DEFAULT_REGION=" "$ENV_FILE"; then
        echo "CDK_DEFAULT_REGION=$DEFAULT_REGION" >> "$ENV_FILE"
    else
        sed -i.bak "s/^#\s*CDK_DEFAULT_REGION=.*/CDK_DEFAULT_REGION=$DEFAULT_REGION/" "$ENV_FILE"
        sed -i.bak "s/^CDK_DEFAULT_REGION=.*/CDK_DEFAULT_REGION=$DEFAULT_REGION/" "$ENV_FILE"
    fi
    
    # Clean up backup files
    rm -f "$ENV_FILE.bak"
else
    echo "⚠️  AWS CLI not found. Please install AWS CLI and configure credentials."
fi

echo ""
echo "📋 Current environment configuration:"
echo "─────────────────────────────────────"
cat "$ENV_FILE" | grep -v "^#" | grep -v "^$" | head -10

echo ""
echo "✅ Environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Review and edit $ENV_FILE if needed"
echo "2. Run 'make deploy' to deploy the stack"
echo "3. Or run 'cd cdk && npm run deploy' for CDK-only deployment"
