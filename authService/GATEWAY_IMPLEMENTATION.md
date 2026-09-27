# Gateway implementation notes

`gateway/` introduces the first secure vertical slice of the POS/mobile gateway described in the supplied APS and SmartVista documentation:

- terminal inventory with a controlled lifecycle (`PENDING_APPROVAL` to `ACTIVE`/`SUSPENDED`);
- canonical, token-oriented transaction requests;
- per-terminal idempotency constraint and persisted transaction state;
- masked transaction responses and APS response-code messages;
- explicit `FAILED_NOT_SENT` default when no certified SmartVista route is configured.

The REST API is beneath the existing context path, for example:

`POST /api/auth-service/api/v1/admin/terminals`

`POST /api/auth-service/api/v1/transactions/purchases`

The default `gateway.smartvista.simulation-enabled=false` is intentional. Set up the actual SmartVista ISO 8583 profile/transport, mTLS terminal authentication, HSM key aliases, reversal worker, database migration strategy, and APS certification before any production payment traffic. Never enable a simulated approval route in production.
