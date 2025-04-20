import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class VisibilitySetting extends StatelessWidget {
  final bool letMembersSeeSavings;
  final ValueChanged<bool> onChanged;

  const VisibilitySetting({
    Key? key,
    required this.letMembersSeeSavings,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.visibility, color: primaryTwo),
      title: const Text(
        'Let Members See Each Other\'s Savings',
        style: TextStyle(color: Colors.black87),
      ),
      subtitle: const Text(
        'Enable or disable visibility of savings among members',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Switch(
        value: letMembersSeeSavings,
        onChanged: onChanged,
      ),
    );
  }
}
