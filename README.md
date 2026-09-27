# APS Acquirer Platform

Acquirer-only payments platform. `authService` manages portal identity. `gateway-service` owns payment processing, merchant and terminal estate, settlements and reconciliation. `AUTH-FRONTEND` is the operations portal. `developer-portal` is partner documentation. `mobile_app` is the mobile channel. `pos_app` is the terminal channel.

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

## APS certification

All values that cannot be safely invented are listed in `APS_CERTIFICATION_TODO.md`.
