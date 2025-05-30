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
/// 

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBlvTuwI-CDdeKzfiL3WZ81debj29qnTuo',
    appId: '1:1007344558521:web:1a7e9661164b0b1f509668',
    messagingSenderId: '1007344558521',
    projectId: 'messapp-9d1bc',
    authDomain: 'messapp-9d1bc.firebaseapp.com',
    storageBucket: 'messapp-9d1bc.firebasestorage.app',
    measurementId: 'G-B5G5ZG75Y8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCErQeaLVFFMg7U5rnGvm0s4GEYh8JFaF8',
    appId: '1:1007344558521:android:988837b36b5d0ca5509668',
    messagingSenderId: '1007344558521',
    projectId: 'messapp-9d1bc',
    storageBucket: 'messapp-9d1bc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBguShRco5B53hE43ShtnUCO1RzUr1-S-A',
    appId: '1:1007344558521:ios:dee08dd208914523509668',
    messagingSenderId: '1007344558521',
    projectId: 'messapp-9d1bc',
    storageBucket: 'messapp-9d1bc.firebasestorage.app',
    iosBundleId: 'com.example.iotapp',
  );
  
}
