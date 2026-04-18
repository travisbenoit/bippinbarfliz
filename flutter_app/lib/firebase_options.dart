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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCTALyTkypYQ_aXl55dopoIx-VvOHlaWzY',
    appId: '1:351924341994:android:3958bb017a9d8cd5b11b93',
    messagingSenderId: '351924341994',
    projectId: 'barfliz-app-a37c5',
    storageBucket: 'barfliz-app-a37c5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBVvumZO8ay7AjEJ_uE_ycfwO7-Dtoyy4w',
    appId: '1:351924341994:ios:d797610e2d296333b11b93',
    messagingSenderId: '351924341994',
    projectId: 'barfliz-app-a37c5',
    storageBucket: 'barfliz-app-a37c5.firebasestorage.app',
    iosBundleId: 'com.barfliz.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.appspot.com',
    authDomain: 'YOUR_FIREBASE_PROJECT_ID.firebaseapp.com',
  );
}
