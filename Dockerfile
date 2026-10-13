
# Build stage
FROM golang:1.26-alpine AS builder

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY cmd/ ./cmd/
COPY internal/ ./internal/

RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /api ./cmd/api

# Runtime stage
FROM alpine:3.22

RUN apk --no-cache add ca-certificates \
    && addgroup -S app \
    && adduser -S -G app app

WORKDIR /app

COPY --from=builder /api /app/api

USER app

EXPOSE 8080

ENTRYPOINT ["/app/api"]
