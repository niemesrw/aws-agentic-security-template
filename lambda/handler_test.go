package main

import (
	"context"
	"testing"
)

func TestHandler(t *testing.T) {
	resp, err := Handler(context.Background())
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}
	expected := "Hello from Agentic Security Tool!"
	if resp != expected {
		t.Errorf("Expected %q, got %q", expected, resp)
	}
}