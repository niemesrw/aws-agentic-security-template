.PHONY: help lambda-build lambda-test lambda-local cdk-test lint format test deploy clean

help:
	@echo "Agentic Security Tools Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  make                   Show this help message"
	@echo "  make lambda-build      Build Go Lambda binary for deployment"
	@echo "  make lambda-test       Run Go Lambda unit tests"
	@echo "  make lambda-local      Invoke Go Lambda locally with sample event"
	@echo "  make cdk-test          Run CDK (TypeScript) unit tests"
	@echo "  make lint              Lint both Go and TypeScript code"
	@echo "  make format            Format both Go and TypeScript code"
	@echo "  make test              Run all tests"
	@echo "  make deploy            Deploy the stack using CDK"
	@echo "  make clean             Clean build artifacts"

lambda-build:
	cd lambda && mkdir -p dist && GOOS=linux GOARCH=amd64 go build -o dist/main handler.go

lambda-test:
	cd lambda && go test -v

lambda-local:
	cd lambda && \
	go build -o main handler.go && \
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

test: lambda-test cdk-test

deploy: lambda-build
	cd cdk && npm install && npm run build && npm run synth && npm run deploy

clean:
	cd lambda && rm -rf dist main
	cd cdk && rm -rf dist