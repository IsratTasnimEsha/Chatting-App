import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'signup.dart'; // Import your SignUpPage
import 'signin.dart'; // Import your SignInPage
import 'home.dart';
import 'view_profile.dart';

const Color color_1 = Color(0xFF8ba16a);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedEmail = prefs.getString('rememberedEmail');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp(savedEmail: savedEmail));
}

class MyApp extends StatelessWidget {
  final String? savedEmail;

  const MyApp({Key? key, this.savedEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the 'DEBUG' watermark
      theme: ThemeData(
        useMaterial3: true, // Material 3 theming enabled
        primaryColor: color_1, // Set the primary color globally
        scaffoldBackgroundColor: Colors.white, // Set scaffold background globally
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.black, // Set default text color globally
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: color_1,
          primary: color_1,
          onPrimary: Colors.black, // Set the onPrimary color to black
        ),
      ),
      home: savedEmail != null
          ? HomePage(email: formatEmailForFirebase(savedEmail!))
          : SignInPage(),
      routes: {
        // Define your routes here
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/viewFriendProfile': (context) => ViewProfilePage(
          // Assuming ViewProfilePage takes email as an argument
          email: ModalRoute.of(context)!.settings.arguments as String,
          other_email: ModalRoute.of(context)!.settings.arguments as String,
        ),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/viewProfile') {
          final args = settings.arguments as Map<String, String>;

          return MaterialPageRoute(
            builder: (context) {
              return ViewProfilePage(
                email: args['email']!,
                other_email: args['other_email']!,
              );
            },
          );
        }
      },

    );
  }

  String formatEmailForFirebase(String email) {
    return email.replaceAll('.', '_dot_').replaceAll('@', '_at_');
  }
}