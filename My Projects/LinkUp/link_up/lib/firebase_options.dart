// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDCTkhUfGTQVWCys986nDrgmvu4djOCJm8',
    appId: '1:622008638968:web:300cf7735dc2e6199eca0d',
    messagingSenderId: '622008638968',
    projectId: 'linkup-d8cca',
    authDomain: 'linkup-d8cca.firebaseapp.com',
    storageBucket: 'linkup-d8cca.appspot.com',
    measurementId: 'G-1GPMNCTB78',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCJrsVqehhvHVUd8NuEyZ45wnNE4YIn6W0',
    appId: '1:622008638968:android:a7790f49ad8ec4949eca0d',
    messagingSenderId: '622008638968',
    projectId: 'linkup-d8cca',
    storageBucket: 'linkup-d8cca.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDIV95fNm_b3I3pIZlHXoZpdFal7MIi9H8',
    appId: '1:622008638968:ios:fe8e99045e05e7259eca0d',
    messagingSenderId: '622008638968',
    projectId: 'linkup-d8cca',
    storageBucket: 'linkup-d8cca.appspot.com',
    iosBundleId: 'com.example.linkUp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDIV95fNm_b3I3pIZlHXoZpdFal7MIi9H8',
    appId: '1:622008638968:ios:fe8e99045e05e7259eca0d',
    messagingSenderId: '622008638968',
    projectId: 'linkup-d8cca',
    storageBucket: 'linkup-d8cca.appspot.com',
    iosBundleId: 'com.example.linkUp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDCTkhUfGTQVWCys986nDrgmvu4djOCJm8',
    appId: '1:622008638968:web:f470dcd2c04994a49eca0d',
    messagingSenderId: '622008638968',
    projectId: 'linkup-d8cca',
    authDomain: 'linkup-d8cca.firebaseapp.com',
    storageBucket: 'linkup-d8cca.appspot.com',
    measurementId: 'G-0SSV10NWYY',
  );
}