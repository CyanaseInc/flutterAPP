import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'pending_groups_screen.dart';

class SearchAndHeaderComponent extends StatelessWidget {
  final int pendingRequestCount;
  final List<Map<String, dynamic>> adminGroups;
  final TextEditingController searchController;
  final Animation<double>? fadeAnimation;
  final Function(String) onFilterChats;
  final VoidCallback onReloadChats;

  const SearchAndHeaderComponent({
    Key? key,
    required this.pendingRequestCount,
    required this.adminGroups,
    required this.searchController,
    required this.fadeAnimation,
    required this.onFilterChats,
    required this.onReloadChats,
  }) : super(key: key);

  Widget _buildPendingBanner(BuildContext context) {
    return AnimatedOpacity(
      opacity: fadeAnimation?.value ?? 1.0,
      duration: const Duration(seconds: 1),
      child: InkWell(
        onTap: () {
          if (adminGroups.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PendingGroupsScreen(
                  adminGroups: adminGroups,
                  onRequestProcessed: onReloadChats,
                ),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: primaryTwo,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.person_add, color: white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$pendingRequestCount pending group request${pendingRequestCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: white, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        if (pendingRequestCount > 0) _buildPendingBanner(context),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search groups...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: onFilterChats,
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
