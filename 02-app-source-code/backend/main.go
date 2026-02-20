package main

import (
	"log"
	"net/http"
	"time"
	"my-app/handlers"
	"my-app/middleware"

	"github.com/prometheus/client_golang/prometheus/promhttp"
	"database/sql"
	"os"
	"fmt"
	"encoding/json"

	_ "github.com/lib/pq"
)
var db *sql.DB

// Struktura danych odbierana od Reacta
type DataPayload struct {
	Message string `json:"message"`
}
func enableCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Pozwalamy na dostęp z każdego źródła (dla devu OK, na produkcji lepiej ograniczyć)
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		// Obsługa pre-flight request (OPTIONS)
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}
func main() {

	var err error
	// Pobieramy hasło z bezpiecznych zmiennych środowiskowych (podrzuconych przez External Secrets!)
	dbURL := os.Getenv("DATABASE_URL") 
	db, err = sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatalf("Błąd połączenia z bazą: %v", err)
	}
	log.Println("Working....d, diajdijsa idjaijdsdjsaid")
	mux := http.NewServeMux()
	log.Println("Working....d")
	// Metrics middleware - liczy requesty, latency, status codes
	mux.Handle("/", middleware.Metrics(http.HandlerFunc(handlers.Home)))
	mux.Handle("/health", middleware.Metrics(http.HandlerFunc(handlers.Health)))
	mux.Handle("/api/hello", middleware.Metrics(http.HandlerFunc(handlers.Hello)))

	// Endpoint Prometheus - bez middleware (unikamy duplikacji)
	mux.Handle("/metrics", promhttp.Handler())

	mux.HandleFunc("/api/data", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Metoda niedozwolona ffftest", http.StatusMethodNotAllowed)
			return
		}

		var payload DataPayload
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			http.Error(w, "Zły format JSON", http.StatusBadRequest)
			return
		}

		// Zapis do PostgreSQL
		_, err := db.Exec("INSERT INTO messages (content) VALUES ($1)", payload.Message)
		if err != nil {
			http.Error(w, "Błąd zapisu do bazy, dodanie metrik", http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusCreated)
		_, _ = fmt.Fprintf(w, `{"status":"success"}`)
	})

	srv := &http.Server{
        Addr:         ":8080",
        Handler:      enableCORS(mux),
        ReadTimeout:  5 * time.Second,   // Max time to read the entire request, including body
        WriteTimeout: 10 * time.Second,  // Max time to write the response
        IdleTimeout:  120 * time.Second, // Max time to wait for the next request when keep-alives are enabled
        ReadHeaderTimeout: 3 * time.Second, // Crucial for mitigating Slowloris attacks
    }

    log.Println("Server starting on :8080")
    // Use the custom server instance instead of the default convenience function
    if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
        log.Fatalf("Server failed to start: %v", err)
    }
}