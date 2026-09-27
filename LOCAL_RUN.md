# Local bank-test environment

1. Copy `.env.example` to `.env` and replace every placeholder with a local secret. Never commit `.env`.
2. Start Docker Desktop.
3. Run `docker compose up --build` from this repository root.

Local addresses:

- Auth API: `http://localhost:8080/api/auth-service`
- Gateway API: `http://localhost:8081/api/gateway`
- Developer portal: `http://localhost:8082`
- Admin portal: `http://localhost:8083`

The default `GATEWAY_SWITCH_MODE=local-simulator` does not contact a national switch. Set `tcp`, host, port, and TLS only for your approved bank test endpoint. PostgreSQL data is kept in Docker named volumes; use `docker compose down` to stop without removing data.
