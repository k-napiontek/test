package main

import (
	"log"
	"net/http"

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
			http.Error(w, "Błąd zapisu do bazy", http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusCreated)
		fmt.Fprintf(w, `{"status":"success"}`)
	})

	log.Println("Server starting on :8080")
	log.Fatal(http.ListenAndServe(":8080", enableCORS(mux)))
}