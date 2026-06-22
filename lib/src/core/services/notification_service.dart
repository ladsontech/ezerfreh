import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final notificationMessengerKey = GlobalKey<ScaffoldMessengerState>();

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  factory NotificationService() => instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String vapidKey = 'uD2SjddgdggMCqPuymxB4qihHLCMfcyXuY3CaV7Wlc8';

  StreamSubscription<User?>? _authSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _messageSub = FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    _tokenRefreshSub = _fcm.onTokenRefresh.listen(_saveTokenForCurrentUser);
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _registerTokenForUser(user.uid);
      }
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await _registerTokenForUser(currentUser.uid);
    }
  }

  Future<void> unregisterCurrentUserToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final token = await _getToken();
      if (token == null) return;
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(_tokenDocId(token))
          .delete();
    } catch (error) {
      debugPrint('FCM token unregister failed: $error');
    }
  }

  Future<void> _registerTokenForUser(String uid) async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final authorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!authorized) {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    await _saveTokenForUser(uid);
  }

  Future<void> _saveTokenForCurrentUser(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _saveToken(uid, token);
  }

  Future<void> _saveTokenForUser(String uid) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      await _saveToken(uid, token);
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }
  }

  Future<void> _saveToken(String uid, String token) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(_tokenDocId(token))
        .set({
          'token': token,
          'platform': _platformLabel,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<String?> _getToken() {
    if (kIsWeb) {
      return _fcm.getToken(vapidKey: vapidKey);
    }
    return _fcm.getToken();
  }

  void _showForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title']?.toString() ??
        'Ezer Fresh';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';

    debugPrint('Foreground notification: $title $body ${message.data}');

    final messenger = notificationMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(body.isEmpty ? title : '$title\n$body'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  String get _platformLabel {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  String _tokenDocId(String token) => Uri.encodeComponent(token);

  void dispose() {
    _authSub?.cancel();
    _tokenRefreshSub?.cancel();
    _messageSub?.cancel();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
}
