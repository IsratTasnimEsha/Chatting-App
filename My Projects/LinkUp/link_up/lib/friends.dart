import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

const Color color_1 = Color(0xFF8ba16a);

class FriendsPage extends StatefulWidget {
  final String email;

  const FriendsPage({Key? key, required this.email}) : super(key: key);

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Map<String, String> _userNames = {};
  Map<String, String?> _profilePics = {};
  Map<String, String> _requestKeys = {}; // Map to store request keys
  Set<String> _friends = {};
  String _searchQuery = '';
  bool _isLoading = true; // Add this flag for loading state

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
    _loadPeople();
  }

  Future<void> _loadFriendRequests() async {
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
          if (email != null && _friends.contains(email)) {
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
    finally {
      setState(() {
        _isLoading = false; // Loading finished
      });
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
        title: const Text('Friends'),
        backgroundColor: Colors.white,
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
                  hintText: 'Search your friends...',
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
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8), // Slightly dim background
              child: const Center(
                child: CircularProgressIndicator(
                  color: color_1, // Use your primary color
                ),
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