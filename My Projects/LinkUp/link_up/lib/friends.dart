import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Color color_1 = Colors.blue;

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
  int _totalRequests = 0;

  @override
  void initState() {
    super.initState();
    _initListeners();
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
    FirebaseDatabase.instance.ref("users/${widget.email}/friend").onValue.drain();
    super.dispose();
  }

  void _initListeners() {
    // Listener for 'friend' node to monitor changes
    final friendsRef = FirebaseDatabase.instance.ref("users/${widget.email}/friend");
    friendsRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final requests = snapshot.children;

        setState(() {
          _friends.clear();
          _requestKeys.clear();
          for (final request in requests) {
            final sentEmail = request.value.toString();
            _friends.add(sentEmail);
            _requestKeys[sentEmail] = _timeAgo(request.key.toString());
          }
          _totalRequests = _friends.length;
        });
        _loadPeople(); // Reload people when friends list changes
      } else {
        // Clear the lists if no friends exist
        setState(() {
          _friends.clear();
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
          if (email != null && _friends.contains(email)) {
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
          if (email != null && _friends.contains(email)) {
            final name = person.child('name').value.toString();
            final profilePicUrl = await _loadProfilePic(email);

            newUserNames[email] = name;
            newProfilePics[email] = profilePicUrl;
          }
        }

        setState(() {
          _userNames = newUserNames;
          _profilePics = newProfilePics;
          _totalRequests = _friends.length;
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

  void _viewFriendProfile(String email) {
    Navigator.pushNamed(
      context,
      '/viewFriendProfile',
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
      body: _isLoading
          ? _buildShimmer()
          : _totalRequests == 0
          ? Center(
        child: Text(
          'No friend',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: Colors.grey[600],
          ),
        ),
      )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
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
                        fontWeight: FontWeight
                            .normal, // Normal weight for the input text
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
                          borderSide:
                              BorderSide.none, // No border when not focused
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide(
                              color: color_1,
                              width: 0.5), // Accent color when focused
                        ),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 20.0),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Total Friends: $_totalRequests',
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
                      final requestKey =
                          _requestKeys[email]; // Get the request key

                      return GestureDetector(
                        onTap: () {
                          // Implement what happens when the card is tapped
                          _viewFriendProfile(email);
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
                                      ? NetworkImage(profilePicUrl)
                                          as ImageProvider
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12.0, horizontal: 16.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.normal),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 16.0),
                                            // Add space between text elements
                                            child: Text(
                                              '$requestKey',
                                              style: const TextStyle(
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.grey),
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
                    color: Colors.white
                        .withOpacity(0.8), // Slightly dim background
                    child: Center(
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

  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
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
                // Shimmering Name and Request Key
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
