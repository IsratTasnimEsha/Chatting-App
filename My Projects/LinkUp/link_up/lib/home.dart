import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:link_up/blocked_contacts.dart';
import 'package:link_up/chats.dart';
import 'package:link_up/friend_requests.dart';
import 'package:link_up/requests_sent.dart';
import 'package:link_up/search_people.dart';
import 'package:link_up/stories.dart';
import 'package:link_up/user_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile.dart';
import 'friends.dart';
import 'reset_password.dart';

const Color color_1 = Color(0xFF8ba16a);

class HomePage extends StatefulWidget {
  final String email;

  const HomePage({Key? key, required this.email}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _profileImageUrl;
  int _selectedIndex = 0;

  Future<void> _loadProfileImage() async {
    try {
      // Construct the path to the user's profile image in Firebase Storage
      String filePath = 'users/${widget.email}/profile_pic.png';  // Ensure correct file extension if any

      // Retrieve the download URL
      String downloadUrl = await FirebaseStorage.instance.ref(filePath).getDownloadURL();

      // Update the state with the profile image URL
      setState(() {
        _profileImageUrl = downloadUrl;
      });
    } catch (e) {
      // Handle any errors (e.g., file not found, permission issues)
      print('Failed to load profile image: $e');
      setState(() {
        _profileImageUrl = null;  // Set to null to handle cases where the image fails to load
      });
    }
  }

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();

    // Initialize _widgetOptions with the email passed from widget.email
    _widgetOptions = <Widget>[
      const ChatsPage(),
      FriendRequestsPage(email: widget.email),
      SearchPeoplePage(email: widget.email), // Use widget.email here
      const StoriesPage(),
    ];
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
                  _profileImageUrl != null
                      ? CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(_profileImageUrl!),
                  )
                      : const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Menu',
                    style: TextStyle(),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.toggle_on),
              title: const Text('Active Status'),
              onTap: () {
                // Navigate to Active Status page
                Navigator.pop(context); // Close the drawer
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
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(email: widget.email),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.memory),
              title: const Text('Memories'),
              onTap: () {

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
                    builder: (context) => BlockedContactsPage(email: widget.email),
                  ),
                );              },
            ),
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Reset Password'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResetPasswordPage(email: widget.email),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                // Clear the saved email from SharedPreferences
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('rememberedEmail');

                // Navigate back to the Sign In page
                Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
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
          canvasColor: Colors.white, // Ensures the background is white even if overridden by the theme
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
            BottomNavigationBarItem(
              icon: Icon(Icons.amp_stories),
              label: 'Stories',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: color_1, // Set the color when an item is selected
          unselectedItemColor: Colors.grey, // Set the color when an item is not selected
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
