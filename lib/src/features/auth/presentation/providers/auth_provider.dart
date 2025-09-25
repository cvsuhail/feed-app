import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../home/presentation/pages/home_page.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          debugPrint('REQ ${options.method} ${options.uri} data=${options.data}');
          handler.next(options);
        },
        onResponse: (Response<dynamic> response, ResponseInterceptorHandler handler) {
          debugPrint('RES ${response.statusCode} ${response.requestOptions.uri} ${response.data}');
          handler.next(response);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) {
          debugPrint('ERR ${e.response?.statusCode} ${e.requestOptions.uri} ${e.response?.data}');
          handler.next(e);
        },
      ),
    );
  }

  static const String _baseUrl = 'https://frijo.noviindus.in/api/';
  static const String _tokenKey = 'access_token';
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      validateStatus: (int? status) => true,
      headers: const <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  final TextEditingController phoneController = TextEditingController();
  String _countryCode = '+91';
  bool _isValid = false;
  bool _isLoading = false;

  String get countryCode => _countryCode;
  bool get isValid => _isValid;
  bool get isLoading => _isLoading;

  void setCountryCode(String code) {
    _countryCode = code;
    notifyListeners();
  }

  void onPhoneChanged(String value) {
    final String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    _isValid = digitsOnly.length == 10;
    debugPrint('Phone changed: "$value" -> digits: "$digitsOnly" -> valid: $_isValid');
    notifyListeners();
  }

  Future<void> continueWithPhone(BuildContext context) async {
    debugPrint('continueWithPhone called - isValid: $_isValid, isLoading: $_isLoading');
    if (!_isValid || _isLoading) {
      debugPrint('Early return: isValid=$_isValid, isLoading=$_isLoading');
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final String raw = phoneController.text.trim();
      final String phoneDigits = raw.replaceAll(RegExp(r'\D'), '');
      final Map<String, dynamic> jsonBody = <String, dynamic>{
        'country_code': _countryCode,
        'phone': phoneDigits,
      };
      final Response<dynamic> response = await _dio.post(
        'otp_verified',
        data: jsonBody,
        options: Options(contentType: Headers.jsonContentType),
      );
      debugPrint('LOGIN_STATUS_CHECK: statusCode=${response.statusCode}, isSuccess=${response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300}');
      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        String message = 'Request failed (${response.statusCode}). Please try again.';
        final dynamic body = response.data;
        if (body is Map<String, dynamic>) {
          final dynamic direct = body['message'] ?? body['detail'] ?? body['error'] ?? body['errors'];
          if (direct is String && direct.trim().isNotEmpty) {
            message = direct.trim();
          } else {
            message = body.toString();
          }
        } else if (body is String && body.trim().isNotEmpty) {
          message = body.trim();
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              action: SnackBarAction(
                label: 'COPY',
                onPressed: () => Clipboard.setData(ClipboardData(text: message)),
              ),
            ),
          );
        }
        return;
      }
      final dynamic data = response.data;
      debugPrint('LOGIN_DATA: $data');
      String? accessToken;
      if (data is Map<String, dynamic>) {
        final dynamic topToken = data['token'];
        debugPrint('LOGIN_TOKEN_EXTRACTION: topToken=$topToken');
        if (topToken is String) {
          accessToken = topToken;
        } else if (topToken is Map<String, dynamic>) {
          accessToken = topToken['access'] as String?;
          debugPrint('LOGIN_ACCESS_TOKEN: $accessToken');
        }
        accessToken ??= data['access'] as String?;
        if (accessToken == null && data['data'] is Map<String, dynamic>) {
          final Map<String, dynamic> inner = data['data'] as Map<String, dynamic>;
          final dynamic innerToken = inner['token'];
          if (innerToken is String) {
            accessToken = innerToken;
          } else if (innerToken is Map<String, dynamic>) {
            accessToken = innerToken['access'] as String?;
          } else {
            accessToken = inner['access'] as String?;
          }
        }
      }
      debugPrint('LOGIN_FINAL_TOKEN: $accessToken');
      final bool statusOk = (data is Map<String, dynamic>) && (data['status'] == true);
      final bool hasPrivilege = (data is Map<String, dynamic>) && (data['privilage'] == true);
      final String? errorMessage = (data is Map<String, dynamic>) ? data['message'] as String? : null;
      
      debugPrint('LOGIN_VALIDATION: statusOk=$statusOk, hasPrivilege=$hasPrivilege, errorMessage=$errorMessage');
      
      // Check if login failed due to privilege issues
      if (statusOk && !hasPrivilege && errorMessage != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              action: SnackBarAction(
                label: 'COPY',
                onPressed: () => Clipboard.setData(ClipboardData(text: errorMessage)),
              ),
            ),
          );
        }
        return;
      }
      
      // Check for general login failure
      if (!statusOk || accessToken == null || accessToken.isEmpty) {
        if (context.mounted) {
          const String fallback = 'Login failed. Unable to retrieve access token.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(fallback),
              action: SnackBarAction(
                label: 'COPY',
                onPressed: () => Clipboard.setData(const ClipboardData(text: fallback)),
              ),
            ),
          );
        }
        return;
      }

      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, accessToken);
        debugPrint('LOGIN_TOKEN_STORED_SUCCESSFULLY: $accessToken');
      } on PlatformException catch (e) {
        debugPrint('LOGIN_PREFERENCES_ERROR: $e');
        // Soft-fail: continue navigation even if preferences are unavailable
      } catch (e) {
        debugPrint('LOGIN_PREFERENCES_UNKNOWN_ERROR: $e');
      }

      debugPrint('LOGIN_NAVIGATING_TO_HOME');
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            reverseTransitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
                  child: const HomePage(),
                ),
              );
            },
          ),
        );
      }
    } on DioException catch (e) {
      String message = 'Network error, please try again';
      final int? code = e.response?.statusCode;
      final dynamic body = e.response?.data;
      
      debugPrint('DioException type: ${e.type}, message: ${e.message}');
      
      if (body is Map<String, dynamic>) {
        final dynamic direct = body['message'] ?? body['detail'] ?? body['error'] ?? body['errors'];
        if (direct is String && direct.trim().isNotEmpty) {
          message = direct.trim();
        } else {
          message = body.toString();
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timed out. The server may be slow. Please try again.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        message = 'Server took too long to respond. Please try again.';
      } else if (e.type == DioExceptionType.sendTimeout) {
        message = 'Request timed out while sending data. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Cannot reach server. Check your internet connection.';
      } else if (e.type == DioExceptionType.badCertificate) {
        message = 'Secure connection failed (certificate error).';
      } else if (e.type == DioExceptionType.cancel) {
        message = 'Request was cancelled. Please try again.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }
      
      if (code == 400 || code == 401) {
        // Prefer a friendly, explicit invalid credentials message
        message = message == 'Network error, please try again'
            ? 'Invalid credentials. Please check your number and try again.'
            : message;
      }
      
      debugPrint('Showing error message: $message');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'COPY',
              onPressed: () => Clipboard.setData(ClipboardData(text: message)),
            ),
          ),
        );
      }
    } catch (e, s) {
      debugPrint('LOGIN_UNEXPECTED_ERROR: $e\n$s');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }
}


