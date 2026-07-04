class ApiConfig {
  ApiConfig._();

  /// Android Emulator: http://10.0.2.2:3000/api
  /// Physical device: use --dart-define=API_BASE_URL=http://YOUR_PC_IP:3000/api
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
}
