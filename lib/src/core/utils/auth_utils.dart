import 'package:shared_preferences/shared_preferences.dart';

class AuthUtils {
  static const String _tokenKey = 'access_token';
  
  /// Gets the stored access token from SharedPreferences
  static Future<String?> getAccessToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Checks if user is authenticated (has valid token)
  static Future<bool> isAuthenticated() async {
    final String? token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Clears the stored token (for logout)
  static Future<void> clearToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      // Handle error silently
    }
  }
}
