import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:link_up/blocked_contacts.dart';
import 'package:link_up/chats.dart';
import 'package:link_up/friend_requests.dart';
import 'package:link_up/requests_sent.dart';
import 'package:link_up/search_people.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'color_mode.dart';
import 'edit_profile.dart';
import 'friends.dart';

Color color_1 = Colors.blue;

class HomePage extends StatefulWidget {
  final String email;

  const HomePage({Key? key, required this.email}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _profileImageUrl;
  int _selectedIndex = 0;
  String username = '';

  Future<void> _loadProfileImage() async {
    try {
      // Construct the path to the user's profile image in Firebase Storage
      String filePath =
          'users/${widget.email}/profile_pic.png'; // Ensure correct file extension if any

      // Retrieve the download URL
      String downloadUrl =
          await FirebaseStorage.instance.ref(filePath).getDownloadURL();

      // Update the state with the profile image URL
      setState(() {
        _profileImageUrl = downloadUrl;
      });
    } catch (e) {
      // Handle any errors (e.g., file not found, permission issues)
      print('Failed to load profile image: $e');
      setState(() {
        _profileImageUrl =
            null; // Set to null to handle cases where the image fails to load
      });
    }
  }

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _fetchUserName();
    _fetchUserColor();

    // Initialize _widgetOptions with the email passed from widget.email
    _widgetOptions = <Widget>[
      ChatsPage(email: widget.email),
      FriendRequestsPage(email: widget.email),
      SearchPeoplePage(email: widget.email), // Use widget.email here
    ];
  }

  void _fetchUserColor() {
    DatabaseReference colorRef =
        FirebaseDatabase.instance.ref('users/${widget.email}/appColor');

    colorRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        String colorValue = event.snapshot.value.toString();
        setState(() {
          color_1 =
              _getColorFromHex(colorValue); // Convert the color string to Color
        });
      }
    });
  }

  void _fetchUserName() {
    DatabaseReference nameRef = FirebaseDatabase.instance.ref('users/${widget.email}/name');
    nameRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          username = event.snapshot.value.toString();
        });
      } else {
        setState(() {
          username = 'Unknown User'; // Default value if not found
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(email: widget.email),
                        ),
                      );
                    },
                    child: _profileImageUrl != null
                        ? CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(_profileImageUrl!),
                    )
                        : const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    username,
                    style: TextStyle(fontWeight: FontWeight.normal), // Added style for better visibility
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formattedEmail(widget.email),
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal), // Added style for better visibility
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Color Mode'),
              onTap: () {
                // Navigate to Active Status page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ColorModePage(email: widget.email, text: "Select Theme Color"),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.connect_without_contact),
              title: const Text('Friends'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FriendsPage(email: widget.email),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('Requests Sent'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RequestsSentPage(email: widget.email),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Blocked Contacts'),
              onTap: () {
                // Navigate to Blocked Persons page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BlockedContactsPage(email: widget.email),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                final databaseReference = FirebaseDatabase.instance.ref();
                await databaseReference
                    .child('users/${widget.email}/activeStatus')
                    .set('Offline');
                // Clear the saved email from SharedPreferences
                final SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                await prefs.remove('rememberedEmail');

                // Navigate back to the Sign In page
                Navigator.pushNamedAndRemoveUntil(
                    context, '/signin', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors
              .white, // Ensures the background is white even if overridden by the theme
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_add),
              label: 'Friend Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search People',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: color_1,
          // Set the color when an item is selected
          unselectedItemColor: Colors.grey,
          // Set the color when an item is not selected
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  String formattedEmail(String email) {
    return email.replaceAll('_dot_', '.').replaceAll('_at_', '@');
  }
}
