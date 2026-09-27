# AfPay Gateway Mobile

Flutter mobile client for the APS/SmartVista gateway. It provides authenticated access to card-to-card, bill payment, cash-out, and balance inquiry flows through the canonical gateway API.

## Run

Generate native shells once on a workstation with a healthy Flutter SDK:

```powershell
flutter create --platforms android,ios .
flutter pub get
flutter run --dart-define=GATEWAY_API_URL=http://10.0.2.2:8080/api/auth-service
```

For a physical phone, replace `10.0.2.2` with the TLS-enabled gateway host. Production must use HTTPS, device/app attestation, token storage in platform secure storage, and an approved mobile-payment certification path.

## Safety boundaries

The app never collects or persists a PIN, CVV/CVC, full PAN, track data, or EMV data. It sends a card token and canonical request only. SmartVista host connectivity, HSM operations, terminal certificates, and payment-key loading are server-side adapters that require APS/acquirer certification and must not be implemented in the app.
