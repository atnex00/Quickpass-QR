import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
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
}
