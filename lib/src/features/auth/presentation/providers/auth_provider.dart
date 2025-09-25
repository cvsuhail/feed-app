import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider();

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
    _isValid = digitsOnly.length >= 10 && digitsOnly.length <= 12;
    notifyListeners();
  }

  Future<void> continueWithPhone() async {
    if (!_isValid || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }
}


