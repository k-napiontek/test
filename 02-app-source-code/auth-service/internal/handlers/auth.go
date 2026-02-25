package handlers

import (
	"encoding/json"
	"net/http"
	
	"github.com/k-napiontek/test/02-app-source-code/auth-service/internal/storage"
)

type AuthHandler struct {
	repo storage.UserRepository
}

// Konstruktor handlera (Wstrzykiwanie Zależności)
func NewAuthHandler(repo storage.UserRepository) *AuthHandler {
	return &AuthHandler{repo: repo}
}

// Zaktualizowana funkcja rejestrująca z Middleware
func RegisterAuthRoutes(mux *http.ServeMux, repo storage.UserRepository) {
	h := NewAuthHandler(repo)
	
	// Tworzymy handler dla endpointu i "owijamy" go naszym zlicznikiem Prometheusa
	finalHandler := MetricsMiddleware(http.HandlerFunc(h.LoginHandler))
	
	mux.Handle("POST /auth/login", finalHandler)
}

func (h *AuthHandler) LoginHandler(w http.ResponseWriter, r *http.Request) {
	// Symulacja logiki biznesowej
	email := "test@example.com"
	hash := "hashed_password"

	// Zapis do AWS RDS (używamy kontekstu żądania R.Context!)
	err := h.repo.SaveUser(r.Context(), email, hash)
	if err != nil {
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "user_created"})
}