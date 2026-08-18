import 'package:flutter/material.dart';

/// Root navigator key handed to [GoRouter] so code outside the widget tree
/// (namely push-notification tap handling in `NotificationService`) can
/// navigate without needing a `BuildContext`. Kept in its own file so
/// `notification_service.dart` doesn't have to import `app_router.dart`
/// directly, avoiding any risk of a circular import between the two.
final rootNavigatorKey = GlobalKey<NavigatorState>();
