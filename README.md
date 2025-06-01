# Agentic Security Tools for AWS

A starter template for agentic security solutions on AWS, using CDK in TypeScript and Go for Lambda/executable code.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Repository Structure](#repository-structure)
4. [Development Workflow](#development-workflow)
5. [Testing](#testing)
6. [CI/CD](#cicd)
7. [Linting and Formatting](#linting-and-formatting)
8. [Prompts](#prompts)
9. [Security Considerations](#security-considerations)
10. [Extending the Project](#extending-the-project)
11. [Makefile Usage](#makefile-usage)
12. [Diagrams](#diagrams)
13. [Getting Started](#getting-started)

---

## Overview

This repository demonstrates a clean and scalable pattern for building security automation and agentic tools on AWS using the best-practice combination of:

- **AWS CDK in TypeScript** for defining cloud infrastructure.
- **Go** for Lambda functions and agent logic.

---

## Architecture

```mermaid
graph TD
  User[User/Operator] --> CLI
  CLI --> CDK[CDK App (TypeScript)]
  CDK --> Lambda[Lambda Function (Go)]
  Lambda --> AWS[AWS Services]
  CDK --> AWS
```

---

## Repository Structure

```
repo-root/
├── cdk/                # TypeScript CDK app and tests
│   ├── bin/            # CDK entrypoint
│   ├── lib/            # CDK stacks and constructs
│   ├── __tests__/      # Unit/integration tests for CDK (TypeScript/Jest)
│   ├── package.json
│   └── tsconfig.json
├── lambda/             # Go source code for Lambda
│   ├── handler.go
│   └── handler_test.go # Go unit tests
├── prompts/            # LLM prompt assets and templates
│   └── example_prompt.txt
├── sample-events/      # Example Lambda event payloads for local testing
│   └── sample-event.json
├── .github/
│   └── workflows/
│       ├── ci.yml      # Continuous Integration workflow
│       └── lint.yml    # Linting workflow
├── .env.example        # Example environment variable file
├── README.md           # Documentation
├── Makefile            # Workflow automation
├── .gitignore
├── CONTRIBUTING.md     # Contribution guidelines
├── LICENSE             # Project license
```

---

## Development Workflow

1. **Edit Go Lambda code** in `lambda/handler.go`.
2. **Edit or add unit tests** in `lambda/handler_test.go`.
3. **Build Go binary** (for deployment in Lambda):

   ```sh
   make lambda-build
   ```

4. **Edit CDK infrastructure** code in `cdk/lib/agentic-security-stack.ts`.
5. **Edit or add CDK unit tests** in `cdk/__tests__/`.
6. **Run all tests**:

   ```sh
   make test
   ```

7. **Lint and format code**:

   ```sh
   make lint
   make format
   ```

8. **Synthesize/deploy stack**:

   ```sh
   make deploy
   ```

9. **Test Lambda locally with sample events**:

   ```sh
   make lambda-local
   ```

---

## Testing

- **CDK Infrastructure (TypeScript):**
  - Write tests in `cdk/__tests__/` using [Jest](https://jestjs.io/).
  - Example: `cdk/__tests__/agentic-security-stack.test.ts`
  - Run CDK tests:
    ```sh
    make cdk-test
    ```

- **Go Lambda Functions:**
  - Write tests in files ending with `_test.go` alongside your Go code in `lambda/`.
  - Example: `lambda/handler_test.go`
  - Run Go tests:
    ```sh
    make lambda-test
    ```

- **Run all tests:**
  ```sh
  make test
  ```

---

## CI/CD

This repository is set up for automated linting, testing, and deployments using **GitHub Actions**.  
All pushes and pull requests trigger the workflows in `.github/workflows/`, which run build, lint, and test steps for both TypeScript and Go code.

---

## Linting and Formatting

- **Go:** Uses [`golangci-lint`](https://golangci-lint.run/) for static analysis and `gofmt` for formatting.
- **TypeScript:** Uses `eslint` and `prettier` for linting and formatting.
- Run linter and formatter:
  ```sh
  make lint
  make format
  ```

---

## Prompts

All LLM prompts and agent instructions are located in the [`prompts/`](./prompts/) directory.  
Edit these files to adjust agent behavior, detection instructions, and remediation templates.

---

## Security Considerations

- Least-privilege IAM roles for Lambda functions.
- Use environment variables or AWS Secrets Manager for sensitive data.
- Use CDK’s constructs to manage VPC, encryption, logging, and monitoring.
- **Do not commit secrets.** Use `.env.example` as a template for your environment variables.

---

## Extending the Project

- Add more Lambda functions by creating more Go files in `lambda/` and referencing them in the CDK stack.
- Add other resources (S3, DynamoDB, etc.) using CDK constructs in `cdk/lib/agentic-security-stack.ts`.
- Write tests for Go code and CDK stacks.
- Add prompt templates to the `prompts/` directory.
- Add sample Lambda event payloads to `sample-events/` for local testing.
- Contribute using the guidelines in [`CONTRIBUTING.md`](./CONTRIBUTING.md).

---

## Makefile Usage

A set of well-defined targets is provided for local development, testing, linting, and deployment.

```sh
make               # Show help for common targets
make lambda-build  # Build Go Lambda binary for deployment
make lambda-test   # Run Go Lambda unit tests
make lambda-local  # Invoke Go Lambda locally with sample event
make cdk-test      # Run CDK (TypeScript) unit tests
make lint          # Lint both Go and TypeScript code
make format        # Format both Go and TypeScript code
make test          # Run all tests
make deploy        # Deploy the stack using CDK
make clean         # Clean build artifacts
```

---

## Diagrams

### High-Level Architecture

```mermaid
flowchart TD
  subgraph CDK [CDK App (TypeScript)]
    direction TB
    stack1[AgenticSecurityStack]
  end
  subgraph Lambda [Lambda (Go)]
    direction TB
    handler[handler.go]
  end
  User -.-> CDK
  CDK --> Lambda
  Lambda --> AWS[(AWS Services)]
  CDK --> AWS
```

---

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (v20 or later)
- [Go](https://golang.org/) (v1.24 or later)
- [AWS CLI](https://aws.amazon.com/cli/) (configured with your credentials)
- [AWS CDK](https://docs.aws.amazon.com/cdk/latest/guide/getting_started.html) (install globally with `npm install -g aws-cdk`)

### Setup

1. **Clone the repository:**
   ```sh
   git clone <repo-url>
   cd <repo-directory>
   ```
2. **Install CDK dependencies:**
   ```sh
   cd cdk
   npm install
   ```
3. **Initialize Go modules and dependencies (if not already present):**
   ```sh
   cd lambda
   go mod tidy
   ```
   > If you see errors, ensure your `go.mod` contains:
   >
   >     module agentic-security-lambda
   >     go 1.24.3
   >     require github.com/aws/aws-lambda-go v1.48.0
4. **Build Lambda binary:**
   ```sh
   make lambda-build
   ```
5. **Bootstrap your AWS environment (only needed once per AWS account/region):**
   ```sh
   cd cdk
   cdk bootstrap
   ```
   > This step sets up the necessary resources for AWS CDK deployments. You only need to run it once per AWS account and region.
6. **Configure AWS credentials:**
   - If you use standard AWS credentials, run:
     ```sh
     aws configure
     ```
   - If you use AWS SSO (IAM Identity Center), run:
     ```sh
     aws configure sso
     aws sso login
     ```
   > For more details, see the [AWS CLI SSO documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html).
7. **Deploy the stack:**
   If you are using AWS SSO, add the `--profile <your-sso-profile>` flag to CDK commands to use your SSO credentials. For example:
   ```sh
   cdk bootstrap --profile <your-sso-profile>
   make deploy CDK_ARGS="--profile <your-sso-profile>"
   ```
   Replace `<your-sso-profile>` with the name of your SSO profile as configured in your AWS CLI.
   
   If you are not using SSO, you can run the commands without the profile flag:
   ```sh
   cdk bootstrap
   make deploy
   ```

For more details, see the [Copilot Instructions](.github/workflows/copilot-instructions.md).