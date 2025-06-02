package main

import (
	"testing"
)

func TestSecurityAlert_Validation(t *testing.T) {
	tests := []struct {
		name  string
		alert SecurityAlert
		valid bool
	}{
		{
			name: "valid alert",
			alert: SecurityAlert{
				AlertType: "S3_PUBLIC_READ_ACCESS",
				Resource:  "s3://test-bucket",
				Region:    "us-east-1",
				Severity:  "HIGH",
			},
			valid: true,
		},
		{
			name: "minimal alert",
			alert: SecurityAlert{
				Resource: "s3://test-bucket",
			},
			valid: true,
		},
		{
			name:  "empty alert",
			alert: SecurityAlert{},
			valid: true, // Empty alerts are allowed but will use defaults
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Test that the alert structure is valid
			if tt.alert.Resource != "" && len(tt.alert.Resource) < 3 {
				t.Errorf("Resource name too short: %s", tt.alert.Resource)
			}
		})
	}
}

func TestGetValueOrDefault(t *testing.T) {
	tests := []struct {
		name         string
		value        string
		defaultValue string
		expected     string
	}{
		{"empty value", "", "default", "default"},
		{"non-empty value", "actual", "default", "actual"},
		{"whitespace value", "   ", "default", "   "},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := getValueOrDefault(tt.value, tt.defaultValue)
			if result != tt.expected {
				t.Errorf("Expected %q, got %q", tt.expected, result)
			}
		})
	}
}

func TestGenerateSecurityAnalysis(t *testing.T) {
	alert := SecurityAlert{
		AlertType:   "S3_PUBLIC_READ_ACCESS",
		Resource:    "s3://test-bucket",
		Region:      "us-east-1",
		Severity:    "HIGH",
		Description: "Test security alert",
		Timestamp:   "2025-06-01T10:30:00Z",
	}

	promptMessages := []string{
		"system: You are a security analyst",
		"user: Analyze this alert",
	}

	analysis := generateSecurityAnalysis(alert, promptMessages)

	// Verify the analysis contains expected sections
	expectedSections := []string{
		"### Alert Summary",
		"### Analysis",
		"### Recommendations",
		"### Missing Information",
	}

	for _, section := range expectedSections {
		if !containsString(analysis, section) {
			t.Errorf("Analysis missing section: %s", section)
		}
	}

	// Verify alert details are included
	if !containsString(analysis, alert.Resource) {
		t.Errorf("Analysis missing resource: %s", alert.Resource)
	}
}

// Helper function to check if a string contains a substring
func containsString(s, substr string) bool {
	return len(s) >= len(substr) && 
		   (len(substr) == 0 || 
		    (len(s) > 0 && (s == substr || 
		     (len(s) > len(substr) && 
		      (s[:len(substr)] == substr || 
		       s[len(s)-len(substr):] == substr ||
		       containsSubstring(s, substr))))))
}

func containsSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}