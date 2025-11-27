// lib/providers/currency_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  String _currencyCode = 'UGX';
  String _currencySymbol = 'UGX';
  String _inviteCode = '';

  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  String get inviteCode => _inviteCode;

  void setCurrency(String code, String symbol) {
    _currencyCode = code;
    _currencySymbol = symbol;
    notifyListeners();
    
    // Also store in shared preferences for persistence
    _saveToStorage();
  }

  void setInviteCode(String code) {
    _inviteCode = code;
    notifyListeners();
    
    // Save invite code to storage
    _saveToStorage();
  }

  Future<void> loadCurrency() async {
    // Load from shared preferences
    final prefs = await SharedPreferences.getInstance();
    _currencyCode = prefs.getString('currency_code') ?? 'UGX';
    _currencySymbol = prefs.getString('currency_symbol') ?? 'UGX';
    _inviteCode = prefs.getString('invite_code') ?? '';
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', _currencyCode);
    await prefs.setString('currency_symbol', _currencySymbol);
    await prefs.setString('invite_code', _inviteCode);
  }

  // Optional: Clear invite code when needed
  void clearInviteCode() {
    _inviteCode = '';
    notifyListeners();
    _saveToStorage();
  }

  // Optional: Validate invite code format
  
}