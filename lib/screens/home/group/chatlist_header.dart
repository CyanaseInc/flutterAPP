import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'pending_groups_screen.dart';
import 'pending_admin_loans.dart';
import 'pending_user_loans.dart';
import 'ongoing_user_loans.dart';

class SearchAndHeaderComponent extends StatelessWidget {
  final int pendingRequestCount;
  final List<Map<String, dynamic>> adminGroups;
  final List<Map<String, dynamic>> pendingAdminLoans;
  final List<Map<String, dynamic>> ongoingUserLoans;
  final List<Map<String, dynamic>> pendingUserLoans;
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
    required this.ongoingUserLoans,
    required this.pendingAdminLoans,
    required this.pendingUserLoans,
  }) : super(key: key);

  Widget _buildLoanBanner({
    required BuildContext context,
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return AnimatedOpacity(
      opacity: fadeAnimation?.value ?? 1.0,
      duration: const Duration(seconds: 1),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color,
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
              Icon(icon, color: white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count $title',
                  style: const TextStyle(
                    color: white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: white, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanBannerz({
    required BuildContext context,
    required String title,
    required int count,
    required IconData icon,
    required Widget screen,
  }) {
    return AnimatedOpacity(
      opacity: fadeAnimation?.value ?? 1.0,
      duration: const Duration(seconds: 1),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: primaryTwo, width: 1),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: primaryTwo, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count $title',
                  style: TextStyle(
                    color: primaryTwo,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: primaryTwo, size: 28),
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
        if (pendingRequestCount > 0)
          _buildLoanBanner(
            context: context,
            title:
                'Pending group request${pendingRequestCount == 1 ? '' : 's'}',
            count: pendingRequestCount,
            icon: Icons.person_add,
            color: primaryTwo,
            screen: PendingGroupsScreen(
              adminGroups: adminGroups,
              onRequestProcessed: onReloadChats,
            ),
          ),
        if (pendingAdminLoans.isNotEmpty)
          _buildLoanBanner(
            context: context,
            title:
                'Pending loan request${pendingAdminLoans.length == 1 ? '' : 's'}',
            count: pendingAdminLoans.length,
            icon: Icons.pending_actions,
            color: primaryDark,
            screen: PendingAdminLoansScreen(
              loans: pendingAdminLoans,
              onLoanProcessed: onReloadChats,
            ),
          ),
        if (pendingUserLoans.isNotEmpty)
          _buildLoanBannerz(
            context: context,
            title: 'My loan request${pendingUserLoans.length == 1 ? '' : 's'}',
            count: pendingUserLoans.length,
            icon: Icons.pending,
            screen: PendingUserLoansScreen(
              loans: pendingUserLoans,
              onLoanProcessed: onReloadChats,
            ),
          ),
        if (ongoingUserLoans.isNotEmpty)
          _buildLoanBanner(
            context: context,
            title: 'Ongoing loan${ongoingUserLoans.length == 1 ? '' : 's'}',
            count: ongoingUserLoans.length,
            icon: Icons.money,
            color: Colors.green,
            screen: OngoingLoansScreen(
              loans: ongoingUserLoans,
              onLoanUpdated: onReloadChats,
            ),
          ),
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
