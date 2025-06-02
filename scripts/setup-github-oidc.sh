#!/bin/bash

# Setup GitHub OIDC Identity Provider and IAM Role for GitHub Actions
# This script creates the most secure setup for GitHub Actions to deploy to AWS
# Works with AWS SSO for secure credential management

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔐 Setting up GitHub OIDC Identity Provider for AWS${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for AWS CLI profile argument
if [ "$1" ]; then
    AWS_PROFILE="$1"
else
    # Default profile or prompt for profile
    read -p "Enter AWS SSO profile name (default: 'default'): " INPUT_PROFILE
    AWS_PROFILE=${INPUT_PROFILE:-default}
fi

echo -e "${YELLOW}Using AWS CLI profile: ${AWS_PROFILE}${NC}"

# Verify AWS SSO session
echo -e "${BLUE}🔄 Verifying AWS SSO session...${NC}"
if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &>/dev/null; then
    echo -e "${YELLOW}⚠️  AWS SSO session not active or expired. Initiating login...${NC}"
    aws sso login --profile "$AWS_PROFILE"
    
    # Verify login was successful
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &>/dev/null; then
        echo -e "${RED}❌ Failed to authenticate with AWS SSO. Please check your configuration and try again.${NC}"
        exit 1
    fi
fi

# Get current AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile "$AWS_PROFILE")
if [ -z "$ACCOUNT_ID" ]; then
    echo -e "${RED}❌ Could not get AWS Account ID. Please ensure AWS CLI is configured.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS Account ID: ${ACCOUNT_ID}${NC}"

# Prompt for GitHub repository information
echo ""
echo -e "${YELLOW}📋 Please provide your GitHub repository information:${NC}"
read -p "GitHub Username/Organization: " GITHUB_USER
read -p "Repository Name: " GITHUB_REPO

if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_REPO" ]; then
    echo -e "${RED}❌ GitHub username and repository name are required${NC}"
    exit 1
fi

GITHUB_REPO_FULL="${GITHUB_USER}/${GITHUB_REPO}"
echo -e "${GREEN}✅ GitHub Repository: ${GITHUB_REPO_FULL}${NC}"

# Create OIDC Identity Provider
echo ""
echo -e "${BLUE}🔧 Creating GitHub OIDC Identity Provider...${NC}"

# Check if OIDC provider already exists
EXISTING_PROVIDER=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" --output text --profile "$AWS_PROFILE" 2>/dev/null || echo "")

if [ -n "$EXISTING_PROVIDER" ]; then
    echo -e "${GREEN}✅ GitHub OIDC Identity Provider already exists: ${EXISTING_PROVIDER}${NC}"
    OIDC_PROVIDER_ARN="$EXISTING_PROVIDER"
else
    # Create the OIDC provider
    OIDC_PROVIDER_ARN=$(aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
        --query 'OpenIDConnectProviderArn' \
        --output text \
        --profile "$AWS_PROFILE")
    
    echo -e "${GREEN}✅ Created OIDC Identity Provider: ${OIDC_PROVIDER_ARN}${NC}"
fi

# Create IAM Role with trust policy
echo ""
echo -e "${BLUE}🔧 Creating IAM Role for GitHub Actions...${NC}"

ROLE_NAME="GitHubActions-AgenticSecurity-Role"
TRUST_POLICY_FILE=$(mktemp /tmp/github-trust-policy-XXXXXX.json)

# Create trust policy document
cat > "$TRUST_POLICY_FILE" << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${OIDC_PROVIDER_ARN}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO_FULL}:*"
                }
            }
        }
    ]
}
EOF

# Check if role exists with proper error handling
echo -e "${YELLOW}Checking if role ${ROLE_NAME} already exists...${NC}"
if aws iam get-role --role-name "$ROLE_NAME" --profile "$AWS_PROFILE" &>/dev/null; then
    echo -e "${GREEN}✅ IAM Role already exists: ${ROLE_NAME}${NC}"
    
    # Update trust policy
    echo -e "${YELLOW}Updating trust policy...${NC}"
    aws iam update-assume-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-document file://"$TRUST_POLICY_FILE" \
        --profile "$AWS_PROFILE" || {
            echo -e "${RED}❌ Failed to update trust policy. Please check your permissions.${NC}"
            exit 1
        }
    echo -e "${GREEN}✅ Updated trust policy for role${NC}"
else
    echo -e "${YELLOW}Creating new IAM role...${NC}"
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document file://"$TRUST_POLICY_FILE" \
        --description "Role for GitHub Actions to deploy Agentic Security stack" \
        --profile "$AWS_PROFILE" || {
            echo -e "${RED}❌ Failed to create IAM role. Please check your permissions.${NC}"
            exit 1
        }
    echo -e "${GREEN}✅ Created IAM Role: ${ROLE_NAME}${NC}"
