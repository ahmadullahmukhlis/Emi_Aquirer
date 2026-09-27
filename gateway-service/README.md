# Gateway service

This is a separate Spring Boot service from `authService`, running on port `8081` at `/api/gateway`.

It provides locally functional **APS acquirer-only** transaction endpoints without a SmartVista connection:

- `POST /api/gateway/api/v1/mobile/transactions/{BALANCE_INQUIRY|PURCHASE|PAYMENT_INFO|SAVE_PAYMENT|WALLET_TO_CARD|CARD_TO_WALLET|CARD_TO_CARD|CARD_TITLE_FETCH|CROSS_CURRENCY|REVERSAL}`
- `POST /api/gateway/api/v1/pos/transactions/{BALANCE_INQUIRY|PURCHASE|CASH_IN|CASH_OUT|PAYMENT_INFO|SAVE_PAYMENT|CARD_TO_CARD|CARD_TITLE_FETCH|REVERSAL}`
- `POST /api/gateway/api/v1/settlements/{merchantId}/{YYYY-MM-DD}`

The local adapter maps the canonical JSON request to ISO-8583 fields (MTI, processing code, amount, STAN, terminal, merchant, currency, channel, response code) and returns a deterministic APS test response. It sends no payment data outside the process.

The persistent path journals idempotent requests locally. Before production, require JWT/role enforcement, use a secret-managed service identity, and replace `LocalIso8583Switch` with the certified SmartVista/HSM/mTLS adapter. Never treat the simulator as a payment switch. See `../APS_CERTIFICATION_TODO.md` for every APS parameter that is intentionally configurable rather than guessed.
