package main

import (
	"context"

	"github.com/aws/aws-lambda-go/lambda"
)

// Handler is the Lambda entrypoint. Replace this with your agent logic.
func Handler(ctx context.Context) (string, error) {
	return "Hello from Agentic Security Tool!", nil
}

func main() {
	lambda.Start(Handler)
}