# APS Acquirer Platform

Acquirer-only payments platform. `authService` manages portal identity. `gateway-service` owns payment processing, merchant and terminal estate, settlements and reconciliation. `AUTH-FRONTEND` is the operations portal. `developer-portal` is partner documentation. `mobile_app` is the mobile channel. `pos_app` is the terminal channel.

## What this project does

This repository implements an APS/SmartVista-facing acquirer platform. It accepts payment requests from managed POS terminals and mobile channels, applies merchant and terminal controls, journals the transaction, maps the approved acquirer catalogue to ISO 8583 fields, and manages pending/reversal, settlement, reconciliation, developer applications, and operational visibility.

It is deliberately **acquirer-only**. It does not implement issuer card production, issuer account ledgers, issuer authorization engines, or issuer customer account management.

## Architecture

| Component | Purpose |
| --- | --- |
| `authService` | User registration, login, JWT/refresh tokens, email verification, password reset, portal identity. |
| `gateway-service` | Acquirer transaction orchestration, ISO mapping, merchant/terminal controls, persistence, settlement, reconciliation, workspaces and developer resources. |
| `AUTH-FRONTEND` | Angular operations, merchant, test and workspace portal. |
| `developer-portal` | Partner/developer documentation portal. |
| `mobile_app` | Flutter mobile payment channel using secure token storage. |
| `pos_app` | Flutter managed-terminal channel with protected reader token flow. |

## Supported acquirer operations

Balance Inquiry, Purchase, Cash In, Cash Out, Payment Info, Save Payment, Wallet to Card, Card to Wallet, Card to Card, Card Title Fetch, Cross Currency, and Reversal.

Every financial request uses an idempotency key. A timeout after an APS send becomes `PENDING`/recovery work; it is never treated as a fresh retry or automatic approval.

## Environment setup

Copy `.env.example` to `.env`. Replace every secret placeholder. `PORTAL_JWT_SECRET` must exactly match `JWT_AUTH_SECRET` so gateway workspace APIs can validate portal users.

Database variables: `POSTGRES_USER`, `POSTGRES_PASSWORD`.

Identity variables: `JWT_AUTH_SECRET`, `JWT_ENCRYPTION_SECRET`, `PORTAL_JWT_SECRET`.

Email variables: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_AUTH`, `SMTP_STARTTLS`, `MAIL_FROM`, `PORTAL_PUBLIC_URL`.

APS variables: `GATEWAY_SWITCH_MODE`, `GATEWAY_SWITCH_HOST`, `GATEWAY_SWITCH_PORT`, `GATEWAY_SWITCH_TLS`, `APS_MTLS_KEYSTORE_REF`, `HSM_PROVIDER`, `HSM_ENDPOINT`, `HSM_KEY_ALIAS_ZPK`, `OTP_PROVIDER`, `RECONCILIATION_SOURCE`, `SETTLEMENT_SOURCE`.

Do not commit real passwords, certificates, HSM material, API secrets or bank routes.

## Docker

Run `docker compose up --build` from this directory after configuring `.env`.

Services: auth API on port 8080, gateway API on 8081, developer portal on 8082, operations portal on 8083.

Open the operations portal at `http://localhost:8083`. The local bootstrap administrator is controlled by `app.bootstrap-admin.*` properties in the auth service; replace it before deployment.

To stop local containers: `docker compose down`. Add `-v` only when you intentionally want to delete local database volumes.

## Features

- Gateway: APS acquirer operations, idempotency, transaction journal, pending/reversal handling, simulator, merchant and terminal estate, settlement, reconciliation metadata, webhooks and workspaces.
- Operations portal: login, registration, email verification, password reset, test/production console, settlements and workspaces.
- Mobile: secure login, protected-token payment actions and recovery view.
- POS: operator login, protected reader-token payment path and multilingual card prompt.

## Checks

Gateway: `cd gateway-service` then `..\\authService\\mvnw.cmd test`.

Auth: `cd authService` then `.\\mvnw.cmd test`.

Portal: `cd AUTH-FRONTEND` then `npm.cmd run build`.

Mobile and POS: run `flutter analyze` in each application directory.

## Security model

- Browser users authenticate through `authService`; portal workspace APIs validate the same JWT secret in `gateway-service`.
- Developer applications use separate client credentials and optional registered certificate thumbprints.
- Only masked or tokenized card references are accepted by application APIs. PAN, CVV, PIN, PIN blocks, OTP values and key material must never be stored or logged.
- Workspace membership separates business applications and team roles. Production secrets belong in a secret manager, not source code.

## Test and production modes

`GATEWAY_SWITCH_MODE=local-simulator` enables controlled local APS outcomes for development. Use `tcp` only after configuring the certified APS host, port, TLS/mTLS profile and HSM references. The portal Test console does not send real cardholder data.

## Repository layout and documentation

- `APS_CERTIFICATION_TODO.md` — external APS/bank certification decisions required before production.
- `LOCAL_RUN.md` — local Windows run notes.
- `docker-compose.yml` — local multi-service container topology.
- `.env.example` — required deployment configuration names and safe defaults.

## Production checklist

1. Configure PostgreSQL, strong JWT secrets, SMTP, HTTPS origins and a secret manager.
2. Configure APS transport, mTLS, HSM, OTP and reconciliation/settlement sources through environment or secret references.
3. Run the test/build commands above.
4. Complete APS, PCI/P2PE, EMV terminal and regulatory certification requirements.
5. Review `APS_CERTIFICATION_TODO.md` and remove all placeholders before go-live.

## APS certification

All values that cannot be safely invented are listed in `APS_CERTIFICATION_TODO.md`.
