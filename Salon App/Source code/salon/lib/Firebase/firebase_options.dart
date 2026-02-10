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
    apiKey: 'AIzaSyAXQvZRaJbWRagQRXKpMoTjqYTipm6PZtY',
    appId: '1:624818969498:web:93629802c2633b1247f823',
    messagingSenderId: '624818969498',
    projectId: 'merry-queen',
    authDomain: 'merry-queen.firebaseapp.com',
    storageBucket: 'merry-queen.firebasestorage.app',
    measurementId: 'G-B45B1XPQ0C',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBFAkViZTxnpkDRWKqF965jHcVuWw3Jzwk',
    appId: '1:624818969498:android:e15dad6962a0563a47f823',
    messagingSenderId: '624818969498',
    projectId: 'merry-queen',
    storageBucket: 'merry-queen.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB5iBnp0711WU22GuzeN6Dx0hUb6orEya4',
    appId: '1:624818969498:ios:620a65ca327f687547f823',
    messagingSenderId: '624818969498',
    projectId: 'merry-queen',
    storageBucket: 'merry-queen.firebasestorage.app',
    iosBundleId: 'com.example.salon',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB5iBnp0711WU22GuzeN6Dx0hUb6orEya4',
    appId: '1:624818969498:ios:620a65ca327f687547f823',
    messagingSenderId: '624818969498',
    projectId: 'merry-queen',
    storageBucket: 'merry-queen.firebasestorage.app',
    iosBundleId: 'com.example.salon',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAXQvZRaJbWRagQRXKpMoTjqYTipm6PZtY',
    appId: '1:624818969498:web:d2dc6fdd934a97f347f823',
    messagingSenderId: '624818969498',
    projectId: 'merry-queen',
    authDomain: 'merry-queen.firebaseapp.com',
    storageBucket: 'merry-queen.firebasestorage.app',
    measurementId: 'G-3YMG593Y9Y',
  );
}
