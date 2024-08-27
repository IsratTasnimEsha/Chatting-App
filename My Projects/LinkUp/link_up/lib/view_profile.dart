import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

class ViewProfilePage extends StatefulWidget {
  final String email;
  final String other_email;

  const ViewProfilePage({
    Key? key,
    required this.email,
    required this.other_email,
  }) : super(key: key);

  @override
  _ViewProfilePageState createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  String? _profileImageUrl;
  String? _name;
  String? _phone;
  String? _address;
  String? _selectedGender;
  String? _aboutMe;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileImage();
  }

  void _loadUserData() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref("users/${widget.email}");
    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      setState(() {
        _name = snapshot.child('name').value.toString();
        _phone = '+88' + snapshot.child('phone').value.toString();
        _address = snapshot.child('address').value.toString();
        _selectedGender = snapshot.child('gender').value.toString();
        _aboutMe = snapshot.child('aboutMe').value.toString();
      });
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      String filePath = 'users/${widget.email}/profile_pic.png';
      String downloadUrl = await FirebaseStorage.instance.ref(filePath).getDownloadURL();

      setState(() {
        _profileImageUrl = downloadUrl;
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
        _showEmailAppNotFoundDialog(email);
      }
    } else {
      _showEmailAppNotFoundDialog(email);
    }
  }

  void _showEmailAppNotFoundDialog(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Email App Found'),
          content: Text('Could not launch $email. Please check your email app settings.'),
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

  Future<void> _blockUser() async {
    // Show confirmation dialog
    final shouldBlock = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Block'),
          content: const Text('Are you sure you want to block this user?'),
          backgroundColor: Colors.white,
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // Sets the text color to red
              ),
              child: const Text('Block'),
              onPressed: () {
                Navigator.of(context).pop(true); // User confirms
              },
            ),
          ],
        );
      },
    );

    if (shouldBlock == true) {
      // Implement Block User functionality
      try {
        String e1 = widget.email;
        String e2 = widget.other_email;

        int timestamp = DateTime.now().millisecondsSinceEpoch;
        String formattedTime = timestamp.toString();

        final DatabaseReference ref1 = FirebaseDatabase.instance.ref("users/$e2/blocked/");
        await ref1.child(formattedTime).set(e1);

        final DatabaseReference ref2 = FirebaseDatabase.instance.ref("users/$e1/blocked_by/");
        await ref2.child(formattedTime).set(e2);

        // Optionally show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User blocked successfully')),
        );
      } catch (e) {
        // Handle any errors that occur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block user: $e')),
        );
      }
    }
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
                child: ElevatedButton.icon(
                  onPressed: _blockUser,
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white,
                    onPrimary: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  ),
                  icon: const Icon(Icons.block),
                  label: const Text('Block User'),
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
          style: const TextStyle(
            color: subtitleColor,
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5.0),
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

  Widget _buildProfileFieldWithIcon(String label, String? value, IconData icon, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          style: const TextStyle(
            color: subtitleColor,
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5.0),
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
          onPressed: onTap,
        ),
      ),
    );
  }
}

String formattedEmail(String email) {
  return email.replaceAll('_dot_', '.').replaceAll('_at_', '@');
}
