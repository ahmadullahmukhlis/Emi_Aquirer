# Developer Portal

Node 24+ backend and browser UI, with a persistent SQLite database. The Portal owns email registration/login, Google OAuth, organizations, applications, hashed API keys, purchase records, business submissions, event logs, and signed webhook deliveries. The Spring Gateway executes authenticated sandbox purchase requests and persists its own result.

## Run locally

From the repository root:

```powershell
node developer-portal/start-local.mjs
```

Open http://localhost:8082 and choose **Create account**. Use any valid email and a password of at least 12 characters. No shared default account is needed. Create an application, issue a test key, and submit a test purchase from Payments or your server.

The launcher generates a random service key in `.local-data/portal-service-key`, supplies it to both services, and starts the Gateway with a clean Maven build. Startup can take a minute. Runtime logs are in `.local-logs`; Portal data is `.local-data/portal.sqlite`. The launcher does not erase data. Node and Java 21 must be installed; first Maven startup requires network access.

## API

`POST /v1/purchases` accepts `Authorization: Bearer sk_test_...` and `Idempotency-Key`. Body:

```json
{"amountMinor":10000,"currency":"AFN","reference":"order-123","scenario":"approved"}
```

`GET /v1/purchases` lists only that key's application and environment. `GET /v1/purchases/{id}` returns its stored response/status and refreshes pending Gateway results. Scenarios: approved, declined, pending. Pending is not approval. Never create another request to recover an unknown outcome; query the original payment.

The Portal stores a request before calling Gateway. Concurrent identical requests produce one Portal purchase. The Gateway separately enforces an idempotency key. Payload changes on an existing key return 409. Sandbox records never enter the live payment journal or banking connection.

## Google sign-in

Set `PORTAL_GOOGLE_CLIENT_ID`, `PORTAL_GOOGLE_CLIENT_SECRET`, and `PORTAL_PUBLIC_URL` in the root `.env` and restart. Register `http://localhost:8082/auth/google/callback` as the local Google redirect URI. Google sign-in uses state and a browser-bound cookie; only verified Google email identities are accepted. Existing password accounts are not automatically linked by matching email.

## Gateway boundary

The Portal sends a private `X-Portal-Service-Key` to `/api/gateway/internal/portal/purchases`. The old anonymous Gateway/Portal endpoints are blocked by Spring Security, including the old local-test-login bypass. Portal pages do not call the Gateway directly. The source of the old modules is retained to avoid deleting existing data models.

## Verification

```powershell
node --test developer-portal/test/portal.test.mjs
cd developer-portal
npm ci
node test/browser-smoke.mjs
```

The browser test uses installed Chrome and a running local stack. It creates an isolated test account/application and a sandbox purchase, visits all screens, captures desktop/mobile screenshots in `.local-data/screenshots`, and fails on browser errors. It leaves its test records for inspection.

## Current operational boundary

This version is usable for local sandbox testing. Live keys and live execution are deliberately locked: the existing Gateway's TCP code is not a certified APS funding/authentication implementation. API keys authenticate an integration; they cannot supply a customer's funding source or authorize a debit. Real payments require that approved bank integration, merchant provisioning, and settlement procedures. Google requires your registered client credentials. Business profile submission is recorded but does not automatically grant approval. There is no password-recovery email workflow or multi-user team invitation workflow in this version.

Webhook endpoints must use HTTPS on port 443 and resolve to public IPv4 addresses. Payloads are signed with HMAC-SHA256 over `timestamp.rawBody`; the header is `AfPay-Signature: t=...,v1=...`. Enforce timestamp freshness and event deduplication at the receiver. The persistent delivery queue retries five times and supports manual redelivery. Signing secrets reside in the local database, so protect database access and backups.
