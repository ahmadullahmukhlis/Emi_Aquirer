# Gateway microservice boundaries

The current `authservice` remains the identity service. Gateway payment code must not be deployed in it long term. Extract the existing `gateway/` package into the following independently deployable services, each with its own database/schema and service key:

| Service | Owns | Public responsibility | Suggested key scope |
| --- | --- | --- | --- |
| `terminal-service` | terminals, heartbeat, device configuration | terminal registration, approval and liveness | `terminal.read`, `terminal.write` |
| `merchant-service` | merchants, KYC cases | merchant onboarding and KYC review | `merchant.read`, `merchant.write`, `kyc.review` |
| `routing-service` | banks, EMIs, bank/EMI routes | route eligibility; no card data | `routing.read` |
| `transaction-service` | transactions, idempotency, reversals | transaction state machine and audit trail | `transaction.submit`, `transaction.read` |
| `host-connector-service` | no business records; HSM/SmartVista configuration references | certified host transport only | `host.send` |

## Service credentials

`authservice` is the issuer for service credentials. Create one key per deployed workload, never one shared gateway key:

```http
POST /api/auth-service/service-keys
Authorization: Bearer <administrator JWT>
Content-Type: application/json

{
  "serviceName": "transaction-service",
  "scopes": ["transaction.submit", "transaction.read"],
  "expiresAt": "2027-03-01T00:00:00Z"
}
```

The response exposes `secret` exactly once. Put it in a deployment secret manager (for example `TRANSACTION_SERVICE_KEY`); the database stores only a BCrypt hash. Do not commit a generated key, private key, or `.env` file to Git.

An extracted service calls a protected internal endpoint with:

```http
X-Service-Id: gws_<key prefix returned at creation>
X-Service-Key: <full secret returned at creation>
```

`GET /api/auth-service/api/v1/internal/whoami` confirms that the key works. Revoke a leaked or retired credential with `DELETE /api/auth-service/service-keys/{id}` and issue a replacement before stopping the old instance.

## Extraction order

1. Extract `routing-service` and `terminal-service`; replace direct repositories in `GatewayService` with authenticated HTTP or messaging clients.
2. Extract `merchant-service`, including KYC, and move its tables to its own database.
3. Extract `transaction-service`; preserve the `(terminal_id, idempotency_key)` unique constraint and transaction history.
4. Add the certified `host-connector-service` behind `transaction-service`. It must use mTLS and HSM-managed keys, never an application API key for PIN/card cryptography.

The existing `gateway.smartvista.simulation-enabled=false` remains fail-closed. No generated service key authorizes simulation or production host traffic.
