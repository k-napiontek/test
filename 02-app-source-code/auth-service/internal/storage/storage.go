package storage

import "context"

type UserRepository interface {
	SaveUser(ctx context.Context, email, passwordHash string) error
}