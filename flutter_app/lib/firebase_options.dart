import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyAztl-cJtuKiV0Oyg7rw-e6jWPxBtQw3J8',
    appId: '1:299600715888:android:5e9994cacbfb4e3497d4b5',
    messagingSenderId: '299600715888',
    projectId: 'quickpass-qr',
    storageBucket: 'quickpass-qr.firebasestorage.app',
  );

  // TODO: Add iOS Firebase app in Firebase Console, then fill these values
  static const ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '299600715888',
    projectId: 'quickpass-qr',
    storageBucket: 'quickpass-qr.firebasestorage.app',
    iosBundleId: 'com.example.quickpass',
  );
}
