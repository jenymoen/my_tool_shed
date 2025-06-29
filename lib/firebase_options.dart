// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  static String _getEnvVar(String key) {
    try {
      return dotenv.env[key] ?? '';
    } catch (e) {
      print(
          'Warning: Environment variable $key not found. Using empty string.');
      return '';
    }
  }

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

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _getEnvVar('FIREBASE_API_KEY_WEB'),
        appId: _getEnvVar('FIREBASE_APP_ID_WEB'),
        messagingSenderId: _getEnvVar('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _getEnvVar('FIREBASE_PROJECT_ID'),
        authDomain: _getEnvVar('FIREBASE_AUTH_DOMAIN'),
        storageBucket: _getEnvVar('FIREBASE_STORAGE_BUCKET'),
        measurementId: _getEnvVar('FIREBASE_MEASUREMENT_ID_WEB'),
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _getEnvVar('FIREBASE_API_KEY_ANDROID'),
        appId: _getEnvVar('FIREBASE_APP_ID_ANDROID'),
        messagingSenderId: _getEnvVar('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _getEnvVar('FIREBASE_PROJECT_ID'),
        storageBucket: _getEnvVar('FIREBASE_STORAGE_BUCKET'),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _getEnvVar('FIREBASE_API_KEY_IOS'),
        appId: _getEnvVar('FIREBASE_APP_ID_IOS'),
        messagingSenderId: _getEnvVar('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _getEnvVar('FIREBASE_PROJECT_ID'),
        storageBucket: _getEnvVar('FIREBASE_STORAGE_BUCKET'),
        iosBundleId: _getEnvVar('FIREBASE_IOS_BUNDLE_ID'),
      );

  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: _getEnvVar('FIREBASE_API_KEY_IOS'),
        appId: _getEnvVar('FIREBASE_APP_ID_IOS'),
        messagingSenderId: _getEnvVar('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _getEnvVar('FIREBASE_PROJECT_ID'),
        storageBucket: _getEnvVar('FIREBASE_STORAGE_BUCKET'),
        iosBundleId: _getEnvVar('FIREBASE_IOS_BUNDLE_ID'),
      );

  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: _getEnvVar('FIREBASE_API_KEY_WEB'),
        appId: _getEnvVar('FIREBASE_APP_ID_WINDOWS'),
        messagingSenderId: _getEnvVar('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _getEnvVar('FIREBASE_PROJECT_ID'),
        authDomain: _getEnvVar('FIREBASE_AUTH_DOMAIN'),
        storageBucket: _getEnvVar('FIREBASE_STORAGE_BUCKET'),
        measurementId: _getEnvVar('FIREBASE_MEASUREMENT_ID_WINDOWS'),
      );
}
