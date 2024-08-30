import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

const Color color_1 = Colors.blue;

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _rememberMe = false;

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
        title: const Text('Sign In'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400, // Adjust width as needed
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 18.0),
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password TextField
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(fontWeight: FontWeight.normal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 18.0),
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
                          _obscureText ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.normal),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sign In Button
                  ElevatedButton(
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
                          final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );
                          _hideLoadingIndicator(context); // Hide loading indicator on success

                          // Successfully signed in
                          // Save email in SharedPreferences if "Remember me" is checked
                          final SharedPreferences prefs = await SharedPreferences.getInstance();
                          if (_rememberMe) {
                            await prefs.setString('rememberedEmail', _emailController.text.trim());
                          }
                          // Navigate to the home screen and pass the formatted email
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(email: formatEmailForFirebase(_emailController.text.trim())),
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          _hideLoadingIndicator(context); // Hide loading indicator on error

                          String errorMessage;

                          if (e.code == 'user-not-found') {
                            errorMessage = 'No user found for that email.';
                          } else if (e.code == 'wrong-password') {
                            errorMessage = 'Wrong password provided for that user.';
                          } else {
                            errorMessage = 'An error occurred. Please try again.';
                          }

                          // Show the error message using a SnackBar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Sign In',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  // Remember me Checkbox
                  Row(
                    children: [
                      Transform.scale(
                        scale: 0.75, // Smaller checkbox
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: color_1, // Color when checked
                          checkColor: Colors.white, // Color of the check mark
                          side: BorderSide(color: Colors.black), // Border color
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Adjust tap target size
                        ),
                      ),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          fontSize: 14, // Smaller font size
                          color: Colors.black, // Custom text color
                        ),
                      ),
                    ],
                  ),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        // Get the email from the user
                        String email = _emailController.text.trim();

                        // Check if the email is not empty
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please enter your email address'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }

                        try {
                          // Send password reset email
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Password reset email sent!'),
                              backgroundColor: color_1,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );

                          // Navigate back to Sign In page
                          Navigator.pop(context);
                        } on FirebaseAuthException catch (e) {
                          // Handle errors
                          String errorMessage;

                          if (e.code == 'invalid-email') {
                            errorMessage = 'Invalid email address.';
                          } else if (e.code == 'user-not-found') {
                            errorMessage = 'No user found with that email address.';
                          } else {
                            errorMessage = 'An error occurred. Please try again.';
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(color: Colors.black, fontStyle: FontStyle.normal),
                      ),
                    ),
                  ),

                  // Don't have an account? Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Don\'t have an account?'),
                      TextButton(
                        onPressed: () {
                          // Navigate to the Sign Up page
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: const Text(
                          'Sign Up',
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
      ),
    );
  }
}

String formatEmailForFirebase(String email) {
  return email.replaceAll('.', '_dot_').replaceAll('@', '_at_');
}
