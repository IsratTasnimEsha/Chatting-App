import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

const Color color_1 = Color(0xFF8ba16a);
const Color errorColor = Colors.red;

bool _obscurePassword = true;
bool _obscureConfirmPassword = true;

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for each TextField
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _selectedGender;
  File? _profileImage;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing the dialog by tapping outside
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color_1),
          ),
        );
      },
    );
  }

  void _hideLoadingIndicator(BuildContext context) {
    Navigator.of(context).pop(); // Close the loading indicator
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
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
                      CircleAvatar(
                        radius: 80,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : AssetImage('assets/placeholder.png')
                                as ImageProvider,
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Name TextField
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(fontWeight: FontWeight.normal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 18.0),
                    filled: true,
                    fillColor: Colors.grey[200],
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color_1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.normal),
                  maxLines: null,
                  // Allow unlimited lines
                  keyboardType: TextInputType.multiline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email TextField
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(fontWeight: FontWeight.normal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 18.0),
                    filled: true,
                    fillColor: Colors.grey[200],
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color_1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.normal),
                  // Text style
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                        .hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone TextField
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: TextEditingController(text: '+88'),
                        readOnly: true,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'Country Code',
                          labelStyle: TextStyle(fontWeight: FontWeight.normal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 18.0),
                          filled: true,
                          fillColor: Colors.grey[200],
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        keyboardType: TextInputType.phone,
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(fontWeight: FontWeight.normal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 18.0),
                          filled: true,
                          fillColor: Colors.grey[200],
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: color_1),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        style: TextStyle(fontWeight: FontWeight.normal),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            // return 'Please enter your phone number';
                          } else if (value.length != 11 ||
                              value.substring(0, 2) != '01') {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Address TextField
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(fontWeight: FontWeight.normal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 18.0),
                    filled: true,
                    fillColor: Colors.grey[200],
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color_1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.normal),
                  // Text style
                  maxLines: null,
                  // Allow unlimited lines
                  keyboardType: TextInputType
                      .multiline, // Ensures the keyboard has a newline option
                ),
                const SizedBox(height: 16),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 18.0),
                    filled: true,
                    fillColor: Colors.grey[200],
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color_1),
                      // Use your color variable here
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Male',
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Male',
                            style: TextStyle(fontWeight: FontWeight.normal)),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Female',
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Female',
                            style: TextStyle(fontWeight: FontWeight.normal)),
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
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                  style: const TextStyle(color: Colors.black),
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  // Allow the dropdown to fill available space (better UX)
                  alignment: Alignment.centerLeft,
                  // Left align text in the dropdown items
                  borderRadius: BorderRadius.circular(12.0),
                  // Rounded corners for the dropdown
                  menuMaxHeight: 200, // Set a max height for the dropdown menu
                ),
                const SizedBox(height: 16),

                // About Me TextField
                TextFormField(
                  controller: _aboutMeController,
                  decoration: InputDecoration(
                    labelText: 'About Me',
                    labelStyle: TextStyle(fontWeight: FontWeight.normal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 18.0),
                    filled: true,
                    fillColor: Colors.grey[200],
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color_1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.normal),
                  // Text style
                  maxLines: null,
                  // Allow unlimited lines
                  keyboardType: TextInputType
                      .multiline, // Ensures the keyboard has a newline option
                ),
                const SizedBox(height: 16),

                // Password TextField
                // Password TextField
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  // Toggle for password visibility
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(fontWeight: FontWeight.normal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 18.0),
                    filled: true,
                    fillColor: Colors.grey[200],
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color_1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.normal),
                  // Text style
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password TextField
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  // Toggle for password visibility
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(fontWeight: FontWeight.normal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 18.0),
                    filled: true,
                    fillColor: Colors.grey[200],
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color_1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.normal),
                  // Text style
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    } else if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 5,
                      backgroundColor: color_1,
                    ),
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        _showLoadingIndicator(context); // Show loading indicator
                        try {
                          final credential = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );

                          if (_selectedGender.toString() != 'Male' ||
                              _selectedGender.toString() != 'Female') {
                            _selectedGender = 'Not Selected';
                          }

                          saveToRealtimeDatabase(
                            _nameController.text.trim(),
                            _emailController.text.trim(),
                            _phoneController.text.trim(),
                            _addressController.text.trim(),
                            _selectedGender.toString(),
                            _aboutMeController.text.trim(),
                          );

                          String? imageUrl;
                          String email = credential.user?.email ?? '';
                          String formattedEmail = formatEmailForFirebase(email);

                          Reference storageRef = await FirebaseStorage.instance
                              .ref()
                              .child('users/$formattedEmail/profile_pic.png');

                          UploadTask uploadTask =
                              storageRef.putFile(_profileImage!);
                          TaskSnapshot snapshot = await uploadTask;
                          imageUrl = await snapshot.ref.getDownloadURL();

                          Navigator.pushNamed(context, '/signin');

                          // Save data to Realtime Database
                        } on FirebaseAuthException catch (e) {
                          String errorMessage;

                          if (e.code == 'email-already-in-use') {
                            errorMessage =
                                'The account already exists for that email.';
                          } else if (e.code == 'weak-password') {
                            errorMessage = 'The password provided is too weak.';
                          } else if (e.code == 'invalid-email') {
                            errorMessage = 'The email provided is invalid.';
                          } else {
                            errorMessage =
                                'An error occurred. Please try again.';
                          }

                          // Show the error message in a dialog or using a snackbar
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Sign Up Error'),
                                content: Text(errorMessage),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Already have an account? Sign In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        // Navigate to the Sign Up page
                        Navigator.pushNamed(context, '/signin');
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(color: color_1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  saveToRealtimeDatabase(String name, String email, String phone,
      String address, String gender, String about_me) async {
    final formattedEmail = formatEmailForFirebase(email);
    final DatabaseReference ref =
        await FirebaseDatabase.instance.ref("users/$formattedEmail");

    // Example of saving some data
    ref.set({
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'gender': gender,
      'aboutMe': about_me,
      'activeStatus': 'off'
    });
  }

  String formatEmailForFirebase(String email) {
    return email.replaceAll('.', '_dot_').replaceAll('@', '_at_');
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
            ],
          ),
        );
      },
    );
  }
}
