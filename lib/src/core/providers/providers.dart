import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/core/services/auth_service.dart';
import 'package:ezer_fresh/src/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

export 'cart_provider.dart';

// Onboarding Completed Provider
class OnboardingNotifier extends AsyncNotifier<bool> {
  static const _key = 'onboarding_completed';

  @override
  FutureOr<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> completeOnboarding() async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = const AsyncValue.data(true);
  }
}

final onboardingCompletedProvider =
    AsyncNotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Firestore Service Provider
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

// User Profile Provider
// NOTE: No autoDispose — the Firestore stream must stay alive for real-time role changes
final userProfileProvider = StreamProvider.family<DocumentSnapshot, String>((ref, uid) {
  ref.keepAlive(); // prevent disposal so real-time updates always flow
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getUserProfile(uid);
});

// Auth State Provider — properly typed as User? for type-safe uid access
final authStateProvider = StreamProvider<User?>((ref) {
  ref.keepAlive();
  return ref.watch(authServiceProvider).authStateChanges;
});

// User Role Provider — combines auth + Firestore profile into a single role stream.
// Uses switchMap pattern: when auth changes, cancels old profile subscription
// and starts a new one, guaranteeing each role emission triggers RouterNotifier.
final userRoleProvider = StreamProvider<String>((ref) {
  ref.keepAlive();
  final firestoreService = ref.read(firestoreServiceProvider);

  final controller = StreamController<String>();
  StreamSubscription<DocumentSnapshot>? profileSub;

  final authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
    // Cancel previous profile listener on every auth change
    profileSub?.cancel();
    profileSub = null;

    if (user == null) {
      controller.add('customer');
    } else {
      profileSub = firestoreService.getUserProfile(user.uid).listen(
        (doc) {
          if (!doc.exists) {
            controller.add('customer');
          } else {
            final data = doc.data() as Map<String, dynamic>?;
            final role = (data?['role'] as String?)?.trim().toLowerCase() ?? 'customer';
            controller.add(role);
          }
        },
        onError: (_) => controller.add('customer'),
      );
    }
  });

  ref.onDispose(() {
    profileSub?.cancel();
    authSub.cancel();
    controller.close();
  });

  return controller.stream;
});

// Profile Completion Provider — reactive detection of completed customer/rider profiles
final isProfileCompleteProvider = StreamProvider<bool>((ref) {
  ref.keepAlive();
  final firestoreService = ref.read(firestoreServiceProvider);

  final controller = StreamController<bool>();
  StreamSubscription<DocumentSnapshot>? profileSub;

  final authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
    profileSub?.cancel();
    profileSub = null;

    if (user == null) {
      controller.add(true); // default true for guests so they aren't blocked/redirected to profile
    } else {
      profileSub = firestoreService.getUserProfile(user.uid).listen(
        (doc) {
          if (!doc.exists) {
            controller.add(false); // No profile doc exists yet
          } else {
            final data = doc.data() as Map<String, dynamic>?;
            final isComplete = data?['isProfileComplete'] as bool? ?? false;
            controller.add(isComplete);
          }
        },
        onError: (_) => controller.add(false),
      );
    }
  });

  ref.onDispose(() {
    profileSub?.cancel();
    authSub.cancel();
    controller.close();
  });

  return controller.stream;
});

// Search Query Provider (Using modern NotifierProvider)
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  set query(String value) => state = value;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

