package main

import (
	"math/rand"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// 1. Definicja Metryk (To zobaczy Grafana)
var (
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"path", "method", "status"},
	)
	httpRequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "Duration of HTTP requests",
			Buckets: prometheus.DefBuckets, // Domyślne kubełki (0.1s, 0.5s, 1s...)
		},
		[]string{"path", "method"},
	)
)

func init() {
	// Rejestracja metryk w Prometheusie
	prometheus.MustRegister(httpRequestsTotal)
	prometheus.MustRegister(httpRequestDuration)
}

// 2. Middleware (To mierzy każdy ruch)
func prometheusMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		
		// Wrapper, żeby przechwycić Status Code (200, 500)
		rw := NewResponseWriter(w)
		next.ServeHTTP(rw, r)

		duration := time.Since(start).Seconds()
		
		// Zapisz dane do metryk
		httpRequestsTotal.WithLabelValues(r.URL.Path, r.Method, http.StatusText(rw.statusCode)).Inc()
		httpRequestDuration.WithLabelValues(r.URL.Path, r.Method).Observe(duration)
	})
}

// Helper do przechwytywania status code
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}
func NewResponseWriter(w http.ResponseWriter) *responseWriter {
	return &responseWriter{w, http.StatusOK}
}
func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// 3. Logika Biznesowa (Symulacja obciążenia)
func cryptoHandler(w http.ResponseWriter, r *http.Request) {
	// Symulacja pracy (Busy CPU loop)
	done := make(chan int)
	go func() {
		for i := 0; i < 1000000; i++ {
			_ = i * i
		}
		done <- 1
	}()
	<-done

	// Symulacja losowych opóźnień (Latency)
	time.Sleep(time.Duration(rand.Intn(500)) * time.Millisecond)

	// Symulacja losowych błędów (dla wykresów)
	if rand.Float32() < 0.1 { // 10% szans na błąd
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Error generating hash"))
		return
	}

	w.Write([]byte("Crypto Hash Generated!"))
}

func main() {
	mux := http.NewServeMux()
	
	// Endpointy
	mux.HandleFunc("/crypto", cryptoHandler)
	mux.Handle("/metrics", promhttp.Handler()) // Tu zagląda Prometheus
	
	// Opakowanie w middleware
	handler := prometheusMiddleware(mux)

	println("Starting server on :8080")
	http.ListenAndServe(":8080", handler)
}