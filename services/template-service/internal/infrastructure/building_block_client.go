package infrastructure

import (
	"encoding/json"
	"fmt"
	"net/http"

	"go-factory-platform/services/template-service/internal/domain"
)

// HTTPBuildingBlockClient implements BuildingBlockClient using HTTP
type HTTPBuildingBlockClient struct {
	baseURL string
	client  *http.Client
}

// NewHTTPBuildingBlockClient creates a new HTTP building block client
func NewHTTPBuildingBlockClient(baseURL string) *HTTPBuildingBlockClient {
	return &HTTPBuildingBlockClient{
		baseURL: baseURL,
		client:  &http.Client{},
	}
}

// GetBuildingBlock retrieves a building block by ID
func (c *HTTPBuildingBlockClient) GetBuildingBlock(id string) (*domain.BuildingBlockReference, error) {
	url := fmt.Sprintf("%s/api/v1/building-blocks/%s", c.baseURL, id)

	resp, err := c.client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to get building block: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("building block not found: status %d", resp.StatusCode)
	}

	var block domain.BuildingBlockReference
	if err := json.NewDecoder(resp.Body).Decode(&block); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &block, nil
}

// GetBuildingBlocksByType retrieves building blocks by type
func (c *HTTPBuildingBlockClient) GetBuildingBlocksByType(blockType string) ([]*domain.BuildingBlockReference, error) {
	url := fmt.Sprintf("%s/api/v1/building-blocks?type=%s", c.baseURL, blockType)

	resp, err := c.client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to get building blocks: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to get building blocks: status %d", resp.StatusCode)
	}

	var blocks []*domain.BuildingBlockReference
	if err := json.NewDecoder(resp.Body).Decode(&blocks); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return blocks, nil
}

// GetPrimitiveBlocks retrieves all primitive building blocks
func (c *HTTPBuildingBlockClient) GetPrimitiveBlocks() ([]*domain.BuildingBlockReference, error) {
	url := fmt.Sprintf("%s/api/v1/building-blocks/primitives", c.baseURL)

	resp, err := c.client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to get primitive blocks: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to get primitive blocks: status %d", resp.StatusCode)
	}

	var blocks []*domain.BuildingBlockReference
	if err := json.NewDecoder(resp.Body).Decode(&blocks); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return blocks, nil
}
