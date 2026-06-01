import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static const String vapidKey = "uD2SjddgdggMCqPuymxB4qihHLCMfcyXuY3CaV7Wlc8";

  Future<void> initialize() async {
    // Request permissions for iOS and Android 13+
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      
      // Get the token
      String? token;
      if (kIsWeb) {
        token = await _fcm.getToken(vapidKey: vapidKey);
      } else {
        token = await _fcm.getToken();
      }
      
      debugPrint("FCM Token: $token");
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
        }
      });
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }
}

// Global background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}
