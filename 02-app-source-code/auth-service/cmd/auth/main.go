package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"github.com/k-napiontek/test/02-app-source-code/auth-service/internal/handlers"
	"github.com/k-napiontek/test/02-app-source-code/auth-service/internal/health"
	"github.com/k-napiontek/test/02-app-source-code/auth-service/internal/storage"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		slog.Error("DATABASE_URL environment variable is not set")
		os.Exit(1)
	}

	initCtx, cancelInit := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancelInit()

	dbPool, err := pgxpool.New(initCtx, dbURL)
	if err != nil {
		slog.Error("failed to initialize database connection pool", "error", err)
		os.Exit(1)
	}
	defer dbPool.Close()

	if err := dbPool.Ping(initCtx); err != nil {
		slog.Error("failed to ping database", "error", err)
		os.Exit(1)
	}

	userRepo := storage.NewPostgresStore(dbPool)

	apiMux := http.NewServeMux()
	handlers.RegisterAuthRoutes(apiMux, userRepo)

	apiServer := &http.Server{
		Addr:         ":8080",
		Handler:      apiMux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	opsMux := http.NewServeMux()
	health.RegisterHandlers(opsMux, dbPool)
	opsMux.Handle("GET /metrics", promhttp.Handler())

	opsServer := &http.Server{
		Addr:         ":9090",
		Handler:      opsMux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 5 * time.Second,
	}

	go func() {
		slog.Info("starting api server", "port", "8080")
		if err := apiServer.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			slog.Error("api server failed", "error", err)
			os.Exit(1)
		}
	}()

	go func() {
		slog.Info("starting ops server", "port", "9090")
		if err := opsServer.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			slog.Error("ops server failed", "error", err)
			os.Exit(1)
		}
	}()

	stopChan := make(chan os.Signal, 1)
	signal.Notify(stopChan, os.Interrupt, syscall.SIGTERM)
	<-stopChan

	slog.Info("shutting down gracefully")
	
	shutdownCtx, cancelShutdown := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancelShutdown()

	apiServer.Shutdown(shutdownCtx)
	opsServer.Shutdown(shutdownCtx)

	slog.Info("server stopped cleanly")
}