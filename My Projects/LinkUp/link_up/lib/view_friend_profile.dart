import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';

const Color backgroundColor = Color(0xFFF5F5F5);
const Color textColor = Color(0xFF212121);
const Color subtitleColor = Color(0xFF757575);
const Color color_1 = Color(0xFF8ba16a);

class ViewFriendProfilePage extends StatefulWidget {
  final String email;
  final String other_email;

  const ViewFriendProfilePage({
    Key? key,
    required this.email,
    required this.other_email,
  }) : super(key: key);

  @override
  _ViewFriendProfilePageState createState() => _ViewFriendProfilePageState();
}

class _ViewFriendProfilePageState extends State<ViewFriendProfilePage> {
  String? _profileImageUrl;
  String? _name;
  String? _phone;
  String? _address;
  String? _selectedGender;
  String? _aboutMe;
  File? _profileImage;
  DatabaseReference? _userRef;
  StreamSubscription<DatabaseEvent>? _userSubscription;

  void _listenToBlockStatus() {
    DatabaseReference blockRef1 = FirebaseDatabase.instance
        .ref('users/${widget.other_email}/blocked');
    DatabaseReference blockRef2 = FirebaseDatabase.instance
        .ref('users/${widget.other_email}/blockedBy');
    DatabaseReference blockRef3 = FirebaseDatabase.instance
        .ref('users/${widget.email}/blocked');
    DatabaseReference blockRef4 = FirebaseDatabase.instance
        .ref('users/${widget.email}/blockedBy');

    blockRef1.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> blockedUsers = event.snapshot.value as Map<dynamic, dynamic>;
        if (blockedUsers.containsValue(widget.email)) {
          _navigateAwayFromProfile();
        }
      }
    });

    blockRef2.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> blockedByUsers = event.snapshot.value as Map<dynamic, dynamic>;
        if (blockedByUsers.containsValue(widget.email)) {
          _navigateAwayFromProfile();
        }
      }
    });

    blockRef3.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> blockedUsers = event.snapshot.value as Map<dynamic, dynamic>;
        if (blockedUsers.containsValue(widget.other_email)) {
          _navigateAwayFromProfile();
        }
      }
    });

    blockRef4.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> blockedByUsers = event.snapshot.value as Map<dynamic, dynamic>;
        if (blockedByUsers.containsValue(widget.other_email)) {
          _navigateAwayFromProfile();
        }
      }
    });
  }

  void _navigateAwayFromProfile() {
    if (mounted) {
      Navigator.of(context).pop(); // Navigate back to the previous screen
    }
  }

  @override
  void initState() {
    super.initState();
    _userRef = FirebaseDatabase.instance.ref("users/${widget.email}");
    _loadProfileImage();
    _listenToUserData();
    _listenToBlockStatus(); // Start listening for block status changes
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _listenToUserData() {
    _userSubscription = _userRef?.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        setState(() {
          _name = snapshot.child('name').value.toString();
          _phone = '+88' + snapshot.child('phone').value.toString();
          _address = snapshot.child('address').value.toString();
          _selectedGender = snapshot.child('gender').value.toString();
          _aboutMe = snapshot.child('aboutMe').value.toString();
        });
      }
    });
  }

  Future<void> _loadProfileImage() async {
    try {
      String filePath = 'users/${widget.email}/profile_pic.png';
      String downloadUrl =
      await FirebaseStorage.instance.ref(filePath).getDownloadURL();

      // Add a unique query parameter to the URL to bypass the cache
      String uniqueUrl = '$downloadUrl?timestamp=${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        _profileImageUrl = uniqueUrl;
      });
    } catch (e) {
      print('Failed to load profile image: $e');
      setState(() {
        _profileImageUrl = null;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunch(phoneUri.toString())) {
      await launch(phoneUri.toString());
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );

    if (await canLaunch(emailUri.toString())) {
      await launch(emailUri.toString());
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.SENDTO',
        data: emailUri.toString(),
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      try {
        await intent.launch();
      } catch (e) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('No Email App Found'),
              content: Text(
                  'Could not launch $email. Please check your email app settings.'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Email App Found'),
            content: Text(
                'Could not launch $email. Please check your email app settings.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _unfriendUser() async {
    String e1 = widget.email;
    String e2 = widget.other_email;

    final DatabaseReference ref1_1 =
    FirebaseDatabase.instance.ref("users/$e1/friend/");
    final DatabaseReference ref1_2 =
    FirebaseDatabase.instance.ref("users/$e2/friend/");

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

    DataSnapshot snapshot2 = await ref1_2.get();
    if (snapshot2.exists) {
      Map<dynamic, dynamic> requestsSent =
      snapshot2.value as Map<dynamic, dynamic>;
      for (var key in requestsSent.keys) {
        if (requestsSent[key] == e1) {
          // Key found, now delete it
          await ref1_2.child(key).remove();
          break;
        }
      }
    }
  }

  Future<void> _blockUser() async {
    String e1 = widget.email;
    String e2 = widget.other_email;

    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String formattedTime = timestamp.toString();

    final DatabaseReference ref1_1 =
    FirebaseDatabase.instance.ref("users/$e1/request_sent/");
    final DatabaseReference ref1_2 =
    FirebaseDatabase.instance.ref("users/$e2/friend_request/");

    // Retrieve the data for e2's request_sent
    DataSnapshot snapshot1_1 = await ref1_1.get();
    if (snapshot1_1.exists) {
      Map<dynamic, dynamic> requestsSent =
      snapshot1_1.value as Map<dynamic, dynamic>;
      for (var key in requestsSent.keys) {
        if (requestsSent[key] == e2) {
          // Key found, now delete it
          await ref1_1.child(key).remove();
          break;
        }
      }
    }

    // Retrieve the data for e1's friend_request
    DataSnapshot snapshot1_2 = await ref1_2.get();
    if (snapshot1_2.exists) {
      Map<dynamic, dynamic> friendRequests =
      snapshot1_2.value as Map<dynamic, dynamic>;
      for (var key in friendRequests.keys) {
        if (friendRequests[key] == e1) {
          // Key found, now delete it
          await ref1_2.child(key).remove();
          break;
        }
      }
    }

    final DatabaseReference ref2_1 =
    FirebaseDatabase.instance.ref("users/$e2/request_sent/");
    final DatabaseReference ref2_2 =
    FirebaseDatabase.instance.ref("users/$e1/friend_request/");

    // Retrieve the data for e2's request_sent
    DataSnapshot snapshot2_1 = await ref2_1.get();
    if (snapshot2_1.exists) {
      Map<dynamic, dynamic> requestsSent =
      snapshot2_1.value as Map<dynamic, dynamic>;
      for (var key in requestsSent.keys) {
        if (requestsSent[key] == e1) {
          // Key found, now delete it
          await ref2_1.child(key).remove();
          break;
        }
      }
    }

    // Retrieve the data for e1's friend_request
    DataSnapshot snapshot2_2 = await ref2_2.get();
    if (snapshot2_2.exists) {
      Map<dynamic, dynamic> friendRequests =
      snapshot2_2.value as Map<dynamic, dynamic>;
      for (var key in friendRequests.keys) {
        if (friendRequests[key] == e2) {
          // Key found, now delete it
          await ref2_2.child(key).remove();
          break;
        }
      }
    }

    final DatabaseReference ref3_1 =
    FirebaseDatabase.instance.ref("users/$e1/friend/");
    final DatabaseReference ref3_2 =
    FirebaseDatabase.instance.ref("users/$e2/friend/");

    // Retrieve the data for e2's request_sent
    DataSnapshot snapshot3_1 = await ref3_1.get();
    if (snapshot3_1.exists) {
      Map<dynamic, dynamic> requestsSent =
      snapshot3_1.value as Map<dynamic, dynamic>;
      for (var key in requestsSent.keys) {
        if (requestsSent[key] == e2) {
          // Key found, now delete it
          await ref3_1.child(key).remove();
          break;
        }
      }
    }

    // Retrieve the data for e1's friend_request
    DataSnapshot snapshot3_2 = await ref3_2.get();
    if (snapshot3_2.exists) {
      Map<dynamic, dynamic> friendRequests =
      snapshot3_2.value as Map<dynamic, dynamic>;
      for (var key in friendRequests.keys) {
        if (friendRequests[key] == e1) {
          // Key found, now delete it
          await ref3_2.child(key).remove();
          break;
        }
      }
    }

    final DatabaseReference ref4_1 =
    FirebaseDatabase.instance.ref("users/$e2/blocked/");
    await ref4_1.child(formattedTime).set(e1);

    final DatabaseReference ref4_2 =
    FirebaseDatabase.instance.ref("users/$e1/blockedBy/");
    await ref4_2.child(formattedTime).set(e2);
  }
  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_remove, color: color_1),
                title: const Text('Unfriend'),
                onTap: () async {
                  // Implement Message functionality here
                  await _unfriendUser();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8.0),
                          Text('This user is no longer your friend'),
                        ],
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      duration: const Duration(seconds: 2), // Set duration for how long the SnackBar will be visible
                    ),
                  );
                  Navigator.pop(context);
                  _navigateAwayFromProfile();
                },

              ),
              ListTile(
                leading: const Icon(Icons.block, color: color_1),
                title: const Text('Block User'),
                onTap: () async {
                  // Implement Call functionality here
                  await _blockUser();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8.0),
                          Text('This user is no longer your friend'),
                        ],
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      duration: const Duration(seconds: 2), // Set duration for how long the SnackBar will be visible
                    ),
                  );
                  Navigator.pop(context);
                  _navigateAwayFromProfile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: Scrollbar(
        thumbVisibility: true,
        thickness: 6.0,
        radius: const Radius.circular(10.0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!) as ImageProvider
                      : (_profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!) as ImageProvider
                      : (_selectedGender == 'Female'
                      ? const AssetImage('assets/female.png')
                      : const AssetImage('assets/male.png'))),
                  backgroundColor: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Implement Add Friend functionality here
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white,
                        onPrimary: color_1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                      ),
                      icon: const Icon(Icons.message),
                      label: const Text('Message'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Implement Block User functionality here
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white,
                        onPrimary: color_1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                      ),
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: color_1),
                      onPressed: () => _showBottomSheet(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildProfileField('Name', _name),
              const SizedBox(height: 12),

              _buildProfileFieldWithIcon(
                'Email',
                formattedEmail(widget.email),
                Icons.email_outlined,
                    () {
                  _sendEmail(formattedEmail(widget.email));
                },
              ),
              const SizedBox(height: 12),

              _buildProfileFieldWithIcon(
                'Phone',
                _phone,
                Icons.phone_outlined,
                    () {
                  if (_phone != null && _phone!.isNotEmpty) {
                    _makePhoneCall(_phone!);
                  }
                },
              ),
              const SizedBox(height: 12),

              _buildProfileField('Address', _address),
              const SizedBox(height: 12),

              _buildProfileField('Gender', _selectedGender),
              const SizedBox(height: 12),

              _buildProfileField('About', _aboutMe),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: subtitleColor),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5.0), // Adjusts space between subtitle and text
          child: Text(
            value ?? '',
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileFieldWithIcon(
      String label, String? value, IconData icon, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: subtitleColor),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5.0), // Adjusts space between subtitle and text
          child: Text(
            value ?? '',
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        trailing: IconButton(
          icon: Icon(icon, color: color_1),
          onPressed: onPressed,
        ),
      ),
    );
  }

  String formattedEmail(String email) {
    return email.replaceAll('_dot_', '.').replaceAll('_at_', '@');
  }
}
