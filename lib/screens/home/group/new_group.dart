import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/theme/theme.dart';
import 'create_new_group_details.dart'; // Import GroupDetailsScreen
import '../../../helpers/hash_numbers.dart'; // Import fetchAndHashContacts and getRegisteredContacts

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  _NewGroupScreenState createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> selectedContacts = [];
  bool isLoading = true;
  bool isRefreshing = false; // Track refresh state separately

  @override
  void initState() {
    super.initState();
    _loadContacts(); // Load contacts initially
  }

  Future<void> _loadContacts() async {
    setState(() {
      isLoading = true; // Show loader
    });

    final dbHelper = DatabaseHelper();
    final existingContacts = await dbHelper.getContacts();

    if (existingContacts.isEmpty) {
      await _fetchAndSyncContacts();
    } else {
      setState(() {
        contacts = existingContacts
            .map((contact) => {
                  'id': contact['id'],
                  'user_id': contact['user_id'],
                  'name': contact['name'],
                  'phone': contact['phone_number'],
                  'profilePic': contact['profilePic'] ?? '',
                  'is_registered': contact['is_registered'] == 1,
                })
            .toList();
        isLoading = false;
      });
    }
  }

  Future<void> _fetchAndSyncContacts({bool isManualRefresh = false}) async {
    if (isManualRefresh) {
      setState(() {
        isRefreshing = true; // Indicate refreshing is in progress
      });
      // Show a loading dialog for manual refresh
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              Loader(),
              const SizedBox(width: 16),
              Text(
                'Refreshing contacts...',
                style: TextStyle(color: primaryTwo),
              ),
            ],
          ),
        ),
      );
    } else {
      setState(() {
        isLoading = true; // Show main loader for initial fetch
      });
    }

    try {
      final fetchedContacts = await fetchAndHashContacts();

      final registeredContacts = await getRegisteredContacts(fetchedContacts);

      // Deduplicate contacts based on phone number
      final uniqueContacts = <String, Map<String, dynamic>>{};
      for (var contact in registeredContacts) {
        final phone = contact['phone'] as String? ?? '';
        if (phone.isNotEmpty && !uniqueContacts.containsKey(phone)) {
          uniqueContacts[phone] = contact;
        }
      }

      setState(() {
        contacts = uniqueContacts.values.toList();
        isLoading = false;
        if (isManualRefresh) isRefreshing = false;
      });

      if (isManualRefresh) {
        Navigator.pop(context); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contacts refreshed successfully!'),
            backgroundColor: primaryTwo,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        if (isManualRefresh) isRefreshing = false;
      });
      if (isManualRefresh) {
        Navigator.pop(context); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh contacts: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "New Group",
          style: TextStyle(color: white, fontSize: 20),
        ),
        backgroundColor: primaryTwo,
        iconTheme: const IconThemeData(color: white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ContactSearchDelegate(
                  contacts,
                  (selected) {
                    setState(() {
                      selectedContacts = selected;
                    });
                  },
                  selectedContacts,
                ),
              );
            },
          ),
          IconButton(
            icon: isRefreshing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: isRefreshing
                ? null
                : () async {
                    await _fetchAndSyncContacts(isManualRefresh: true);
                  },
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Loader(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading contacts...',
                    style: TextStyle(color: primaryTwo, fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Display selected contacts at the top
                if (selectedContacts.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedContacts.length,
                      itemBuilder: (context, index) {
                        final contact = selectedContacts[index];
                        String firstName =
                            (contact['name'] as String?)?.split(' ').first ??
                                'Unknown';
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: contact['profilePic'] !=
                                                null &&
                                            contact['profilePic']!.isNotEmpty
                                        ? NetworkImage(contact['profilePic']!)
                                        : const AssetImage(
                                            'assets/images/avatar.png'),
                                    child: contact['profilePic'] == null ||
                                            contact['profilePic']!.isEmpty
                                        ? Icon(Icons.person, color: white)
                                        : null,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    firstName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedContacts.removeAt(index);
                                  });
                                },
                                child: CircleAvatar(
                                  radius: 8,
                                  backgroundColor: Colors.red,
                                  child:
                                      Icon(Icons.close, size: 16, color: white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      final isSelected = selectedContacts.contains(contact);

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundImage: contact['profilePic'] != null &&
                                  contact['profilePic']!.isNotEmpty
                              ? NetworkImage(contact['profilePic']!)
                              : const AssetImage('assets/images/avatar.png'),
                          child: contact['profilePic'] == null ||
                                  contact['profilePic']!.isEmpty
                              ? Icon(Icons.person, color: white)
                              : null,
                        ),
                        title: Text(contact['name'] ?? 'Unknown'),
                        subtitle: Text(contact['phone'] ?? 'No phone number'),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: primaryColor)
                            : const Icon(Icons.radio_button_unchecked),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedContacts.remove(contact);
                            } else {
                              selectedContacts.add(contact);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: selectedContacts.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: primaryTwo,
              child: Icon(Icons.arrow_forward, color: primaryColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupDetailsScreen(
                      selectedContacts: selectedContacts,
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }
}

class ContactSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> contacts;
  final Function(List<Map<String, dynamic>>) onSelection;
  final List<Map<String, dynamic>> selectedContacts;

  ContactSearchDelegate(this.contacts, this.onSelection, this.selectedContacts);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final filteredContacts = _filterContacts(contacts);
    final unselectedContacts = filteredContacts.where((contact) {
      return !selectedContacts.contains(contact);
    }).toList();

    return ListView.builder(
      itemCount: unselectedContacts.length,
      itemBuilder: (context, index) {
        final contact = unselectedContacts[index];
        final isSelected = selectedContacts.contains(contact);

        return ListTile(
          leading: CircleAvatar(
            radius: 30,
            backgroundImage: contact['profilePic'] != null &&
                    contact['profilePic']!.isNotEmpty
                ? NetworkImage(contact['profilePic']!)
                : const AssetImage('assets/images/avatar.png'),
            child:
                contact['profilePic'] == null || contact['profilePic']!.isEmpty
                    ? Icon(Icons.person, color: white)
                    : null,
          ),
          title: Text(contact['name'] ?? 'Unknown'),
          subtitle: Text(contact['phone'] ?? 'No phone number'),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: primaryColor)
              : const Icon(Icons.radio_button_unchecked),
          onTap: () {
            if (isSelected) {
              selectedContacts.remove(contact);
            } else {
              selectedContacts.add(contact);
            }
            onSelection(List.from(selectedContacts));
            close(context, null); // Close search after selection
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }

  List<Map<String, dynamic>> _filterContacts(
      List<Map<String, dynamic>> originalContacts) {
    final normalizedQuery = query.toLowerCase();
    return originalContacts.where((contact) {
      final name = contact['name']?.toLowerCase() ?? '';
      final phone = contact['phone']?.toLowerCase() ?? '';
      return name.contains(normalizedQuery) || phone.contains(normalizedQuery);
    }).toList();
  }
}
