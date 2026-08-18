import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/firebase_options.dart';
import 'package:ezer_fresh/src/core/router/navigation_keys.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

final notificationMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Android notification channel used for every push we send. The id
/// ("default") must exactly match the `channelId` the `notifyOrderStatusChanged`
/// / `notifyStaffOnOrderCreated` Cloud Functions hardcode in `functions/index.js`.
const _defaultChannel = AndroidNotificationChannel(
  'default',
  'General Notifications',
  description: 'Order and account updates from Ezer Fresh',
  importance: Importance.high,
);

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  factory NotificationService() => instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Web Push (VAPID) *public* key from Firebase Console → Project Settings
  /// → Cloud Messaging → Web configuration. Safe to ship in client code —
  /// it's the public half of the key pair, and browsers require it to
  /// register a push subscription. Only used on web; Android/iOS ignore it.
  ///
  /// The previous value here was 43 characters, which is not a valid key
  /// (a VAPID public key is always 87 chars / 65 bytes), so `getToken` was
  /// failing on web and no browser could ever register for push.
  static const String vapidKey =
      'BLT0hWijx5tXJe8vZOX82dpB-48ImjSoEDl3dWTUtYo3wPn9RB7JfYnMqE7YngEm1C3sQcPis1Zb1oIz6XXLM9A';

  StreamSubscription<User?>? _authSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb) {
      await _initLocalNotifications();
    }

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

    // Tapped a notification while the app was in the background.
    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _navigateForNotificationData(message.data),
    );

    // App was launched (cold start) by tapping a notification. The
    // navigator isn't mounted yet at this point in `main()`, so defer the
    // navigation to just after the first frame renders.
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateForNotificationData(initialMessage.data);
      });
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await _registerTokenForUser(currentUser.uid);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _navigateForNotificationData(data);
        } catch (error) {
          debugPrint('Failed to parse notification payload: $error');
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_defaultChannel);
    await androidPlugin?.requestNotificationsPermission();
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

    // Web has no flutter_local_notifications support, so keep the in-app
    // banner there. Everywhere else, show a real system notification so
    // foreground behavior matches background/terminated behavior instead
    // of silently degrading to a SnackBar.
    if (kIsWeb) {
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
      return;
    }

    _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannel.id,
          _defaultChannel.name,
          channelDescription: _defaultChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Routes a notification tap to the right screen for the current user's
  /// role — there's no single deep-linkable order-detail route today, so
  /// this lands on the right list (rider queue / admin orders / customer
  /// orders) rather than a specific order.
  Future<void> _navigateForNotificationData(Map<String, dynamic> data) async {
    final type = data['type']?.toString();
    var path = '/home';

    if (type == 'user_signup') {
      path = '/admin/users';
    } else {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          final doc = await _firestore.collection('users').doc(uid).get();
          final role =
              (doc.data()?['role'] as String?)?.trim().toLowerCase() ??
              'customer';
          path = switch (role) {
            'admin' => '/admin/orders',
            'rider' => '/rider',
            _ => '/orders',
          };
        } catch (error) {
          debugPrint('Could not resolve role for notification tap: $error');
        }
      }
    }

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    GoRouter.of(context).go(path);
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
    _openedAppSub?.cancel();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
}
