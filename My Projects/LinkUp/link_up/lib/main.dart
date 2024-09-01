import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:firebase_database/firebase_database.dart'; // for Firebase Realtime Database
import 'package:provider/provider.dart'; // Import provider
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'signup.dart'; // Import your SignUpPage
import 'signin.dart'; // Import your SignInPage
import 'home.dart';
import 'view_profile.dart';
import 'view_friend_profile.dart';
import 'user_message.dart';
import 'theme_provider.dart'; // Import your ThemeProvider

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FlutterDownloader.initialize();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedEmail = prefs.getString('rememberedEmail');

  // Fetch the color from Firebase if the user is signed in
  Color fetchedColor = Colors.blue;
  if (savedEmail != null) {
    final databaseReference = FirebaseDatabase.instance.ref();
    final colorSnapshot = await databaseReference.child(
        'users/${formatEmailForFirebase(savedEmail)}/appColor').get();
    if (colorSnapshot.exists) {
      final colorValue = colorSnapshot.value as String?;
      if (colorValue != null) {
        fetchedColor = Color(int.parse(colorValue, radix: 16));
      }
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider()..setColor(fetchedColor),
      child: MyApp(savedEmail: savedEmail),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? savedEmail;

  const MyApp({Key? key, this.savedEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: themeProvider.color, // Use the dynamic color
            scaffoldBackgroundColor: Colors.white,
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.black,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeProvider.color,
              primary: themeProvider.color,
              onPrimary: Colors.black,
            ),
          ),
          home: savedEmail != null
              ? HomePage(email: formatEmailForFirebase(savedEmail!))
              : SignInPage(),
          routes: {
            '/signin': (context) => SignInPage(),
            '/signup': (context) => SignUpPage(),
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
            if (settings.name == '/viewFriendProfile') {
              final args = settings.arguments as Map<String, String>;

              return MaterialPageRoute(
                builder: (context) {
                  return ViewFriendProfilePage(
                    email: args['email']!,
                    other_email: args['other_email']!,
                  );
                },
              );
            }
            if (settings.name == '/userMessage') {
              final args = settings.arguments as Map<String, String>;

              return MaterialPageRoute(
                builder: (context) {
                  return UserMessagePage(
                    email: args['email']!,
                    other_email: args['other_email']!,
                  );
                },
              );
            }
            return null;
          },
        );
      },
    );
  }

  String formatEmailForFirebase(String email) {
    return email.replaceAll('.', '_dot_').replaceAll('@', '_at_');
  }
}
