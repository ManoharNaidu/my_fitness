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
    if (fromDefine.isNotEmpty) return fromDefine;

    const hostedApi = 'https://my-fitness-api-k2jv.onrender.com/v1';
    if (kIsWeb) return hostedApi;
    if (isAndroidPlatform) return hostedApi;
    return hostedApi;
  }

  static const String demoEmail = 'demo@myfitness.app';
  static const String demoPassword = 'demo1234';
}
