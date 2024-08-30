import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

const Color color_1 = Colors.blue;

class BlockedContactsPage extends StatefulWidget {
  final String email;

  const BlockedContactsPage({Key? key, required this.email}) : super(key: key);

  @override
  _BlockedContactsPageState createState() => _BlockedContactsPageState();
}

class _BlockedContactsPageState extends State<BlockedContactsPage> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Map<String, String> _userNames = {};
  Map<String, String?> _profilePics = {};
  Map<String, String> _requestKeys = {};
  Set<String> _blockedContacts = {};
  String _searchQuery = '';
  bool _isLoading = true;
  int _totalRequests = 0;

  @override
  void initState() {
    super.initState();
    _initListeners();
  }

  @override
  void dispose() {
    _usersRef.onValue.drain();
    FirebaseDatabase.instance.ref("users/${widget.email}/blocked").onValue.drain();
    super.dispose();
  }

  void _initListeners() {
    final blockedContactsRef = FirebaseDatabase.instance.ref("users/${widget.email}/blocked");
    blockedContactsRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final requests = snapshot.children;

        setState(() {
          _blockedContacts.clear();
          _requestKeys.clear();
          for (final request in requests) {
            final sentEmail = request.value.toString();
            _blockedContacts.add(sentEmail);
            _requestKeys[sentEmail] = _timeAgo(request.key.toString());
          }
          _totalRequests = _blockedContacts.length;
        });
        _loadPeople(); // Reload people when request_sent list changes
      } else {
        // Clear the lists if no requests sent exist
        setState(() {
          _blockedContacts.clear();
          _requestKeys.clear();
          _userNames.clear();
          _profilePics.clear();
          _totalRequests = 0;
        });
      }
    });

    // Listener for changes in the 'users' node
    _usersRef.onValue.listen((event) async {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final people = snapshot.children;

        final Map<String, String> newUserNames = {};
        final Map<String, String?> newProfilePics = {};

        for (final person in people) {
          final email = person.key;
          if (email != null && _blockedContacts.contains(email)) {
            final name = person.child('name').value.toString();
            final profilePicUrl = await _loadProfilePic(email);

            newUserNames[email] = name;
            newProfilePics[email] = profilePicUrl;
          }
        }

        setState(() {
          _userNames = newUserNames;
          _profilePics = newProfilePics;
          _isLoading = false;
        });
      }
    });
  }

  void _loadPeople() {
    _usersRef.onValue.listen((event) async {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final people = snapshot.children;

        final Map<String, String> newUserNames = {};
        final Map<String, String?> newProfilePics = {};

        for (final person in people) {
          final email = person.key;
          if (email != null && _blockedContacts.contains(email)) {
            final name = person.child('name').value.toString();
            final profilePicUrl = await _loadProfilePic(email);

            newUserNames[email] = name;
            newProfilePics[email] = profilePicUrl;
          }
        }

        setState(() {
          _userNames = newUserNames;
          _profilePics = newProfilePics;
          _totalRequests = _blockedContacts.length;
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

  Future<void> _unblockUser(String email) async {
    String e1 = email;
    String e2 = widget.email;

    final DatabaseReference ref1_1 =
    FirebaseDatabase.instance.ref("users/$e2/blocked/");
    final DatabaseReference ref1_2 =
    FirebaseDatabase.instance.ref("users/$e1/blockedBy/");

    // Retrieve the data for e2's request_sent
    DataSnapshot snapshot1 = await ref1_1.get();
    if (snapshot1.exists) {
      Map<dynamic, dynamic> requestsSent = snapshot1.value as Map<dynamic, dynamic>;

      // Iterate through the map to find the key with the matching value
      for (var key in requestsSent.keys) {
        var value = requestsSent[key];

        // Print the key-value pair for debugging
        print('Key: $key, Value: $value');

        // Check if the value matches the one you're looking for
        if (value == e1) {
          // Key found, now delete it
          await ref1_1.child(key).remove(); // Remove the key-value pair
          print('Deleted Key: $key with Value: $value');
          break; // Exit the loop after deleting the first match
        }
      }
    } else {
      print('No data found at this reference');
    }

    // Retrieve the data for e1's friend_request
    DataSnapshot snapshot2 = await ref1_2.get();
    if (snapshot2.exists) {
      Map<dynamic, dynamic> friendRequests =
      snapshot2.value as Map<dynamic, dynamic>;
      for (var key in friendRequests.keys) {
        if (friendRequests[key] == e2) {
          // Key found, now delete it
          await ref1_2.child(key).remove();
          break;
        }
      }
    }

    // Update the state to reflect changes in the UI
    setState(() {
      _blockedContacts.remove(email); // Remove from friend requests set
      _userNames.remove(email); // Remove from user names map
      _profilePics.remove(email); // Remove from profile pics map
      _requestKeys.remove(email); // Remove the request key
      _totalRequests = _blockedContacts.length; // Update total requests count
    });
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
        title: const Text('Blocked Contacts'),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? _buildShimmer()
          : _totalRequests == 0
          ? Center(
        child: Text(
          'No blocked contacts',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: Colors.grey[600],
          ),
        ),
      )
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
                  hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft, // Align text to the left
              child: Text(
                'Total blocked contacts: $_totalRequests',
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                  fontSize: 14,
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
                final requestKey = _requestKeys[email]; // Get the request key

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
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16.0),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          requestKey.toString(),
                          style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: SizedBox(
                      width: 110, // Adjust width as needed
                      child: ElevatedButton.icon(
                        onPressed: () => _unblockUser(email),
                        style: ElevatedButton.styleFrom(
                          primary: color_1,
                          onPrimary: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        icon: const Icon(Icons.remove_circle_outline, size: 16), // Adjust icon size
                        label: const Text(
                          'Unblock',
                          style: TextStyle(fontSize: 14.0), // Adjust text size
                        ),
                      ),
                    ),
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
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              children: [
                // Shimmering Circle Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12.0),
                // Shimmering Name, Request Key, and Cancel Button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16.0,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        width: 100.0,
                        height: 12.0,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),
                // Shimmering Cancel Button
                Container(
                  width: 100, // Adjust width as needed to match the real button
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.0),
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

String _timeAgo(String timestamp) {
  // Convert the string to an integer
  int requestTimeMillis = int.parse(timestamp);

  // Convert milliseconds since epoch to DateTime
  DateTime requestTime = DateTime.fromMillisecondsSinceEpoch(requestTimeMillis);

  // Get the current time
  final now = DateTime.now();

  // Calculate the difference
  final difference = now.difference(requestTime);

  // Format the difference
  if (difference.inDays > 365) {
    int years = (difference.inDays / 365).floor();
    return '$years yr${years > 1 ? 's' : ''}';
  } else if (difference.inDays > 30) {
    int months = (difference.inDays / 30).floor();
    return '$months month${months > 1 ? 's' : ''}';
  } else if (difference.inDays > 0) {
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} hr${difference.inHours > 1 ? 's' : ''}';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''}';
  } else {
    return '${difference.inSeconds} sec${difference.inSeconds > 1 ? 's' : ''}';
  }
}
