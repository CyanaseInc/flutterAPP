import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';
import './image_picker_helper.dart';
import 'test.dart'; // Import the helper file
import 'dart:io'; // For File handling

class GroupHeader extends StatefulWidget {
  final String groupName;
  final String profilePic;

  const GroupHeader({
    Key? key,
    required this.groupName,
    required this.profilePic,
  }) : super(key: key);

  @override
  _GroupHeaderState createState() => _GroupHeaderState();
}

class _GroupHeaderState extends State<GroupHeader> {
  File? _profilePicFile; // To hold the profile picture

  // Function to handle profile picture update
  void _updateProfilePic(File image) {
    setState(() {
      _profilePicFile = image; // Update the profile picture
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Ensures the container takes full width
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Column(
        children: [
          // Top Row with Menu Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Vertical Three Dots Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'Add Members') {
                    // Handle "Add Members" action
                  } else if (value == 'Change Group Name') {
                    // Handle "Change Group Name" action
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Add Members',
                    child: Text('Add Members'),
                  ),
                  const PopupMenuItem(
                    value: 'Change Group Name',
                    child: Text('Change Group Name'),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),

          // Profile Picture (Center of the page)
          GestureDetector(
            onTap: () {
              // Show bottom sheet with options when the profile picture is clicked
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.edit),
                          title: Text("Edit Profile Picture"),
                          onTap: () {
                            // Handle "Edit Profile Picture" action
                            Navigator.pop(context); // Close the bottom sheet
                            ImagePickerHelper.pickImageFromCamera(
                                context, _updateProfilePic);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.photo_camera),
                          title: Text("Change Profile Picture"),
                          onTap: () {
                            // Handle "Change Profile Picture" action
                            Navigator.pop(context); // Close the bottom sheet
                            ImagePickerHelper.pickImageFromGallery(
                                context, _updateProfilePic);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.delete),
                          title: Text("Remove Profile Picture"),
                          onTap: () {
                            // Handle "Remove Profile Picture" action
                            Navigator.pop(context); // Close the bottom sheet
                            setState(() {
                              _profilePicFile =
                                  null; // Remove the profile picture
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryTwo, // Change the color of the border as needed
                  width: 2, // Adjust the width of the border
                ),
              ),
              child: CircleAvatar(
                backgroundImage: _profilePicFile != null
                    ? FileImage(
                        _profilePicFile!) // Show the selected profile picture
                    : AssetImage(widget.profilePic)
                        as ImageProvider, // Default image if no profile is set
                radius: 50,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Group Name
          Text(
            widget.groupName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const Text(
            '18 members',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Group Description
          const Text(
            'This is a family saving group for us all',
            style: TextStyle(
              color: primaryTwo,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDepositButton(context),
              _buildRequestLoanButton(),
              _buildWithdrawButton(),
            ],
          ),
        ],
      ),
    );
  }

  // Deposit Button: ElevatedButton style
  Widget _buildDepositButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Testa(),
          ),
        );
        // Add Deposit functionality here
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTwo, // Background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding
      ),
      child: const Text(
        'Deposit', // Button label
        style: TextStyle(
            color: Colors.white, // Text color
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  // Request Loan Button: ElevatedButton style
  Widget _buildRequestLoanButton() {
    return ElevatedButton(
      onPressed: () {
        // Implement action for requesting a loan
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: const Text(
        'Get Loan',
        style: TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Withdraw Button: OutlinedButton style with border
  Widget _buildWithdrawButton() {
    return OutlinedButton(
      onPressed: () {
        // Implement action for withdrawing
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: primaryTwo), // Border color (red for emphasis)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding
      ),
      child: const Text(
        'Withdraw', // Button label
        style: const TextStyle(
            color: primaryTwo, // Text color matches the border
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
