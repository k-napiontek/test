package storage

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

type PostgresStore struct {
	pool *pgxpool.Pool
}

func NewPostgresStore(pool *pgxpool.Pool) *PostgresStore {
	return &PostgresStore{pool: pool}
}

func (p *PostgresStore) SaveUser(ctx context.Context, email, passwordHash string) error {
	query := `INSERT INTO users (email, password_hash) VALUES ($1, $2)`

	_, err := p.pool.Exec(ctx, query, email, passwordHash)
	if err != nil {
		return fmt.Errorf("failed to save user: %w", err)
	}
	return nil
}