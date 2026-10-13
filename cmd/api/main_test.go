package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestHealthHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	healthHandler(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d",
			http.StatusOK, rec.Code)
	}

	if contentType := rec.Header().Get("Content-Type"); contentType != "application/json" {
		t.Errorf("expected application/json, got %q", contentType)
	}

	var response HealthResponse
	if err := json.NewDecoder(rec.Body).Decode(&response); err != nil {
		t.Fatalf("failed to decode JSON response: %v", err)
	}

	if response.Status != "ok" {
		t.Errorf("expected status ok, got %q", response.Status)
	}

	if response.Service != "devops-api" {
		t.Errorf("expected service devops-api, got %q", response.Service)
	}

	if _, err := time.Parse(time.RFC3339, response.Timestamp); err != nil {
		t.Errorf("invalid timestamp: %v", err)
	}
}

func TestReadyHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/ready", nil)
	rec := httptest.NewRecorder()

	readyHandler(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d",
			http.StatusOK, rec.Code)
	}

	if contentType := rec.Header().Get("Content-Type"); contentType != "application/json" {
		t.Errorf("expected application/json, got %q", contentType)
	}

	var response struct {
		Status string `json:"status"`
	}

	if err := json.NewDecoder(rec.Body).Decode(&response); err != nil {
		t.Fatalf("failed to decode JSON response: %v", err)
	}

	if response.Status != "ready" {
		t.Errorf("expected status ready, got %q", response.Status)
	}
}
