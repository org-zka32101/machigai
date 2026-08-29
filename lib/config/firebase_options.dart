import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// Firebase設定オプション
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return windows;
    }
    if (defaultTargetPlatform == TargetPlatform.linux) {
      return linux;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return macos;
    }
    if (defaultTargetPlatform == TargetPlatform.web) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'machigai-xxxx',
    storageBucket: 'machigai-xxxx.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'machigai-xxxx',
    storageBucket: 'machigai-xxxx.appspot.com',
    iosBundleId: 'jp.co.example.machigai',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WINDOWS_API_KEY',
    appId: 'YOUR_WINDOWS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'machigai-xxxx',
    storageBucket: 'machigai-xxxx.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR_LINUX_API_KEY',
    appId: 'YOUR_LINUX_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'machigai-xxxx',
    storageBucket: 'machigai-xxxx.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'machigai-xxxx',
    storageBucket: 'machigai-xxxx.appspot.com',
    iosBundleId: 'jp.co.example.machigai.macos',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'machigai-xxxx',
    storageBucket: 'machigai-xxxx.appspot.com',
    authDomain: 'machigai-xxxx.firebaseapp.com',
  );
}
