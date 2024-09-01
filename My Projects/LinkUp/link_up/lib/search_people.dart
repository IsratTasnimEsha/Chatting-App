import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Color color_1 = Colors.blue;

class SearchPeoplePage extends StatefulWidget {
  final String email;

  const SearchPeoplePage({Key? key, required this.email}) : super(key: key);

  @override
  _SearchPeoplePageState createState() => _SearchPeoplePageState();
}

class _SearchPeoplePageState extends State<SearchPeoplePage> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Map<String, String> _userNames = {};
  Map<String, String?> _profilePics = {};
  Set<String> _requestSents = {};
  Set<String> _friendRequests = {};
  Set<String> _friends = {};
  Set<String> _blockedContacts = {};
  Set<String> _blockedByContacts = {};
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initCombinedListeners();
    _fetchUserColor(); // Fetch the color for other_email
  }

  void _fetchUserColor() {
    DatabaseReference colorRef = FirebaseDatabase.instance
        .ref('users/${widget.email}/appColor');

    colorRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        String colorValue = event.snapshot.value.toString();
        setState(() {
          color_1 = _getColorFromHex(colorValue); // Convert the color string to Color
        });
      }
    });
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor"; // Add alpha if not provided
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  void dispose() {
    _usersRef.onValue.drain();
    FirebaseDatabase.instance.ref("users/${widget.email}").onValue.drain();
    super.dispose();
  }

  void _initCombinedListeners() {
    final userRef = FirebaseDatabase.instance.ref("users/${widget.email}");
    userRef.onValue.listen((event) async {
      final snapshot = event.snapshot;

      if (snapshot.exists) {
        final userSnapshot = snapshot.value as Map;

        // Debugging: Print the snapshot data
        print('User Snapshot: $userSnapshot');

        Set<String> updatedRequestSents = {};
        Set<String> updatedFriendRequests = {};
        Set<String> updatedFriends = {};
        Set<String> updatedBlockedContacts = {};
        Set<String> updatedBlockedByContacts = {};

        if (userSnapshot.containsKey('request_sent')) {
          updatedRequestSents = Set<String>.from(userSnapshot['request_sent'].values);
        }

        if (userSnapshot.containsKey('friend_request')) {
          updatedFriendRequests = Set<String>.from(userSnapshot['friend_request'].values);
        }

        if (userSnapshot.containsKey('friend')) {
          updatedFriends = Set<String>.from(userSnapshot['friend'].values);
        }

        if (userSnapshot.containsKey('blocked')) {
          updatedBlockedContacts = Set<String>.from(userSnapshot['blocked'].values);
        }

        if (userSnapshot.containsKey('blockedBy')) {
          updatedBlockedByContacts = Set<String>.from(userSnapshot['blockedBy'].values);
        }

        // Debugging: Print updated blocked contacts
        print('Blocked Contacts: $updatedBlockedContacts');
        print('Blocked By Contacts: $updatedBlockedByContacts');

        final Map<String, String> newUserNames = {};
        final Map<String, String?> newProfilePics = {};

        final allUsersSnapshot = await _usersRef.get();
        if (allUsersSnapshot.exists) {
          for (final person in allUsersSnapshot.children) {
            final email = person.key;
            if (email != null &&
                email != widget.email &&
                !updatedRequestSents.contains(email) &&
                !updatedFriendRequests.contains(email) &&
                !updatedFriends.contains(email) &&
                !updatedBlockedContacts.contains(email) &&
                !updatedBlockedByContacts.contains(email)) {
              final name = person.child('name').value.toString();
              final profilePicUrl = await _loadProfilePic(email);

              newUserNames[email] = name;
              newProfilePics[email] = profilePicUrl;
            }
          }
        }

        setState(() {
          _requestSents = updatedRequestSents;
          _friendRequests = updatedFriendRequests;
          _friends = updatedFriends;
          _blockedContacts = updatedBlockedContacts;
          _blockedByContacts = updatedBlockedByContacts;
          _userNames = newUserNames;
          _profilePics = newProfilePics;
          _isLoading = false;
        });
      }
    });
  }

  Future<String?> _loadProfilePic(String email) async {
    try {
      final filePath = 'users/$email/profile_pic.png';
      final downloadUrl = await _storage.ref(filePath).getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Failed to load profile picture for $email: $e');
      return null;
    }
  }

  Future<void> _addFriend(String email) async {
    String e1 = email;
    String e2 = widget.email;

    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String formattedTime = timestamp.toString();

    // Using push() to generate a unique key
    final DatabaseReference ref1 =
    FirebaseDatabase.instance.ref("users/$e2/request_sent/");
    await ref1.child(formattedTime).set(e1);

    final DatabaseReference ref2 =
    FirebaseDatabase.instance.ref("users/$e1/friend_request/");
    await ref2.child(formattedTime).set(e2);

    // Update the state to reflect changes in the UI
    setState(() {
      _requestSents.remove(email);
      _friendRequests.remove(email); // Remove from friend requests set
      _friends.remove(email);
      _blockedContacts.remove(email);
      _blockedByContacts.remove(email);
      _userNames.remove(email); // Remove from user names map
      _profilePics.remove(email); // Remove from profile pics map
    });
  }

  void _viewProfile(String email) {
    Navigator.pushNamed(
      context,
      '/viewProfile',
      arguments: {
        'email': email,
        'other_email': widget.email,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUserNames = _userNames.entries.where((entry) {
      final name = entry.value.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search People'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? _buildShimmer()
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: const Offset(0, 3), // Shadow position
                  ),
                ],
              ),
              child: TextField(
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
                style: const TextStyle(
                  fontWeight: FontWeight.normal, // Normal weight for the input text
                ),
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal), // Normal text style,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide.none, // No border on focus
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide.none, // No border when not focused
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(color: color_1, width: 0.5), // Accent color when focused
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredUserNames.length,
              itemBuilder: (context, index) {
                final email = filteredUserNames[index].key;
                final name = filteredUserNames[index].value;
                final profilePicUrl = _profilePics[email];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4.0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12.0),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: profilePicUrl != null
                          ? NetworkImage(profilePicUrl) as ImageProvider
                          : const AssetImage('assets/default_profile_pic.png'),
                      backgroundColor: Colors.grey[300],
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.normal)),
                    trailing: ElevatedButton.icon(
                      onPressed: () => _addFriend(email),
                      style: ElevatedButton.styleFrom(
                        primary: color_1,
                        onPrimary: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      icon: const Icon(Icons.person_add_alt_1), // Replace with your desired icon
                      label: const Text('Add Friend'),
                    ),
                    onTap: () => _viewProfile(email),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 5, // Number of shimmer items to display
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                // Shimmering Profile Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16.0), // Spacing between avatar and text

                // Shimmering Name and Button in the same row
                Expanded(
                  child: Row(
                    children: [
                      // Shimmering Name
                      Expanded(
                        child: Container(
                          height: 16.0,
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      // Shimmering Button
                      Container(
                        width: 100.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}