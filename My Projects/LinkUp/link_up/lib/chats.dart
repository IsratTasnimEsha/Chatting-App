import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

const Color color_1 = Color(0xFF8ba16a);

class ChatsPage extends StatefulWidget {
  final String email;

  const ChatsPage({Key? key, required this.email}) : super(key: key);

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Map<String, String> _userNames = {};
  Map<String, String?> _profilePics = {};
  Set<String> _friends = {};
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
    FirebaseDatabase.instance.ref("users/${widget.email}/chat").onValue.drain();
    super.dispose();
  }

  void _initListeners() {
    final chatRef = FirebaseDatabase.instance.ref("users/${widget.email}/chat");
    chatRef.onValue.listen((event) async {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final Map<String, String> newUserNames = {};
        final Map<String, String?> newProfilePics = {};

        _friends.clear();

        for (final child in snapshot.children) {
          final friendEmail = child.key;

          if (friendEmail != null) {
            _friends.add(friendEmail);

            // Fetch the username
            final userSnapshot = await _usersRef.child(friendEmail).get();
            final name = userSnapshot.child('name').value.toString();
            final profilePicUrl = await _loadProfilePic(friendEmail);

            newUserNames[friendEmail] = name;
            newProfilePics[friendEmail] = profilePicUrl;
          }
        }

        setState(() {
          _userNames = newUserNames;
          _profilePics = newProfilePics;
          _totalRequests = _friends.length;
          _isLoading = false;
        });
      } else {
        setState(() {
          _userNames.clear();
          _profilePics.clear();
          _friends.clear();
          _totalRequests = 0;
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

  void _userMessage(String email) {
    Navigator.pushNamed(
      context,
      '/userMessage',
      arguments: {
        'email': widget.email,
        'other_email': email,
      },
    );
  }

  void _showOptionsBottomSheet(String otherEmail) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Conversation'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _showConfirmationDialog(otherEmail); // Show confirmation dialog
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmationDialog(String otherEmail) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Conversation?'),
          content: Text('Are you sure you want to delete the conversation?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                // Remove chat entry from Firebase
                await FirebaseDatabase.instance.ref("users/${widget.email}/chat/$otherEmail").remove();

                final chatImagesRef = FirebaseStorage.instance.ref("users/${widget.email}/chat/$otherEmail");
                final listResult = await chatImagesRef.listAll();
                for (final item in listResult.items) {
                  await item.delete();
                }
              },
              child: const Text('Delete'),
              style: TextButton.styleFrom(primary: Colors.red),
            ),
          ],
        );
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
        title: const Text('Chats'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      body: _isLoading
          ? _buildShimmer()
          : _totalRequests == 0
          ? Center(
        child: Text(
          'No chat',
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
                    offset: const Offset(0, 3),
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
                  fontWeight: FontWeight.normal,
                ),
                decoration: InputDecoration(
                  hintText: 'Search your friends...',
                  hintStyle: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.normal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: const BorderSide(
                        color: color_1,
                        width: 0.5),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total Chats: $_totalRequests',
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

                return GestureDetector(
                  onTap: () {
                    _userMessage(email);
                  },
                  onLongPress: () {
                    _showOptionsBottomSheet(email);
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal),
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
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(
                  color: color_1,
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
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12.0),
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

