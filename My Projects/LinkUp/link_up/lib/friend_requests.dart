import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

const Color color_1 = Color(0xFF8ba16a);

class FriendRequestsPage extends StatefulWidget {
  final String email;

  const FriendRequestsPage({Key? key, required this.email}) : super(key: key);

  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Map<String, String> _userNames = {};
  Map<String, String?> _profilePics = {};
  Map<String, String> _requestKeys = {}; // Map to store request keys
  Set<String> _friendRequests = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
    _loadPeople();
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
            _requestKeys[sentEmail] = _timeAgo(request.key.toString()); // Store the request key
          }
        });
      }
    } catch (e) {
      print('Failed to load friend requests: $e');
    }
  }

  Future<void> _loadPeople() async {
    try {
      final snapshot = await _usersRef.get();
      if (snapshot.exists) {
        final people = snapshot.children;

        for (final person in people) {
          final email = person.key;
          if (email != null && _friendRequests.contains(email)) {
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

  Future<void> _acceptRequest(String email) async {
    String e1 = email;
    String e2 = widget.email;

    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String formattedTime = timestamp.toString();

    final DatabaseReference ref1_1 =
    FirebaseDatabase.instance.ref("users/$e1/request_sent/");
    final DatabaseReference ref1_2 =
    FirebaseDatabase.instance.ref("users/$e2/friend_request/");

    // Retrieve the data for e2's request_sent
    DataSnapshot snapshot1 = await ref1_1.get();
    if (snapshot1.exists) {
      Map<dynamic, dynamic> requestsSent =
      snapshot1.value as Map<dynamic, dynamic>;
      for (var key in requestsSent.keys) {
        if (requestsSent[key] == e2) {
          // Key found, now delete it
          await ref1_1.child(key).remove();
          break;
        }
      }
    }

    // Retrieve the data for e1's friend_request
    DataSnapshot snapshot2 = await ref1_2.get();
    if (snapshot2.exists) {
      Map<dynamic, dynamic> friendRequests =
      snapshot2.value as Map<dynamic, dynamic>;
      for (var key in friendRequests.keys) {
        if (friendRequests[key] == e1) {
          // Key found, now delete it
          await ref1_2.child(key).remove();
          break;
        }
      }
    }

    // Using push() to generate a unique key
    final DatabaseReference ref2_1 =
    FirebaseDatabase.instance.ref("users/$e2/friend/");
    await ref2_1.child(formattedTime).set(e1);

    final DatabaseReference ref2_2 =
    FirebaseDatabase.instance.ref("users/$e1/friend/");
    await ref2_2.child(formattedTime).set(e2);

    // Update the UI to remove the user from the list after sending the request
    setState(() {
      _userNames.remove(email);
      _profilePics.remove(email);
      _requestKeys.remove(email); // Remove the request key
    });
  }

  Future<void> _deleteRequest(String email) async {
    String e1 = email;
    String e2 = widget.email;

    final DatabaseReference ref1_1 =
    FirebaseDatabase.instance.ref("users/$e2/request_sent/");
    final DatabaseReference ref1_2 =
    FirebaseDatabase.instance.ref("users/$e1/friend_request/");

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

    // Update the UI to remove the user from the list after sending the request
    setState(() {
      _userNames.remove(email);
      _profilePics.remove(email);
      _requestKeys.remove(email); // Remove the request key
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
        title: const Text('Friend Requests'),
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
            padding:
            const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                  fontWeight:
                  FontWeight.normal, // Normal weight for the input text
                ),
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  hintStyle: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.normal),
                  // Normal text style,
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
                    borderSide: const BorderSide(
                        color: color_1,
                        width: 0.5), // Accent color when focused
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 20.0),
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
                final requestKey = _requestKeys[email]; // Get the request key

                return GestureDetector(
                  onTap: () {
                    // Implement what happens when the card is tapped
                    _viewProfile(email);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4.0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        // Profile Image
                        Container(
                          margin: const EdgeInsets.all(12.0),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: profilePicUrl != null
                                ? NetworkImage(profilePicUrl) as ImageProvider
                                : const AssetImage(
                                'assets/default_profile_pic.png'),
                            backgroundColor: Colors.grey[300],
                          ),
                        ),
                        // Profile Details and Buttons
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.normal),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16.0), // Add space between text elements
                                      child: Text(
                                        '$requestKey',
                                        style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Buttons Row
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding:
                                        const EdgeInsets.only(right: 4.0),
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            // Implement Accept functionality here
                                            _acceptRequest(email);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            primary: color_1,
                                            // Accept button color
                                            onPrimary: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(8.0),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12.0),
                                          ),
                                          icon: const Icon(Icons.check,
                                              color: Colors.white),
                                          label: const Text('Accept'),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding:
                                        const EdgeInsets.only(left: 4.0),
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            // Implement Delete functionality here
                                            _deleteRequest(email);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            primary: Colors.redAccent,
                                            // Delete button color
                                            onPrimary: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(8.0),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12.0),
                                          ),
                                          icon: const Icon(Icons.delete,
                                              color: Colors.white),
                                          label: const Text('Delete'),
                                        ),
                                      ),
                                    ),
                                  ],
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
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
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
