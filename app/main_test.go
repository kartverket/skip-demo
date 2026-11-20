package main

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestHealthEndpoints(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := newRouter()

	for _, path := range []string{"/healthz", "/readyz"} {
		t.Run(path, func(t *testing.T) {
			rec := httptest.NewRecorder()
			req := httptest.NewRequest(http.MethodGet, path, nil)

			router.ServeHTTP(rec, req)

			if rec.Code != http.StatusOK {
				t.Fatalf("forventet status %d, fikk %d", http.StatusOK, rec.Code)
			}
		})
	}
}
