import 'package:flutter/material.dart';
// Ensure this matches your actual file name

class FlutterPay extends StatefulWidget {
  final String? name;
  final double? amount;
  final String? email;
  final dynamic data; //formData
  final String? currency; // Made email nullable since it wasn't required before

  const FlutterPay(
      {super.key, // Modern Flutter key convention
      this.name,
      this.email,
      this.amount,
      this.data,
      this.currency});

  @override
  _FlutterPayState createState() => _FlutterPayState();
}

class _FlutterPayState extends State<FlutterPay>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;

  Future<void> _checkOut() async {
    try {
      // final dbHelper = DatabaseHelper();
      // final db = await dbHelper.database;
      // final userProfile = await db.query('profile', limit: 1);
    } catch (e) {
      print('Error during initialization: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () => print('hi'), child: const Text("flutterwave"));
  }
}
