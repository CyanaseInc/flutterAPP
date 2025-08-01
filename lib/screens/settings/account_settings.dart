import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'set_passcode_screen.dart';

class AccountSettingsPage extends StatefulWidget {
  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  String? name;
  String? email;
  String? token;
  String? picture;
  final _formKey = GlobalKey<FormState>();
  final _nextOfKinFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isNextOfKinLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Next of Kin Controllers
  final TextEditingController _kinNameController = TextEditingController();
  final TextEditingController _kinEmailController = TextEditingController();
  final TextEditingController _kinPhoneController = TextEditingController();
  final TextEditingController _kinNationalIdController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    getProfile();
    _fetchNextOfKin();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _kinNameController.dispose();
    _kinEmailController.dispose();
    _kinPhoneController.dispose();
    _kinNationalIdController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 5) {
      return 'Password must be at least 5 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  void getProfile() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final userProfile = await db.query('profile', limit: 1);

    setState(() {
      if (userProfile.isNotEmpty) {
        name = userProfile.first['name'] as String? ?? 'User';
        email = userProfile.first['email'] as String? ?? 'Not set';
        token = userProfile.first['token'] as String? ?? '';
        picture = userProfile.first['profile_pic'] as String? ?? '';
      } else {
        name = 'User';
        email = 'Not set';
        token = '';
      }
    });
  }

  Future<void> _handlePasswordChange() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication error. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = {
        "old_password": _currentPasswordController.text,
        "new_password": _newPasswordController.text
      };

      final response = await ApiService.changeUserPassword(token!, userData);
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Clear the form
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      
      String errorMessage = 'Failed to change password. Please try again.';

      if (e.toString().contains('401')) {
        errorMessage = 'Current password is incorrect.';
      } else if (e.toString().contains('400')) {
        errorMessage = 'Invalid password format.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNextOfKin() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final userProfile = await db.query('profile', limit: 1);
    final mytoken = userProfile.first['token'] as String? ?? '';
    if (mytoken.isEmpty) {
      return;
    }
    try {
      final response = await ApiService.getNextOfKin(mytoken);

      if (response != null) {
        setState(() {
          // Combine first and last name
          _kinNameController.text =
              '${response['kin_first_name'] ?? ''} ${response['kin_last_name'] ?? ''}'
                  .trim();

          // Handle email
          _kinEmailController.text = response['kin_email'] ?? '';

          // Format phone number to ensure it's displayed correctly
          String phone = response['kin_phone']?.toString() ?? '';
          if (phone.isNotEmpty && !phone.startsWith('+')) {
            phone = '+$phone';
          }
          _kinPhoneController.text = phone;

          // Convert Next_of_kin_id to string safely
          _kinNationalIdController.text =
              response['Next_of_kin_id']?.toString() ?? '';
        });
      }
    } catch (e) {
      
    }
  }

  Future<void> _handleNextOfKinSave() async {
    if (!_nextOfKinFormKey.currentState!.validate()) {
      return;
    }

    if (token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication error. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isNextOfKinLoading = true;
    });

    try {
      // Split the full name into first and last name
      final nameParts = _kinNameController.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final nextOfKinData = {
        "first_name": firstName,
        "last_name": lastName,
        "email": _kinEmailController.text.trim(),
        "phone": _kinPhoneController.text.trim().replaceAll('+', ''),
        "national_id": _kinNationalIdController.text.trim()
      };

      final response = await ApiService.saveNextOfKin(token!, nextOfKinData);

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Next of Kin details saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                response['message'] ?? 'Failed to save Next of Kin details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to save Next of Kin details. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isNextOfKinLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Account"),
        titleTextStyle: TextStyle(
          color: white, // Custom color
          fontSize: 24,
        ),
        backgroundColor: primaryTwo,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: white),
          onPressed: () => Navigator.pop(context),
        ),
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
            Divider(height: 1, indent: 72),
            // Add a divider
            _buildSettingsOption(
              context,
              icon: Icons.pin,
              title: "Passcode",
              subtitle: "Set a passcode for quick login",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SetPasscodeScreen(), // Replace with actual email
                  ),
                );
              },
            ),
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
          color: primaryTwo.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.lock, color: primaryTwo),
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildPasswordTextField(
                  controller: _currentPasswordController,
                  labelText: "Current Password",
                  obscureText: !_showCurrentPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _showCurrentPassword = !_showCurrentPassword;
                    });
                  },
                  validator: _validatePassword,
                ),
                SizedBox(height: 16),
                _buildPasswordTextField(
                  controller: _newPasswordController,
                  labelText: "New Password",
                  obscureText: !_showNewPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                  validator: _validatePassword,
                ),
                SizedBox(height: 16),
                _buildPasswordTextField(
                  controller: _confirmPasswordController,
                  labelText: "Confirm New Password",
                  obscureText: !_showConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                  validator: _validateConfirmPassword,
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handlePasswordChange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTwo,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          )
                        : Text(
                            "Change Password",
                            style: TextStyle(fontSize: 16, color: primaryColor),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.grey[600],
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: primaryTwo,
            width: 2,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey[400]!,
            width: 1,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      obscureText: obscureText,
      validator: validator,
    );
  }

  // Next of Kin Expansion Tile
  Widget _buildNextOfKinExpansionTile() {
    return ExpansionTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryTwo.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person_add, color: primaryTwo),
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
          child: Form(
            key: _nextOfKinFormKey,
            child: Column(
              children: [
                _buildBottomBorderTextField(
                  controller: _kinNameController,
                  labelText: "Full Name",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildBottomBorderTextField(
                  controller: _kinEmailController,
                  labelText: "Email",
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                SizedBox(height: 16),
                _buildBottomBorderTextField(
                  controller: _kinPhoneController,
                  labelText: "Phone Number",
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
                SizedBox(height: 16),
                _buildBottomBorderTextField(
                  controller: _kinNationalIdController,
                  labelText: "National ID Number",
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isNextOfKinLoading ? null : _handleNextOfKinSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTwo,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isNextOfKinLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          )
                        : Text(
                            "Save Next of Kin",
                            style: TextStyle(fontSize: 16, color: primaryColor),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Update the _buildBottomBorderTextField to include validation
  Widget _buildBottomBorderTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.grey[600],
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: primaryTwo,
            width: 2,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey[400]!,
            width: 1,
          ),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }

  Widget _buildSettingsOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryTwo.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: primaryTwo),
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
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
