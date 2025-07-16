package infrastructure

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"go-factory-platform/services/generator-service/internal/domain"
)

// HTTPTemplateServiceClient implements TemplateServiceClient using HTTP
type HTTPTemplateServiceClient struct {
	baseURL string
	client  *http.Client
}

// NewHTTPTemplateServiceClient creates a new HTTP template service client
func NewHTTPTemplateServiceClient(baseURL string) *HTTPTemplateServiceClient {
	return &HTTPTemplateServiceClient{
		baseURL: baseURL,
		client:  &http.Client{},
	}
}

// ProcessTemplate processes a template request
func (c *HTTPTemplateServiceClient) ProcessTemplate(ctx context.Context, templateID string, parameters map[string]string) (string, error) {
	url := fmt.Sprintf("%s/api/v1/templates/process", c.baseURL)

	requestBody := map[string]interface{}{
		"template_id": templateID,
		"parameters":  parameters,
	}

	jsonData, err := json.Marshal(requestBody)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("template processing failed: status %d", resp.StatusCode)
	}

	var result struct {
		GeneratedCode string `json:"generated_code"`
		Success       bool   `json:"success"`
		ErrorMessage  string `json:"error_message"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	if !result.Success {
		return "", fmt.Errorf("template processing failed: %s", result.ErrorMessage)
	}

	return result.GeneratedCode, nil
}

// GetTemplate retrieves a template by ID
func (c *HTTPTemplateServiceClient) GetTemplate(ctx context.Context, templateID string) (interface{}, error) {
	url := fmt.Sprintf("%s/api/v1/templates/%s", c.baseURL, templateID)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("template not found: status %d", resp.StatusCode)
	}

	var template interface{}
	if err := json.NewDecoder(resp.Body).Decode(&template); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return template, nil
}

// HTTPCompilerServiceClient implements CompilerServiceClient using HTTP
type HTTPCompilerServiceClient struct {
	baseURL string
	client  *http.Client
}

// NewHTTPCompilerServiceClient creates a new HTTP compiler service client
func NewHTTPCompilerServiceClient(baseURL string) *HTTPCompilerServiceClient {
	return &HTTPCompilerServiceClient{
		baseURL: baseURL,
		client:  &http.Client{},
	}
}

// WriteFiles writes accumulated files to the filesystem
func (c *HTTPCompilerServiceClient) WriteFiles(ctx context.Context, accumulator *domain.CodeAccumulator, outputPath string) error {
	url := fmt.Sprintf("%s/api/v1/files/write", c.baseURL)

	requestBody := map[string]interface{}{
		"files":       accumulator.Files,
		"output_path": outputPath,
		"metadata":    accumulator.Metadata,
	}

	jsonData, err := json.Marshal(requestBody)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("file writing failed: status %d", resp.StatusCode)
	}

	return nil
}

// CompileProject compiles a Go project
func (c *HTTPCompilerServiceClient) CompileProject(ctx context.Context, projectPath string) error {
	url := fmt.Sprintf("%s/api/v1/compile", c.baseURL)

	requestBody := map[string]interface{}{
		"project_path": projectPath,
	}

	jsonData, err := json.Marshal(requestBody)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("compilation failed: status %d", resp.StatusCode)
	}

	return nil
}

// ValidateCode validates generated code files
func (c *HTTPCompilerServiceClient) ValidateCode(ctx context.Context, files []domain.GeneratedFile) error {
	url := fmt.Sprintf("%s/api/v1/validate", c.baseURL)

	requestBody := map[string]interface{}{
		"files": files,
	}

	jsonData, err := json.Marshal(requestBody)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("validation failed: status %d", resp.StatusCode)
	}

	return nil
}
