#!/bin/bash

# Security Check Script
# Verifies that sensitive files are not being tracked by git

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔒 Running security checks for Agentic Security project..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ISSUES_FOUND=0

# Check for sensitive files in git staging
echo "🔍 Checking git staging area for sensitive files..."

SENSITIVE_PATTERNS=(
    "\.env$"
    "\.env\.local$"
    "\.env\.production$"
    "\.env\.staging$"
    "\.env\.development$"
    "\.aws/credentials$"
    "\.aws/config$"
    ".*\.key$"
    ".*\.pem$"
    ".*secret.*"
    ".*password.*"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if git diff --cached --name-only | grep -E "$pattern" >/dev/null 2>&1; then
        echo -e "${RED}❌ DANGER: Sensitive file pattern '$pattern' found in staging area!${NC}"
        echo -e "${YELLOW}   Files found:${NC}"
        git diff --cached --name-only | grep -E "$pattern" | sed 's/^/     /'
        echo -e "${YELLOW}   Run: git restore --staged <filename> to unstage${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
done

# Check if .env.local exists and is ignored
echo ""
echo "🔍 Checking .env.local configuration..."

if [ -f ".env.local" ]; then
    if git check-ignore .env.local >/dev/null 2>&1; then
        echo -e "${GREEN}✅ .env.local exists and is properly ignored by git${NC}"
    else
        echo -e "${RED}❌ DANGER: .env.local exists but is NOT ignored by git!${NC}"
        echo -e "${YELLOW}   This file may contain sensitive information${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
else
    echo -e "${YELLOW}⚠️  .env.local does not exist (run 'make setup' to create it)${NC}"
fi

# Check for hardcoded secrets in code
echo ""
echo "🔍 Scanning code for potential hardcoded secrets..."

SECRET_PATTERNS=(
    "sk-[a-zA-Z0-9]{32,}"        # OpenAI API keys
    "sk-ant-[a-zA-Z0-9-]{95,}"   # Anthropic API keys
    "AKIA[0-9A-Z]{16}"           # AWS access key IDs
    "password\s*=\s*['\"][^'\"]+['\"]"  # Hardcoded passwords
    "secret\s*=\s*['\"][^'\"]+['\"]"    # Hardcoded secrets
)

# Directories to exclude from secret scanning
EXCLUDE_PATHS=(
    "./node_modules/*"
    "./cdk/node_modules/*"
    "./cdk.out/*"
    "./cdk/cdk.out/*"
    "./.git/*"
    "./lambda/dist/*"
    "./.env.example"  # This is a template file, not real secrets
)

# Build exclude arguments for find command
EXCLUDE_ARGS=""
for exclude_path in "${EXCLUDE_PATHS[@]}"; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS -not -path \"$exclude_path\""
done

for pattern in "${SECRET_PATTERNS[@]}"; do
    # Only scan our source files, excluding dependencies and build artifacts
    matches=$(find . -type f \( -name "*.go" -o -name "*.ts" -o -name "*.js" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" \) \
              -not -path "./node_modules/*" \
              -not -path "./cdk/node_modules/*" \
              -not -path "./cdk.out/*" \
              -not -path "./cdk/cdk.out/*" \
              -not -path "./.git/*" \
              -not -path "./lambda/dist/*" \
              -not -name "package-lock.json" \
              -not -name "go.sum" \
              -exec grep -l -E "$pattern" {} \; 2>/dev/null || true)
    
    if [ -n "$matches" ]; then
        # Filter out .env.example since it's just a template
        filtered_matches=$(echo "$matches" | grep -v ".env.example" || true)
        if [ -n "$filtered_matches" ]; then
            echo -e "${RED}❌ DANGER: Potential secret pattern '$pattern' found in:${NC}"
            echo "$filtered_matches" | sed 's/^/     /'
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
        fi
    fi
done

# Check AWS credentials configuration
echo ""
echo "🔍 Checking AWS credentials configuration..."

if [ -f ~/.aws/credentials ] || [ -n "$AWS_ACCESS_KEY_ID" ]; then
    echo -e "${YELLOW}⚠️  AWS credentials detected in environment${NC}"
    echo -e "${YELLOW}   For production, consider using IAM roles or AWS SSO instead${NC}"
fi

# Check for proper .gitignore
echo ""
echo "🔍 Checking .gitignore configuration..."

REQUIRED_IGNORES=(
    ".env"
    ".env.local"
    ".env.*.local"
    "node_modules/"
    "*.log"
    ".DS_Store"
)

for ignore_pattern in "${REQUIRED_IGNORES[@]}"; do
    if ! grep -q "$ignore_pattern" .gitignore 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Missing gitignore pattern: $ignore_pattern${NC}"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ Security check passed! No issues found.${NC}"
    exit 0
else
    echo -e "${RED}❌ Security check failed! Found $ISSUES_FOUND issue(s).${NC}"
    echo ""
    echo "🛠️  Recommended actions:"
    echo "1. Remove sensitive files from git staging"
    echo "2. Add sensitive patterns to .gitignore"
    echo "3. Use environment variables or AWS Secrets Manager for secrets"
    echo "4. Review and update security practices"
    echo ""
    echo "📚 See SECURITY.md for detailed security guidelines"
    exit 1
fi
