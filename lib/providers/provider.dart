// lib/providers/provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CurrencyProvider with ChangeNotifier {
  String _currencyCode = 'UGX';
  String _currencySymbol = 'UGX';
  String _inviteCode = '';
  
  // Financial data
  Map<String, dynamic>? _financialSummary;
  Map<String, dynamic>? _bonusBreakdown;
  Map<String, dynamic>? _recentActivity;

  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  String get inviteCode => _inviteCode;
  
  // Financial data getters
  Map<String, dynamic>? get financialSummary => _financialSummary;
  Map<String, dynamic>? get bonusBreakdown => _bonusBreakdown;
  Map<String, dynamic>? get recentActivity => _recentActivity;
  
  // Convenience getters for financial data
  double get currentBalance {
    if (_financialSummary != null && _financialSummary!.containsKey('current_balance')) {
      final value = _financialSummary!['current_balance'];
     
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
  
  double get totalEarnings {
    if (_financialSummary != null && _financialSummary!.containsKey('total_earnings')) {
      final value = _financialSummary!['total_earnings'];
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
  
  double get totalWithdrawals {
    if (_financialSummary != null && _financialSummary!.containsKey('total_withdrawals')) {
      final value = _financialSummary!['total_withdrawals'];
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
  
  int get totalInvitations {
    if (_financialSummary != null && _financialSummary!.containsKey('total_invitations')) {
      final value = _financialSummary!['total_invitations'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
    }
    return 0;
  }
  
  String? get financialCurrency => _financialSummary?['currency'] as String?;
  String? get financialCurrencySymbol => _financialSummary?['currency_symbol'] as String?;

  void setCurrency(String code, String symbol) {
    _currencyCode = code;
    _currencySymbol = symbol;
    notifyListeners();
    _saveToStorage();
  }

  void setInviteCode(String code) {
    _inviteCode = code;
    notifyListeners();
    _saveToStorage();
  }
  
  // Method to set all financial data at once
  void setFinancialData({
    Map<String, dynamic>? financialSummary,
    Map<String, dynamic>? bonusBreakdown,
    Map<String, dynamic>? recentActivity,
  }) {
    // Convert generic maps to Map<String, dynamic>
    _financialSummary = _convertToTypedMap(financialSummary);
    _bonusBreakdown = _convertToTypedMap(bonusBreakdown);
    _recentActivity = _convertToTypedMap(recentActivity);
    
    notifyListeners();
    _saveFinancialDataToStorage();
  }
  
  // Helper method to convert Map<dynamic, dynamic> to Map<String, dynamic>
  Map<String, dynamic>? _convertToTypedMap(Map<dynamic, dynamic>? map) {
    if (map == null) return null;
    
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      final keyString = key.toString();
      
      // Recursively convert nested maps
      if (value is Map) {
        result[keyString] = _convertToTypedMap(Map<dynamic, dynamic>.from(value));
      } 
      // Handle lists that might contain maps
      else if (value is List) {
        result[keyString] = value.map((item) {
          if (item is Map) {
            return _convertToTypedMap(Map<dynamic, dynamic>.from(item));
          }
          return item;
        }).toList();
      }
      else {
        result[keyString] = value;
      }
    });
    
    return result;
  }
  
  // Method to update specific financial data
  void updateFinancialSummary(Map<dynamic, dynamic> summary) {
    _financialSummary = _convertToTypedMap(summary);
    notifyListeners();
    _saveFinancialDataToStorage();
  }
  
  void updateBonusBreakdown(Map<dynamic, dynamic> breakdown) {
    _bonusBreakdown = _convertToTypedMap(breakdown);
    notifyListeners();
    _saveFinancialDataToStorage();
  }
  
  void updateRecentActivity(Map<dynamic, dynamic> activity) {
    _recentActivity = _convertToTypedMap(activity);
    notifyListeners();
    _saveFinancialDataToStorage();
  }
  
  // Method to clear financial data (e.g., on logout)
  void clearFinancialData() {
    _financialSummary = null;
    _bonusBreakdown = null;
    _recentActivity = null;
    notifyListeners();
    _clearFinancialDataFromStorage();
  }

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currencyCode = prefs.getString('currency_code') ?? 'UGX';
    _currencySymbol = prefs.getString('currency_symbol') ?? 'UGX';
    _inviteCode = prefs.getString('invite_code') ?? '';
    
    await _loadFinancialDataFromStorage(prefs);
    notifyListeners();
  }
  
  Future<void> _saveFinancialDataToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save financial summary
    if (_financialSummary != null) {
      await prefs.setString('financial_summary', jsonEncode(_financialSummary));
    } else {
      await prefs.remove('financial_summary');
    }
    
    // Save bonus breakdown
    if (_bonusBreakdown != null) {
      await prefs.setString('bonus_breakdown', jsonEncode(_bonusBreakdown));
    } else {
      await prefs.remove('bonus_breakdown');
    }
    
    // Save recent activity
    if (_recentActivity != null) {
      await prefs.setString('recent_activity', jsonEncode(_recentActivity));
    } else {
      await prefs.remove('recent_activity');
    }
  }
  
  Future<void> _loadFinancialDataFromStorage(SharedPreferences prefs) async {
    try {
      // Load financial summary
      final summaryString = prefs.getString('financial_summary');
      if (summaryString != null && summaryString.isNotEmpty) {
        final decoded = jsonDecode(summaryString);
        if (decoded is Map) {
          _financialSummary = _convertToTypedMap(Map<dynamic, dynamic>.from(decoded));
        }
      }
      
      // Load bonus breakdown
      final breakdownString = prefs.getString('bonus_breakdown');
      if (breakdownString != null && breakdownString.isNotEmpty) {
        final decoded = jsonDecode(breakdownString);
        if (decoded is Map) {
          _bonusBreakdown = _convertToTypedMap(Map<dynamic, dynamic>.from(decoded));
        }
      }
      
      // Load recent activity
      final activityString = prefs.getString('recent_activity');
      if (activityString != null && activityString.isNotEmpty) {
        final decoded = jsonDecode(activityString);
        if (decoded is Map) {
          _recentActivity = _convertToTypedMap(Map<dynamic, dynamic>.from(decoded));
        }
      }
    } catch (e) {
      print('Error loading financial data from storage: $e');
      _clearFinancialDataFromStorage();
    }
  }
  
  Future<void> _clearFinancialDataFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('financial_summary');
    await prefs.remove('bonus_breakdown');
    await prefs.remove('recent_activity');
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

  // Optional: Clear all data (for logout)
  void clearAllData() {
    _currencyCode = 'UGX';
    _currencySymbol = 'UGX';
    _inviteCode = '';
    _financialSummary = null;
    _bonusBreakdown = null;
    _recentActivity = null;
    notifyListeners();
    
    // Clear from storage
    SharedPreferences.getInstance().then((prefs) async {
      await prefs.remove('currency_code');
      await prefs.remove('currency_symbol');
      await prefs.remove('invite_code');
      await _clearFinancialDataFromStorage();
    });
  }
  
  // Helper method for debugging

}