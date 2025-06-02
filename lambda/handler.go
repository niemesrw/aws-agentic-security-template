package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"gopkg.in/yaml.v2"
)

// PromptConfig represents the structure of the prompt YAML file
type PromptConfig struct {
	Messages []struct {
		Role    string `yaml:"role"`
		Content string `yaml:"content"`
	} `yaml:"messages"`
	Model      string        `yaml:"model"`
	TestData   []interface{} `yaml:"testData"`
	Evaluators []interface{} `yaml:"evaluators"`
}

// SecurityAlert represents an incoming security alert payload
type SecurityAlert struct {
	AlertType    string                 `json:"alertType,omitempty"`
	Resource     string                 `json:"resource,omitempty"`
	Region       string                 `json:"region,omitempty"`
	Severity     string                 `json:"severity,omitempty"`
	Description  string                 `json:"description,omitempty"`
	Timestamp    string                 `json:"timestamp,omitempty"`
	Metadata     map[string]interface{} `json:"metadata,omitempty"`
	RawPayload   interface{}            `json:"rawPayload,omitempty"`
}

// AnalysisResponse represents the structured response from the Lambda
type AnalysisResponse struct {
	Analysis       string `json:"analysis"`
	Model          string `json:"model"`
	PromptVersion  string `json:"promptVersion,omitempty"`
	ProcessingTime string `json:"processingTime,omitempty"`
}

// Handler is the Lambda entrypoint for processing security alerts
func Handler(ctx context.Context, alert SecurityAlert) (*AnalysisResponse, error) {
	log.Printf("Processing security alert for resource: %s", alert.Resource)

	// Load prompt configuration from S3
	promptConfig, err := loadPromptFromS3(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to load prompt: %w", err)
	}

	// Process the alert using the loaded prompt
	analysis, err := processSecurityAlert(alert, promptConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to process alert: %w", err)
	}

	response := &AnalysisResponse{
		Analysis: analysis,
		Model:    promptConfig.Model,
	}

	log.Printf("Successfully processed alert for resource: %s", alert.Resource)
	return response, nil
}

// loadPromptFromS3 retrieves and parses the prompt configuration from S3
func loadPromptFromS3(ctx context.Context) (*PromptConfig, error) {
	bucketName := os.Getenv("PROMPTS_BUCKET")
	promptKey := os.Getenv("PROMPT_KEY")

	if bucketName == "" || promptKey == "" {
		return nil, fmt.Errorf("PROMPTS_BUCKET and PROMPT_KEY environment variables must be set")
	}

	// Load AWS config
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	// Create S3 client
	s3Client := s3.NewFromConfig(cfg)

	// Get object from S3
	result, err := s3Client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: &bucketName,
		Key:    &promptKey,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to get prompt from S3 bucket %s, key %s: %w", bucketName, promptKey, err)
	}
	defer result.Body.Close()

	// Parse YAML
	var promptConfig PromptConfig
	if err := yaml.NewDecoder(result.Body).Decode(&promptConfig); err != nil {
		return nil, fmt.Errorf("failed to parse prompt YAML: %w", err)
	}

	log.Printf("Successfully loaded prompt configuration with model: %s", promptConfig.Model)
	return &promptConfig, nil
}

// processSecurityAlert processes the security alert using the loaded prompt configuration
func processSecurityAlert(alert SecurityAlert, promptConfig *PromptConfig) (string, error) {
	// Convert alert to JSON for template substitution
	alertJSON, err := json.MarshalIndent(alert, "", "  ")
	if err != nil {
		return "", fmt.Errorf("failed to marshal alert: %w", err)
	}

	// Build the prompt by substituting variables
	var processedMessages []string
	for _, message := range promptConfig.Messages {
		// Replace template variables in the content
		content := strings.ReplaceAll(message.Content, "{{input}}", string(alertJSON))
		processedMessages = append(processedMessages, fmt.Sprintf("**%s**: %s", message.Role, content))
	}

	// Generate analysis response (in a real implementation, this would call an LLM API)
	analysis := generateSecurityAnalysis(alert, processedMessages)

	return analysis, nil
}

// generateSecurityAnalysis creates a structured security analysis response
// In a production implementation, this would integrate with an LLM API
func generateSecurityAnalysis(alert SecurityAlert, promptMessages []string) string {
	// This is a mock implementation - replace with actual LLM API call
	analysis := fmt.Sprintf(`### Alert Summary
- Alert Type: %s
- Resource(s) Involved: %s
- AWS Region: %s
- Severity Level: %s
- Initial Assessment: Automated analysis based on alert metadata

### Analysis
- **Root Cause**: %s
- **Potential Impact**: Varies based on resource exposure and access patterns
- **False Positive Likelihood**: Medium - requires manual verification
- **Related AWS Services Involved**: IAM, S3, CloudTrail, VPC

### Recommendations
- [Immediate] – Review resource permissions and access logs
- [Short-term] – Implement least-privilege access controls
- [Long-term] – Set up automated monitoring and alerting

### Missing Information
- [Access Logs] – Required to determine if unauthorized access occurred
- [Resource Configuration] – Needed to assess current security posture

---
**Processing Details:**
- Model: %s
- Alert processed at: %s
- Number of prompt messages: %d`,
		getValueOrDefault(alert.AlertType, "Unknown"),
		getValueOrDefault(alert.Resource, "Unknown"),
		getValueOrDefault(alert.Region, "Unknown"),
		getValueOrDefault(alert.Severity, "Medium"),
		getValueOrDefault(alert.Description, "Security alert detected"),
		"openai/gpt-4o", // This would come from promptConfig.Model in real implementation
		alert.Timestamp,
		len(promptMessages))

	return analysis
}

// getValueOrDefault returns the value if not empty, otherwise returns the default
func getValueOrDefault(value, defaultValue string) string {
	if value == "" {
		return defaultValue
	}
	return value
}

func main() {
	lambda.Start(Handler)
}