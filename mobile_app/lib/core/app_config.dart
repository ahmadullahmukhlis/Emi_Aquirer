abstract final class AppConfig {
  static const authApiUrl = String.fromEnvironment(
    'AUTH_API_URL',
    defaultValue: 'http://10.60.76.77:8084/api/auth-service',
  );
  static const gatewayApiUrl = String.fromEnvironment(
    'GATEWAY_API_URL',
    defaultValue: 'http://10.60.76.77:8081/api/gateway',
  );
}
