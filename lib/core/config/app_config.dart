import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads runtime config from `.env`. Each getter checks the canonical Flutter
/// variable name first, then falls back to the `VITE_*` name the marketing
/// site uses, so a single shared `.env` can power both apps. Hardcoded
/// defaults are the production values — the app remains usable even if
/// `.env` is missing or empty.
class AppConfig {
  static String _read(List<String> keys, String fallback) {
    for (final k in keys) {
      final v = dotenv.env[k];
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return fallback;
  }

  static String get apiOrigin => _read(
        ['API_ORIGIN', 'VITE_API_BASE_URL'],
        'https://devapi.newbalanpharmacy.com',
      );
  static String get apiPrefix => _read(
        ['API_PREFIX', 'VITE_API_PREFIX'],
        '/api/v1',
      );
  static String get baseUrl => '$apiOrigin$apiPrefix';

  static String get shopCity => _read(['SHOP_CITY'], 'Thoothukudi');
  static String get shopState => _read(['SHOP_STATE'], 'Tamil Nadu');
  static String get shopPincode => _read(['SHOP_PINCODE'], '628001');
}
