import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Color color_1 = Colors.blue;

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
  Map<String, String> _requestKeys = {};
  Set<String> _friendRequests = {};
  String _searchQuery = '';
  bool _isLoading = true;
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
    FirebaseDatabase.instance.ref("users/${widget.email}/friend_request").onValue.drain();
    super.dispose();
  }

  void _initListeners() {
    // Listener for 'request_sent' node to monitor changes
    final requestSentRef = FirebaseDatabase.instance.ref("users/${widget.email}/friend_request");
    requestSentRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final requests = snapshot.children;

        setState(() {
          _friendRequests.clear();
          _requestKeys.clear();
          for (final request in requests) {
            final sentEmail = request.value.toString();
            _friendRequests.add(sentEmail);
            _requestKeys[sentEmail] = _timeAgo(request.key.toString());
          }
          _totalRequests = _friendRequests.length;
        });
        _loadPeople(); // Reload people when request_sent list changes
      } else {
        // Clear the lists if no requests sent exist
        setState(() {
          _friendRequests.clear();
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
          if (email != null && _friendRequests.contains(email)) {
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
          if (email != null && _friendRequests.contains(email)) {
            final name = person.child('name').value.toString();
            final profilePicUrl = await _loadProfilePic(email);

            newUserNames[email] = name;
            newProfilePics[email] = profilePicUrl;
          }
        }

        setState(() {
          _userNames = newUserNames;
          _profilePics = newProfilePics;
          _totalRequests = _friendRequests.length;
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

    // Using push() to generate a unique key
    final DatabaseReference ref3_1 =
    FirebaseDatabase.instance.ref("users/$e2/chatColor/");
    await ref3_1.child(e1).set('ff448aff');

    final DatabaseReference ref3_2 =
    FirebaseDatabase.instance.ref("users/$e1/chatColor/");
    await ref3_2.child(e2).set('ff448aff');

    // Update the UI to remove the user from the list after sending the request
    setState(() {
      _userNames.remove(email);
      _profilePics.remove(email);
      _requestKeys.remove(email); // Remove the request key
    });

    // Update the state to reflect changes in the UI
    setState(() {
      _friendRequests.remove(email); // Remove from friend requests set
      _userNames.remove(email); // Remove from user names map
      _profilePics.remove(email); // Remove from profile pics map
      _requestKeys.remove(email); // Remove the request key
      _totalRequests = _friendRequests.length; // Update total requests count
    });
  }

  Future<void> _deleteRequest(String email) async {
    String e1 = email;
    String e2 = widget.email;

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

    // Update the state to reflect changes in the UI
    setState(() {
      _friendRequests.remove(email); // Remove from friend requests set
      _userNames.remove(email); // Remove from user names map
      _profilePics.remove(email); // Remove from profile pics map
      _requestKeys.remove(email); // Remove the request key
      _totalRequests = _friendRequests.length; // Update total requests count
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
      body: _isLoading
          ? _buildShimmer()
          : _totalRequests == 0
          ? Center(
        child: Text(
          'No friend request',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: Colors.grey[600],
          ),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: Column(
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
                // Display the number of requests or a message if there are no requests
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Total Friend Requests: $_totalRequests',
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
                                      : const AssetImage('assets/default_profile_pic.png'),
                                  backgroundColor: Colors.grey[300],
                                ),
                              ),
                              // Profile Details and Buttons
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name and Request Key
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
                                              style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12.0, color: Colors.grey),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Buttons Row
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 4.0),
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  // Implement Accept functionality here
                                                  _acceptRequest(email);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  primary: color_1, // Accept button color
                                                  onPrimary: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8.0),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                                ),
                                                icon: const Icon(Icons.check, color: Colors.white),
                                                label: const Text('Accept'),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 4.0),
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  // Implement Delete functionality here
                                                  _deleteRequest(email);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  primary: Colors.redAccent, // Delete button color
                                                  onPrimary: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8.0),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                                ),
                                                icon: const Icon(Icons.delete, color: Colors.white),
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
          )
        ],
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5, // Number of shimmer items to display
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
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
                // Shimmering Profile Details and Buttons
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shimmering Name and Request Key
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 16.0,
                                color: Colors.grey[300],
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Container(
                              width: 50.0,
                              height: 12.0,
                              color: Colors.grey[300],
                            ),
                          ],
                        ),
                      ),
                      // Shimmering Buttons Row
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 36.0,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Container(
                                height: 36.0,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8.0),
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
