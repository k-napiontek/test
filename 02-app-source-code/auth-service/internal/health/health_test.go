package health

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestLivenessHandler(t *testing.T) {
	req, err := http.NewRequest("GET", "/healthz/live", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	
	checker := NewChecker(nil)
	checker.LivenessHandler(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("expected status %v, got %v", http.StatusOK, status)
	}

	expectedBody := `{"status":"alive"}`
	if rr.Body.String() != expectedBody {
		t.Errorf("expected body %v, got %v", expectedBody, rr.Body.String())
	}
}