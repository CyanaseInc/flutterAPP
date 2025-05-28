import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'pending_requests.dart';

class PendingGroupsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> adminGroups;
  final VoidCallback onRequestProcessed;

  const PendingGroupsScreen({
    super.key,
    required this.adminGroups,
    required this.onRequestProcessed,
  });

  @override
  _PendingGroupsScreenState createState() => _PendingGroupsScreenState();
}

class _PendingGroupsScreenState extends State<PendingGroupsScreen> {
  late List<Map<String, dynamic>> _adminGroups;

  @override
  void initState() {
    super.initState();
    _adminGroups = List.from(widget.adminGroups);
  }

  void _updatePendingCount(String groupId) {
    setState(() {
      final index =
          _adminGroups.indexWhere((g) => g['group_id'].toString() == groupId);
      if (index != -1) {
        final newCount = _adminGroups[index]['pending_count'] - 1;
        if (newCount > 0) {
          _adminGroups[index] = {
            ..._adminGroups[index],
            'pending_count': newCount,
          };
        } else {
          _adminGroups.removeAt(index);
        }
        debugPrint('Updated adminGroups: $_adminGroups');
      }
    });
    widget.onRequestProcessed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Join Group Requests',
          style: TextStyle(color: white, fontSize: 18),
        ),
        backgroundColor: primaryTwo,
        iconTheme: const IconThemeData(color: white),
      ),
      body: _adminGroups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No groups with pending requests',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _adminGroups.length,
              itemBuilder: (context, index) {
                final group = _adminGroups[index];
                final groupId = group['group_id'].toString();
                final groupName = group['group_name'] as String;
                final pendingCount = group['pending_count'] as int;

                return Card(
                  elevation: 2,
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: primaryColor,
                      child: Text(
                        groupName.isNotEmpty ? groupName[0].toUpperCase() : 'G',
                        style: const TextStyle(
                          color: white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      groupName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                        '$pendingCount pending request${pendingCount == 1 ? '' : 's'}'),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: primaryTwo,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PendingRequestsScreen(
                            groupId: int.parse(groupId),
                            groupName: groupName,
                            onRequestProcessed: () =>
                                _updatePendingCount(groupId),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
