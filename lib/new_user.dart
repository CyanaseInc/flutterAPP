import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cyanase/screens/home/group/new_group.dart';

class NewUserScreen extends StatefulWidget {
  @override
  _NewUserScreenState createState() => _NewUserScreenState();
}

class _NewUserScreenState extends State<NewUserScreen> {
  // Function to handle the "Create Group" button press
  void _handleCreateGroup() {
    // Navigate directly to the NewGroupScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewGroupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SvgPicture.asset(
                  'assets/images/new_user.svg', // Ensure this path points to your SVG file
                  fit: BoxFit.contain,
                  color: primaryColor,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Welcome to Cyanase groups",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Collaborate with your friends and family by creating a group to save and invest together effortlessly.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: primaryTwo, // Background color when enabled
                disabledBackgroundColor:
                    primaryTwo, // Background color when disabled
              ),
              onPressed:
                  _handleCreateGroup, // Directly navigate on button press
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    color: primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Create group",
                    style: TextStyle(fontSize: 16, color: primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
