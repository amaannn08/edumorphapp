/// API configuration — single source of truth for the backend URL.
///
/// Set at compile time with:
///   flutter run --dart-define=BACKEND_URL=https://api.yourdomain.com
///
/// Or for local development, just change [_devUrl] below.
class ApiConfig {
  ApiConfig._();

  /// The backend URL injected via --dart-define.
  /// Falls back to the local dev server if not provided.
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: _devUrl,
  );

  /// ─────────────────────────────────────────────────────
  /// 👇 PUT YOUR BACKEND URL HERE
  /// ─────────────────────────────────────────────────────
  static const String _devUrl = 'http://YOUR_EC2_IP:3000';
  //
  // Examples:
  //   'http://localhost:3000'           ← web browser / iOS sim
  //   'http://10.0.2.2:3000'           ← Android emulator (maps to localhost)
  //   'http://192.168.1.42:3000'       ← physical phone on same WiFi
  //   'https://api.shikshaverse.com'   ← production

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
