import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiOrigin => dotenv.env['API_ORIGIN'] ?? 'https://devapi.newbalanpharmacy.com';
  static String get apiPrefix => dotenv.env['API_PREFIX'] ?? '/api/v1';
  static String get baseUrl => '$apiOrigin$apiPrefix';
  static String get shopCity => dotenv.env['SHOP_CITY'] ?? 'Palakkad';
  static String get shopState => dotenv.env['SHOP_STATE'] ?? 'Kerala';
  static String get shopPincode => dotenv.env['SHOP_PINCODE'] ?? '678001';
}
