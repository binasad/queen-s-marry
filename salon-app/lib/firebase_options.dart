// marry-queen Firebase project
// For Android/iOS: Add apps in Firebase Console (marry-queen) and run: flutterfire configure
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

  // marry-queen Firebase project
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCuZHbiZlBfJmqFFHUkkIcipOS0WhmAfVM',
    appId: '1:229108556395:web:f0cad17cc59b41f343c72e',
    messagingSenderId: '229108556395',
    projectId: 'marry-queen',
    authDomain: 'marry-queen.firebaseapp.com',
    databaseURL: 'https://marry-queen-default-rtdb.firebaseio.com',
    storageBucket: 'marry-queen.firebasestorage.app',
    measurementId: 'G-18FNN8LL7B',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuZHbiZlBfJmqFFHUkkIcipOS0WhmAfVM',
    appId: '1:229108556395:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: '229108556395',
    projectId: 'marry-queen',
    databaseURL: 'https://marry-queen-default-rtdb.firebaseio.com',
    storageBucket: 'marry-queen.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCuZHbiZlBfJmqFFHUkkIcipOS0WhmAfVM',
    appId: '1:229108556395:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '229108556395',
    projectId: 'marry-queen',
    databaseURL: 'https://marry-queen-default-rtdb.firebaseio.com',
    storageBucket: 'marry-queen.firebasestorage.app',
    iosClientId:
        '229108556395-YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
    iosBundleId: 'com.example.salon',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCuZHbiZlBfJmqFFHUkkIcipOS0WhmAfVM',
    appId: '1:229108556395:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '229108556395',
    projectId: 'marry-queen',
    databaseURL: 'https://marry-queen-default-rtdb.firebaseio.com',
    storageBucket: 'marry-queen.firebasestorage.app',
    iosClientId:
        '229108556395-YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
    iosBundleId: 'com.example.salon',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCuZHbiZlBfJmqFFHUkkIcipOS0WhmAfVM',
    appId: '1:229108556395:web:f0cad17cc59b41f343c72e',
    messagingSenderId: '229108556395',
    projectId: 'marry-queen',
    authDomain: 'marry-queen.firebaseapp.com',
    databaseURL: 'https://marry-queen-default-rtdb.firebaseio.com',
    storageBucket: 'marry-queen.firebasestorage.app',
    measurementId: 'G-18FNN8LL7B',
  );
}
