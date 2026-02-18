import 'package:flutter/foundation.dart';

import 'platform_stub.dart' if (dart.library.io) 'platform_io.dart';

class AppConfig {
  static bool? _enableApiOverride;

  static void setEnableApiOverride(bool? value) {
    _enableApiOverride = value;
  }

  static bool get enableApi =>
      _enableApiOverride ??
      const bool.fromEnvironment('ENABLE_API', defaultValue: true);

  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return _normalizeApiBaseUrl(fromDefine);

    const hostedApi = 'https://my-fitness-api-k2jv.onrender.com/v1';
    if (kIsWeb) return _normalizeApiBaseUrl(hostedApi);
    if (isAndroidPlatform) return _normalizeApiBaseUrl(hostedApi);
    return _normalizeApiBaseUrl(hostedApi);
  }

  static String _normalizeApiBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'https://my-fitness-api-k2jv.onrender.com/v1';

    final withoutTrailingSlash = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;

    if (withoutTrailingSlash.endsWith('/v1')) return withoutTrailingSlash;
    return '$withoutTrailingSlash/v1';
  }

  static const String demoEmail = 'demo@myfitness.app';
  static const String demoPassword = 'demo1234';
}
