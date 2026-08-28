import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCX6V0aeDv3fAWhLnJADkiOVsJriN7nWaU',
    appId: '1:1099075542388:android:a7ad5b396d633388fc6021',
    messagingSenderId: '1099075542388',
    projectId: 'attentadce',
    storageBucket: 'attentadce.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCX6V0aeDv3fAWhLnJADkiOVsJriN7nWaU',
    appId: '1:1099075542388:android:a7ad5b396d633388fc6021',
    messagingSenderId: '1099075542388',
    projectId: 'attentadce',
    storageBucket: 'attentadce.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCX6V0aeDv3fAWhLnJADkiOVsJriN7nWaU',
    appId: '1:1099075542388:android:a7ad5b396d633388fc6021',
    messagingSenderId: '1099075542388',
    projectId: 'attentadce',
    authDomain: 'attentadce.firebaseapp.com',
    storageBucket: 'attentadce.firebasestorage.app',
  );
}
