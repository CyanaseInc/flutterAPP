import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart'; // Import your theme

class HelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Help"),
        titleTextStyle: TextStyle(
          color: white, // Custom color
          fontSize: 24,
        ),
        backgroundColor: primaryTwo, // WhatsApp green color
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Us Section
            _buildSectionHeader("Contact Us"),
            _buildContactInfo(
              "For more information or inquiries, please reach us. We are available 24/7.",
            ),
            SizedBox(height: 16),

            // Call Us Section
            _buildContactOption(
              icon: Icons.phone,
              title: "Call Us",
              subtitle: "+256705640852",
              onTap: () {
                // Handle call action
              },
            ),
            Divider(height: 1, indent: 72), // Add a divider

            // WhatsApp Us Section
            _buildContactOption(
              icon: Icons.message,
              title: "WhatsApp Us",
              subtitle: "+256705640852",
              onTap: () {
                // Handle WhatsApp action
              },
            ),
            Divider(height: 1, indent: 72), // Add a divider

            // Email Us Section
            _buildContactOption(
              icon: Icons.email,
              title: "Email Us",
              subtitle: "support@cyanase.com",
              onTap: () {
                // Handle email action
              },
            ),
            Divider(height: 1, indent: 72), // Add a divider

            // DM Us on Social Media Section
            _buildContactOption(
              icon: Icons.thumb_up,
              title: "DM Us on Social Media",
              subtitle: "Cyanase (Facebook, Twitter, LinkedIn)",
              onTap: () {
                // Handle social media action
              },
            ),
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

  // Contact Information Text
  Widget _buildContactInfo(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // Reusable Contact Option Widget
  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: primaryTwo, // Light green background
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: primaryTwo), // WhatsApp green color
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