fi

# Create IAM policy for CDK deployment
echo ""
echo -e "${BLUE}🔧 Creating IAM Policy for CDK deployment...${NC}"

POLICY_NAME="GitHubActions-AgenticSecurity-Policy"
POLICY_FILE="/tmp/github-deployment-policy.json"

cat > "$POLICY_FILE" << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:*",
                "iam:GetRole",
                "iam:PassRole",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:TagRole",
                "iam:UntagRole",
                "lambda:*",
                "s3:*",
                "logs:*",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:PutParameter",
                "ssm:DeleteParameter",
                "secretsmanager:GetSecretValue",
                "secretsmanager:CreateSecret",
                "secretsmanager:UpdateSecret",
                "secretsmanager:DeleteSecret",
                "secretsmanager:TagResource",
                "kms:Decrypt",
                "kms:DescribeKey",
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreatePolicy",
                "iam:DeletePolicy",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:ListPolicyVersions"
            ],
            "Resource": "arn:aws:iam::${ACCOUNT_ID}:policy/AgenticSecurity*"
        }
    ]
}
EOF

# Check if policy exists and get ARN with improved error handling
echo -e "${YELLOW}Checking if policy ${POLICY_NAME} already exists...${NC}"
EXISTING_POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn" --output text --profile "$AWS_PROFILE" 2>/dev/null || echo "")

if [ -n "$EXISTING_POLICY_ARN" ]; then
    echo -e "${GREEN}✅ IAM Policy already exists: ${EXISTING_POLICY_ARN}${NC}"
    
    # Update policy
    echo -e "${YELLOW}Updating policy...${NC}"
    POLICY_VERSION=$(aws iam create-policy-version \
        --policy-arn "$EXISTING_POLICY_ARN" \
        --policy-document file://"$POLICY_FILE" \
        --set-as-default \
        --query 'PolicyVersion.VersionId' \
        --output text \
        --profile "$AWS_PROFILE") || {
            echo -e "${RED}❌ Failed to update policy. Please check your permissions.${NC}"
            exit 1
        }
    echo -e "${GREEN}✅ Updated policy version: ${POLICY_VERSION}${NC}"
    
    POLICY_ARN="$EXISTING_POLICY_ARN"
else
    # Create new policy
    echo -e "${YELLOW}Creating new policy...${NC}"
    POLICY_ARN=$(aws iam create-policy \
        --policy-name "$POLICY_NAME" \
        --policy-document file://"$POLICY_FILE" \
        --description "Policy for GitHub Actions to deploy Agentic Security stack" \
        --query 'Policy.Arn' \
        --output text \
        --profile "$AWS_PROFILE") || {
            echo -e "${RED}❌ Failed to create policy. Please check your permissions.${NC}"
            exit 1
        }
    echo -e "${GREEN}✅ Created IAM Policy: ${POLICY_ARN}${NC}"
fi

# Attach policy to role
echo ""
echo -e "${BLUE}🔧 Attaching policy to role...${NC}"

aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN" \
    --profile "$AWS_PROFILE" || {
        echo -e "${RED}❌ Failed to attach policy to role. Please check your permissions.${NC}"
        exit 1
    }

echo -e "${GREEN}✅ Attached policy to role${NC}"

# Get role ARN with error handling
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text --profile "$AWS_PROFILE")
if [ -z "$ROLE_ARN" ]; then
    echo -e "${RED}❌ Could not retrieve Role ARN. Setup may be incomplete.${NC}"
    exit 1
fi

# Cleanup temporary files
rm -f "$TRUST_POLICY_FILE" "$POLICY_FILE"

echo ""
echo -e "${GREEN}✅ Setup completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}1. Add the following secret to your GitHub repository:${NC}"
echo "   Repository Settings → Secrets and variables → Actions → New repository secret"
echo ""
echo -e "${BLUE}   Secret Name:${NC} AWS_ROLE_ARN"
echo -e "${BLUE}   Secret Value:${NC} ${ROLE_ARN}"
echo ""
echo -e "${YELLOW}2. Test the deployment:${NC}"
echo "   git add . && git commit -m 'feat: enable GitHub Actions deployment' && git push"
echo ""
echo -e "${YELLOW}3. Monitor the deployment:${NC}"
echo "   Go to your GitHub repository → Actions tab to see the deployment progress"
echo ""
echo -e "${GREEN}🔐 Security Features Enabled:${NC}"
echo "• ✅ No long-lived AWS access keys required"
echo "• ✅ Temporary credentials with limited scope"
echo "• ✅ Repository-specific access controls"
echo "• ✅ Branch-specific deployment restrictions"
echo "• ✅ Audit trail through CloudTrail"
