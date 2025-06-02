#!/bin/bash

# Test the deployed Lambda function with sample event
# This script invokes the Lambda function and displays the response

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Deployed Lambda Function${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get the function ARN from CDK outputs
FUNCTION_ARN=$(aws cloudformation describe-stacks \
    --stack-name AgenticSecurityStack \
    --query 'Stacks[0].Outputs[?OutputKey==`AgentFunctionArn`].OutputValue' \
    --output text \
    --profile smhre-admin 2>/dev/null)

if [ -z "$FUNCTION_ARN" ]; then
    echo -e "${RED}❌ Could not find deployed Lambda function${NC}"
    echo "Make sure the stack is deployed: make deploy"
    exit 1
fi

echo -e "${GREEN}✅ Found Lambda function:${NC} $FUNCTION_ARN"

# Extract function name from ARN
FUNCTION_NAME=$(basename "$FUNCTION_ARN")
echo -e "${GREEN}✅ Function name:${NC} $FUNCTION_NAME"

# Test the function
echo -e "\n${BLUE}📤 Invoking Lambda with sample event...${NC}"

RESPONSE_FILE="/tmp/lambda-response.json"
LOG_FILE="/tmp/lambda-logs.txt"

# Invoke the function
aws lambda invoke \
    --function-name "$FUNCTION_NAME" \
    --payload fileb://sample-events/sample-event.json \
    --log-type Tail \
    --profile smhre-admin \
    --query 'LogResult' \
    --output text \
    "$RESPONSE_FILE" | base64 --decode > "$LOG_FILE" 2>/dev/null || true

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Lambda function executed successfully${NC}"
    
    echo -e "\n${BLUE}📋 Function Response:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ -f "$RESPONSE_FILE" ]; then
        cat "$RESPONSE_FILE" | jq '.' 2>/dev/null || cat "$RESPONSE_FILE"
    fi
    
    echo -e "\n${BLUE}📝 Function Logs:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ -f "$LOG_FILE" ]; then
        cat "$LOG_FILE"
    fi
else
    echo -e "${RED}❌ Lambda function invocation failed${NC}"
    exit 1
fi

# Cleanup
rm -f "$RESPONSE_FILE" "$LOG_FILE"

echo -e "\n${GREEN}✅ Test completed successfully!${NC}"
echo -e "\n${BLUE}💡 Next steps:${NC}"
echo "1. Review the analysis output above"
echo "2. Test prompt updates by modifying prompts/aws_lambda_security_analysis.prompt.yml"
echo "3. Deploy prompt changes with: git commit && git push (via GitHub Actions)"
