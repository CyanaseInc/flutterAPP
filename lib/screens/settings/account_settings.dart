import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class AccountSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Account"),
        titleTextStyle: TextStyle(
          color: white, // Custom color
          fontSize: 24,
        ),
        backgroundColor: primaryTwo, // WhatsApp green color
        elevation: 0,
        iconTheme: IconThemeData(
          color: white, // Change the back arrow color to white
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Change Password Section
            _buildSectionHeader("Change Password"),
            _buildPasswordExpansionTile(),
            Divider(height: 1, indent: 72), // Add a divider

            // Next of Kin Section
            _buildSectionHeader("Next of Kin"),
            _buildNextOfKinExpansionTile(),
          ],
        ),
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      color: Colors.grey[100], // Light grey background
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // Change Password Expansion Tile
  Widget _buildPasswordExpansionTile() {
    return ExpansionTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryTwo.withOpacity(0.1), // Light green background
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.lock, color: primaryTwo), // WhatsApp green color
      ),
      title: Text(
        "Change Password",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        "Update your account password",
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildBottomBorderTextField(
                labelText: "Current Password",
                obscureText: true,
              ),
              SizedBox(height: 16),
              _buildBottomBorderTextField(
                labelText: "New Password",
                obscureText: true,
              ),
              SizedBox(height: 16),
              _buildBottomBorderTextField(
                labelText: "Confirm New Password",
                obscureText: true,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Handle password change
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo, // WhatsApp green color
                ),
                child: Text(
                  "change password",
                  style: TextStyle(fontSize: 16, color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Next of Kin Expansion Tile
  Widget _buildNextOfKinExpansionTile() {
    return ExpansionTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryTwo.withOpacity(0.1), // Light green background
          shape: BoxShape.circle,
        ),
        child:
            Icon(Icons.person_add, color: primaryTwo), // WhatsApp green color
      ),
      title: Text(
        "Add Next of Kin",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        "Add or update next of kin details",
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildBottomBorderTextField(
                labelText: "Full Name",
              ),
              SizedBox(height: 16),
              _buildBottomBorderTextField(
                labelText: "Email",
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              _buildBottomBorderTextField(
                labelText: "Phone Number",
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              _buildBottomBorderTextField(
                labelText: "National ID Number",
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Handle next of kin submission
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo, // WhatsApp green color
                ),
                child: Text(
                  "Save Next of Kin",
                  style: TextStyle(fontSize: 16, color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Reusable TextField with Bottom Border Only
  Widget _buildBottomBorderTextField({
    required String labelText,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.grey[600],
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: primaryTwo, // WhatsApp green color
            width: 2,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey[400]!, // Grey border color
            width: 1,
          ),
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }
}
