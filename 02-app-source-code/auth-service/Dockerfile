FROM golang:1.26-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o auth-service ./cmd/auth/main.go

FROM gcr.io/distroless/static-debian12

EXPOSE 8080 9090

COPY --from=builder /app/auth-service /auth-service

USER nonroot:nonroot

ENTRYPOINT ["/auth-service"]