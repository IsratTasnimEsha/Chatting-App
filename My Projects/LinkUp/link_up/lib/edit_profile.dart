import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

const Color color_1 = Color(0xFF8ba16a);
const Color errorColor = Colors.red;

class EditProfilePage extends StatefulWidget {
  final String email;

  const EditProfilePage({Key? key, required this.email}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String? _profileImageUrl;

  // Controllers for each TextField
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _selectedGender;
  final TextEditingController _aboutMeController = TextEditingController();
  File? _profileImage;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileImage();
  }

  void _loadUserData() async {
    final DatabaseReference ref =
    FirebaseDatabase.instance.ref("users/${widget.email}");

    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      setState(() {
        _nameController.text = snapshot.child('name').value.toString();
        _phoneController.text = snapshot.child('phone').value.toString();
        _addressController.text = snapshot.child('address').value.toString();
        _selectedGender = snapshot.child('gender').value.toString();
        _aboutMeController.text = snapshot.child('aboutMe').value.toString();
      });
    }
  }

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

  bool _isNameEditing = false;
  bool _isAddressEditing = false;
  bool _isPhoneEditing = false;
  bool _isGenderEditing = false;
  bool _isAboutMeEditing = false;

  // Create a reference to your Firebase Realtime Database
  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.reference().child('users');

  void _toggleNameEditing() async {
    setState(() {
      _isNameEditing = !_isNameEditing;
    });

    if (!_isNameEditing) {
      if (_formKey.currentState?.validate() ?? false) {
        // Save data to Firebase Realtime Database
        String name = _nameController.text;
        if (name.isNotEmpty) {
          try {
            // Update Firebase Realtime Database with the name
            await _dbRef.child(widget.email).update({
              'name': name,
            });
            // Optionally show a success message or handle other logic
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Name saved successfully')),
            );
          } catch (e) {
            // Handle any errors that occur
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save name: $e')),
            );
          }
        }
      }
    }
  }

  void _togglePhoneEditing() async {
    setState(() {
      _isPhoneEditing = !_isPhoneEditing;
    });

    if (!_isPhoneEditing) {
      // Save data to Firebase Realtime Database
      String phone = _phoneController.text;
      if (phone.isNotEmpty) {
        try {
          // Update Firebase Realtime Database with the phone
          await _dbRef.child(widget.email).update({
            'phone': phone,
          });
          // Optionally show a success message or handle other logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Phone saved successfully')),
          );
        } catch (e) {
          // Handle any errors that occur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save phone: $e')),
          );
        }
      }
    }
  }

  void _toggleAddressEditing() async {
    setState(() {
      _isAddressEditing = !_isAddressEditing;
    });

    if (!_isAddressEditing) {
      // Save data to Firebase Realtime Database
      String address = _addressController.text;
      if (address.isNotEmpty) {
        try {
          // Update Firebase Realtime Database with the address
          await _dbRef.child(widget.email).update({
            'address': address,
          });
          // Optionally show a success message or handle other logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Address saved successfully')),
          );
        } catch (e) {
          // Handle any errors that occur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save address: $e')),
          );
        }
      }
    }
  }

  void _toggleGenderEditing() async {
    setState(() {
      _isGenderEditing = !_isGenderEditing;
    });

    if (!_isGenderEditing) {
      // Save data to Firebase Realtime Database
      String gender = _selectedGender.toString();
      if (gender.isNotEmpty) {
        try {
          // Update Firebase Realtime Database with the gender
          await _dbRef.child(widget.email).update({
            'gender': gender,
          });
          // Optionally show a success message or handle other logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gender saved successfully')),
          );
        } catch (e) {
          // Handle any errors that occur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save gender: $e')),
          );
        }
      }
    }
  }

  void _toggleAboutMeEditing() async {
    setState(() {
      _isAboutMeEditing = !_isAboutMeEditing;
    });

    if (!_isAboutMeEditing) {
      // Save data to Firebase Realtime Database
      String aboutMe = _aboutMeController.text;
      if (aboutMe.isNotEmpty) {
        try {
          // Update Firebase Realtime Database with the about me
          await _dbRef.child(widget.email).update({
            'aboutMe': aboutMe,
          });
          // Optionally show a success message or handle other logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('About Me saved successfully')),
          );
        } catch (e) {
          // Handle any errors that occur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save about me: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
      ),
      body: Scrollbar(
        thumbVisibility: true,
        thickness: 6.0,
        radius: const Radius.circular(10.0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Center(
                  child: Stack(
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 80,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!) as ImageProvider
                                  : (_profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!) as ImageProvider
                                  : (_selectedGender == 'Female'
                                  ? AssetImage('assets/female.png') as ImageProvider
                                  : AssetImage('assets/male.png') as ImageProvider)),
                              backgroundColor: Colors.grey[200],
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _showImagePickerOptions(context),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color_1,
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0, // Position this button at the bottom-left corner
                              child: GestureDetector(
                                onTap: () async {
                                  // Implement the action for saving the image here
                                  String? imageUrl;
                                  String email = widget.email;

                                  Reference storageRef = await FirebaseStorage.instance.ref().child('users/$email/profile_pic.png');

                                  UploadTask uploadTask = storageRef.putFile(_profileImage!);
                                  TaskSnapshot snapshot = await uploadTask;
                                  imageUrl = await snapshot.ref.getDownloadURL();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Profile picture uploaded successfully')),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Colors.pinkAccent, Colors.purpleAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: const Icon(
                                    Icons.save,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Name TextField
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(fontWeight: FontWeight.normal),
                          border: _isNameEditing
                              ? UnderlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                          )
                              : InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          filled: true,
                          fillColor: Colors.transparent,
                          enabledBorder: _isNameEditing
                              ? UnderlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                          )
                              : InputBorder.none,
                          focusedBorder: _isNameEditing
                              ? UnderlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                          )
                              : InputBorder.none,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.normal),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                        enabled: _isNameEditing, // Toggle editability
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isNameEditing ? Icons.check : Icons.edit,
                        color: color_1,
                      ),
                      onPressed: _toggleNameEditing,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Phone TextField
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.phone,
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(fontWeight: FontWeight.normal),
                          prefixText: '+88 ',
                          prefixStyle: TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                          border: _isPhoneEditing
                              ? UnderlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                          )
                              : InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          filled: true,
                          fillColor: Colors.transparent,
                          enabledBorder: _isPhoneEditing
                              ? UnderlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                          )
                              : InputBorder.none,
                          focusedBorder: _isPhoneEditing
                              ? UnderlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                          )
                              : InputBorder.none,
                        ),
                        style: TextStyle(fontWeight: FontWeight.normal),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                          } else if (value.length != 11 ||
                              value.substring(0, 2) != '01') {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                        enabled: _isPhoneEditing, // Toggle editability
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isPhoneEditing ? Icons.check : Icons.edit,
                        color: color_1,
                      ),
                      onPressed: _togglePhoneEditing,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Address TextField
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          labelStyle: TextStyle(fontWeight: FontWeight.normal),
                          border: _isAddressEditing
                              ? UnderlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                          )
                              : InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          filled: true,
                          fillColor: Colors.transparent,
                          enabledBorder: _isAddressEditing
                              ? UnderlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                          )
                              : InputBorder.none,
                          focusedBorder: _isAddressEditing
                              ? UnderlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                          )
                              : InputBorder.none,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.normal),
                        enabled: _isAddressEditing,
                        // Toggle editability
                        maxLines: null,
                        // Allow unlimited lines
                        keyboardType: TextInputType
                            .multiline, // Ensures the keyboard has a newline option
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isAddressEditing ? Icons.check : Icons.edit,
                        color: color_1,
                      ),
                      onPressed: _toggleAddressEditing,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Gender Dropdown
                Row(
                  children: [
                    Expanded(
                      child: _isGenderEditing
                          ? DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          labelStyle: const TextStyle(
                              fontWeight: FontWeight.normal),
                          // No explicit font size
                          border: InputBorder.none,
                          // No border during editing
                          enabledBorder: InputBorder.none,
                          // No border when not focused
                          focusedBorder: InputBorder.none,
                          // No border when focused
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Male',
                            child: Padding(
                              padding:
                              EdgeInsets.symmetric(horizontal: 0.0),
                              child: Text('Male',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight
                                          .normal)), // No explicit font size
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Padding(
                              padding:
                              EdgeInsets.symmetric(horizontal: 0.0),
                              child: Text('Female',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight
                                          .normal)), // No explicit font size
                            ),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGender = newValue;
                          });
                        },
                        hint: const Text(
                          'Select your gender',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal), // No explicit font size
                        ),
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        alignment: Alignment.centerLeft,
                        borderRadius: BorderRadius.circular(12.0),
                        menuMaxHeight: 200,
                      )
                          : InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          labelStyle: const TextStyle(
                              fontWeight: FontWeight.normal),
                          // No explicit font size
                          border: InputBorder.none,
                          // No border when not editing
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                        ),
                        child: Text(
                          _selectedGender ?? 'Not selected',
                          style: const TextStyle(
                              fontWeight: FontWeight
                                  .normal), // No explicit font size
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isGenderEditing ? Icons.check : Icons.edit,
                        color: color_1,
                      ),
                      onPressed: _toggleGenderEditing,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // About Me TextField
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _aboutMeController,
                        decoration: InputDecoration(
                          labelText: 'About Me',
                          labelStyle: TextStyle(fontWeight: FontWeight.normal),
                          border: _isAboutMeEditing
                              ? UnderlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                          )
                              : InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          filled: true,
                          fillColor: Colors.transparent,
                          enabledBorder: _isAboutMeEditing
                              ? UnderlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                          )
                              : InputBorder.none,
                          focusedBorder: _isAboutMeEditing
                              ? UnderlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                          )
                              : InputBorder.none,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.normal),
                        enabled: _isAboutMeEditing,
                        // Toggle editability
                        maxLines: null,
                        // Allow unlimited lines
                        keyboardType: TextInputType
                            .multiline, // Ensures the keyboard has a newline option
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isAboutMeEditing ? Icons.check : Icons.edit,
                        color: color_1,
                      ),
                      onPressed: _toggleAboutMeEditing,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete), // Icon changed to a delete icon
                title: Text('Delete photo'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Are you sure?"),
                        content: Text("Do you want to delete this photo?"),
                        actions: [
                          TextButton(
                            child: Text("No"),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                          ),
                          TextButton(
                            child: Text("Yes"),
                            onPressed: () async {
                              // Delete the photo from storage
                              try {
                                await FirebaseStorage.instance
                                    .ref(
                                    'users/${widget.email}/profile_pic.png')
                                    .delete();
                              } catch (e) {
                                print("Error deleting photo: $e");
                              }

                              Navigator.of(context).pop(); // Close the dialog
                              Navigator.of(context)
                                  .pop(); // Close the ListTile menu
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}