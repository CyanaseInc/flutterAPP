import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class SendMessagesSetting extends StatelessWidget {
  final bool allowMessageSending;
  final ValueChanged<bool> onChanged;

  const SendMessagesSetting({
    Key? key,
    required this.allowMessageSending,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.message, color: Colors.blue),
      title: const Text(
        'Send Messages',
        style: TextStyle(color: Colors.black87),
      ),
      subtitle: const Text(
        'Allow or restrict members from sending messages',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Switch(
        value: allowMessageSending,
        onChanged: onChanged,
      ),
    );
  }
}
