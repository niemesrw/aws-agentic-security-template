.PHONY: help setup security-check lambda-build lambda-test lambda-local lambda-invoke cdk-test lint format test deploy clean

help:
	@echo "Agentic Security Tools Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  make                   Show this help message"
	@echo "  make setup             Setup environment variables and configuration"
	@echo "  make security-check    Run security checks for sensitive files"
	@echo "  make lambda-build      Build Go Lambda binary for deployment"
	@echo "  make lambda-test       Run Go Lambda unit tests"
	@echo "  make lambda-local      Invoke Go Lambda locally with sample event"
	@echo "  make lambda-invoke     Invoke deployed Lambda function with sample event"
	@echo "  make cdk-test          Run CDK (TypeScript) unit tests"
	@echo "  make lint              Lint both Go and TypeScript code"
	@echo "  make format            Format both Go and TypeScript code"
	@echo "  make test              Run all tests"
	@echo "  make deploy            Deploy the stack using CDK"
	@echo "  make clean             Clean build artifacts"

setup:
	@echo "Setting up environment configuration..."
	@./scripts/setup-env.sh

security-check:
	@echo "Running security checks..."
	@./scripts/security-check.sh

lambda-build:
	cd lambda && mkdir -p dist && GOOS=linux GOARCH=amd64 go build -o dist/bootstrap handler.go

lambda-test:
	cd lambda && go test -v

lambda-local:
	cd lambda && \
	go build -o bootstrap handler.go && \
	echo "Invoking Lambda locally with sample-events/sample-event.json" && \
	sam local invoke "AgenticGoHandler" -e ../sample-events/sample-event.json

cdk-test: lambda-build
	cd cdk && npm install && npm run build && npm run cdk-test

lint:
	cd lambda && golangci-lint run
	cd cdk && npm install && npm run lint

format:
	cd lambda && gofmt -w .
	cd cdk && npm install && npm run format

test: security-check lambda-test cdk-test

deploy: setup lambda-build
	cd cdk && npm install && npm run build && npm run synth && npm run deploy

lambda-invoke:
	@echo "🧪 Testing deployed Lambda function..."
	@FUNCTION_NAME=$$(aws cloudformation describe-stacks --stack-name AgenticSecurityStack --query 'Stacks[0].Outputs[?OutputKey==`AgentFunctionArn`].OutputValue' --output text --profile smhre-admin | xargs basename) && \
	aws lambda invoke --function-name "$$FUNCTION_NAME" --payload fileb://sample-events/sample-event.json --profile smhre-admin /tmp/lambda-response.json && \
	echo "✅ Lambda response:" && \
	cat /tmp/lambda-response.json && \
	echo ""

clean:
	cd lambda && rm -rf dist main
	cd cdk && rm -rf dist