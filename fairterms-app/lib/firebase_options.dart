/// Firebase configuration options for FairTerms.
///
/// TODO (Member 2): Replace the placeholder values below with actual Firebase
/// project configuration obtained from the Firebase Console.
/// Run `flutterfire configure` to generate this file automatically.
library;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for use with the FairTerms Firebase project.
///
/// Replace all placeholder strings with actual values from your Firebase project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Non-web targets require real Firebase configs from the Firebase Console.
    // Run `flutterfire configure` or populate the values below manually.
    // Until then, Firebase is unsupported on non-web platforms.
    throw UnsupportedError(
      'Firebase is not configured for ${defaultTargetPlatform.name}. '
      'Run `flutterfire configure` with real project credentials to enable it.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBtUV0ls8_VTErbhfw4kJGgMYK2IdnSRnE',
    appId: '1:599294573388:web:55363cdfd23319c5ddede9',
    messagingSenderId: '599294573388',
    projectId: 'aaaaa-c1291',
    authDomain: 'aaaaa-c1291.firebaseapp.com',
    storageBucket: 'aaaaa-c1291.firebasestorage.app',
  );

  // TODO: Replace with actual Firebase Web app config

  // TODO: Replace with actual Firebase Android config (google-services.json values)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TODO_REPLACE_WITH_ACTUAL_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'fairterms-TODO',
    storageBucket: 'fairterms-TODO.appspot.com',
  );

  // TODO: Replace with actual Firebase iOS config (GoogleService-Info.plist values)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TODO_REPLACE_WITH_ACTUAL_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'fairterms-TODO',
    storageBucket: 'fairterms-TODO.appspot.com',
    iosBundleId: 'com.fairterms.app',
  );

  // TODO: Replace with actual Firebase macOS config
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'TODO_REPLACE_WITH_ACTUAL_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'fairterms-TODO',
    storageBucket: 'fairterms-TODO.appspot.com',
    iosBundleId: 'com.fairterms.app',
  );

  // TODO: Replace with actual Firebase Windows config
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'TODO_REPLACE_WITH_ACTUAL_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'fairterms-TODO',
    authDomain: 'fairterms-TODO.firebaseapp.com',
    storageBucket: 'fairterms-TODO.appspot.com',
  );
}