# AfPay POS

Separate Flutter merchant POS application. It sends canonical purchase and terminal-heartbeat requests to the gateway using Dio and uses platform encrypted storage for login tokens.

Run after platform folders are generated:

```powershell
flutter create --platforms android,ios .
flutter pub get
flutter run --dart-define=GATEWAY_API_URL=https://your-gateway/api/auth-service
```

This is not an EMV kernel, card-reader, PIN-pad, or HSM SDK. Integrate the approved terminal vendor SDK and APS-certified payment stack for live card acceptance.
