import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

const Color color_1 = Color(0xFF8ba16a);

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
  Set<String> _sentRequests = {};
  Set<String> _friendRequests = {};
  Set<String> _friends = {};
  Set<String> _blockeds = {};
  Set<String> _blockedBys = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSentRequests();
    _loadFriendRequests();
    _loadFriends();
    _loadBlockeds();
    _loadBlockedBys();
    _loadPeople();
  }

  Future<void> _loadSentRequests() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref("users/${widget.email}/request_sent")
          .get();

      if (snapshot.exists) {
        final requests = snapshot.children;

        setState(() {
          for (final request in requests) {
            final sentEmail = request.value.toString();
            _sentRequests.add(sentEmail);
          }
        });
      }
    } catch (e) {
      print('Failed to load sent requests: $e');
    }
  }

  Future<void> _loadFriendRequests() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref("users/${widget.email}/friend_request")
          .get();

      if (snapshot.exists) {
        final requests = snapshot.children;

        setState(() {
          for (final request in requests) {
            final sentEmail = request.value.toString();
            _friendRequests.add(sentEmail);
          }
        });
      }
    } catch (e) {
      print('Failed to load friend requests: $e');
    }
  }

  Future<void> _loadFriends() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref("users/${widget.email}/friend")
          .get();

      if (snapshot.exists) {
        final requests = snapshot.children;

        setState(() {
          for (final request in requests) {
            final sentEmail = request.value.toString();
            _friends.add(sentEmail);
          }
        });
      }
    } catch (e) {
      print('Failed to load friends: $e');
    }
  }

  Future<void> _loadBlockeds() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref("users/${widget.email}/blocked")
          .get();

      if (snapshot.exists) {
        final requests = snapshot.children;

        setState(() {
          for (final request in requests) {
            final sentEmail = request.value.toString();
            _blockeds.add(sentEmail);
          }
        });
      }
    } catch (e) {
      print('Failed to load blockeds: $e');
    }
  }

  Future<void> _loadBlockedBys() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref("users/${widget.email}/blocked")
          .get();

      if (snapshot.exists) {
        final requests = snapshot.children;

        setState(() {
          for (final request in requests) {
            final sentEmail = request.value.toString();
            _blockedBys.add(sentEmail);
          }
        });
      }
    } catch (e) {
      print('Failed to load blocked by s: $e');
    }
  }

  Future<void> _loadPeople() async {
    try {
      final snapshot = await _usersRef.get();
      if (snapshot.exists) {
        final people = snapshot.children;

        for (final person in people) {
          final email = person.key;
          if (email != null && email != widget.email && !_sentRequests.contains(email) && !_friendRequests.contains(email) && !_friends.contains(email) && !_blockeds.contains(email) && !_blockedBys.contains(email)) {
            final name = person.child('name').value.toString();
            final profilePicUrl = await _loadProfilePic(email);

            setState(() {
              _userNames[email] = name;
              _profilePics[email] = profilePicUrl;
            });
          }
        }
      }
    } catch (e) {
      print('Failed to load people: $e');
    }
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

    // Update the UI to remove the user from the list after sending the request
    setState(() {
      _userNames.remove(email);
      _profilePics.remove(email);
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
      body: Column(
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
                    borderSide: const BorderSide(color: color_1, width: 0.5), // Accent color when focused
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
}