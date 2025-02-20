import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart'; // Import the DatabaseHelper
import 'package:cyanase/theme/theme.dart'; // Import your theme file
import 'create_new_group_details.dart'; // Import the GroupDetailsScreen
import '../../../helpers/hash_numbers.dart'; // Import the getRegisteredContacts function

class NewGroupScreen extends StatefulWidget {
  @override
  _NewGroupScreenState createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> selectedContacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshContacts(); // Refresh contacts when the screen is opened
  }

  Future<void> _refreshContacts() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      // Fetch the latest contacts from the database
      final dbHelper = DatabaseHelper();
      final fetchedContacts = await dbHelper.getContacts();

      // Format the contacts
      final formattedContacts = fetchedContacts.map((contact) {
        return {
          'id': contact['id'],
          'name': contact['name'],
          'phone': contact['phone_number'],
          'profilePic': '', // Add profile picture logic if available
        };
      }).toList();

      // Fetch registered contacts from the server
      final registeredContacts = await getRegisteredContacts(formattedContacts);

      // Update the state with the registered contacts
      setState(() {
        contacts = registeredContacts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh contacts: $e')),
      );
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
        iconTheme: IconThemeData(color: white),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
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
          // Add a refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await _refreshContacts();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: Loader())
          : Column(
              children: [
                // Display selected contacts at the top
                if (selectedContacts.isNotEmpty)
                  Container(
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
                              padding: EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: contact['profilePic'] !=
                                                null &&
                                            contact['profilePic']!.isNotEmpty
                                        ? NetworkImage(contact['profilePic']!)
                                        : AssetImage(
                                            'assets/images/avatar.png'),
                                    child: contact['profilePic'] == null ||
                                            contact['profilePic']!.isEmpty
                                        ? Icon(Icons.person, color: white)
                                        : null,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    firstName,
                                    style: TextStyle(
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
                              : AssetImage('assets/images/avatar.png'),
                          child: contact['profilePic'] == null ||
                                  contact['profilePic']!.isEmpty
                              ? Icon(Icons.person, color: white)
                              : null,
                        ),
                        title: Text(contact['name'] ?? 'Unknown'),
                        subtitle: Text(contact['phone'] ?? 'No phone number'),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: primaryColor)
                            : Icon(Icons.radio_button_unchecked),
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
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
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
                : AssetImage('assets/images/avatar.png'),
            child:
                contact['profilePic'] == null || contact['profilePic']!.isEmpty
                    ? Icon(Icons.person, color: white)
                    : null,
          ),
          title: Text(contact['name'] ?? 'Unknown'),
          subtitle: Text(contact['phone'] ?? 'No phone number'),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: primaryColor)
              : Icon(Icons.radio_button_unchecked),
          onTap: () {
            if (isSelected) {
              selectedContacts.remove(contact);
            } else {
              selectedContacts.add(contact);
            }
            onSelection(List.from(selectedContacts));
            close(context, null); // Close the search after selection
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
