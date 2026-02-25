package health

import (
	"context"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Checker struct {
	pool *pgxpool.Pool
}

func NewChecker(pool *pgxpool.Pool) *Checker {
	return &Checker{pool: pool}
}

func RegisterHandlers(mux *http.ServeMux, pool *pgxpool.Pool) {
	c := NewChecker(pool)
	mux.HandleFunc("GET /healthz/live", c.LivenessHandler)
	mux.HandleFunc("GET /healthz/ready", c.ReadinessHandler)
}

func (c *Checker) LivenessHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"alive"}`))
}

func (c *Checker) ReadinessHandler(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()

	if err := c.pool.Ping(ctx); err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		w.Write([]byte(`{"status":"database_down"}`))
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ready"}`))
}