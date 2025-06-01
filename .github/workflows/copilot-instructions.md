# Copilot Instructions
## Introduction 
This document provides guidelines for using AWS CDK with TypeScript and Go, focusing on clean code generation, inline comments, and comprehensive documentation. It also outlines how to structure unit tests and Makefile targets for efficient development workflows.
## CDK with TypeScript
Use AWS CDK with TypeScript to define your cloud infrastructure. TypeScript provides strong typing and modern JavaScript features, making it easier to write and maintain your infrastructure code.
## CDK with Go

For Lambda functions or executable code, use Go. Go is known for its performance and simplicity, making it a great choice for serverless applications. Ensure that the code is clean, easy to read, and well-commented.
## Code Quality
Generate clean and easy-to-read code. Use consistent naming conventions and follow best practices for both TypeScript and Go. Inline comments should explain complex logic or important decisions in the code.
## Testing
Unit tests should be located in a dedicated directory, typically named `tests` or `spec`. Use a testing framework suitable for the language (e.g., Jest for TypeScript, Go's built-in testing package). Provide clear instructions on how to run these tests.
## Makefile Targets
Define Makefile targets for common tasks such as building, testing, and deploying your application. This helps streamline the development workflow and ensures consistency across different environments. Include a help target that displays all available commands and their descriptions.
## Documentation
Ensure that all code is well-documented. Use JSDoc for TypeScript and GoDoc for Go to generate documentation from comments. This helps other developers understand the purpose and usage of your code.
## Getting Started
Include instructions on how to set up the development environment, including prerequisites like Node.js, Go, and AWS CLI. Provide a step-by-step guide on how to deploy the application using CDK.
## Conclusion
Following these guidelines will help maintain a high standard of code quality and documentation in your AWS CDK projects. By using TypeScript for infrastructure definitions and Go for serverless functions, you can leverage the strengths of both languages while ensuring your code is clean, well-tested, and easy to maintain.