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
// One kept-alive Firestore stream per user is reused by UI, routing, and role checks.
final userProfileProvider = StreamProvider.family<DocumentSnapshot, String>((
  ref,
  uid,
) {
  ref.keepAlive();
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getUserProfile(uid);
});

// Auth State Provider - typed as User? for type-safe uid access.
final authStateProvider = StreamProvider<User?>((ref) {
  ref.keepAlive();
  return ref.watch(authServiceProvider).authStateChanges;
});

// User Role Provider - derived from the shared profile stream to avoid duplicate
// listeners on users/{uid}.
final userRoleProvider = Provider<AsyncValue<String>>((ref) {
  ref.keepAlive();
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return const AsyncValue.data('customer');

      return ref
          .watch(userProfileProvider(user.uid))
          .when(
            data: (doc) {
              if (!doc.exists) return const AsyncValue.data('customer');

              final data = doc.data() as Map<String, dynamic>?;
              final role =
                  (data?['role'] as String?)?.trim().toLowerCase() ??
                  'customer';
              return AsyncValue.data(role);
            },
            loading: () => const AsyncValue.loading(),
            error: (_, __) => const AsyncValue.data('customer'),
          );
    },
    loading: () => const AsyncValue.loading(),
    error: (_, __) => const AsyncValue.data('customer'),
  );
});

// Profile Completion Provider - derived from the shared profile stream.
final isProfileCompleteProvider = Provider<AsyncValue<bool>>((ref) {
  ref.keepAlive();
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return const AsyncValue.data(true);
      }

      return ref
          .watch(userProfileProvider(user.uid))
          .when(
            data: (doc) {
              if (!doc.exists) return const AsyncValue.data(false);

              final data = doc.data() as Map<String, dynamic>?;
              return AsyncValue.data(
                data?['isProfileComplete'] as bool? ?? false,
              );
            },
            loading: () => const AsyncValue.loading(),
            error: (_, __) => const AsyncValue.data(false),
          );
    },
    loading: () => const AsyncValue.loading(),
    error: (_, __) => const AsyncValue.data(false),
  );
});

// Search Query Provider (Using modern NotifierProvider)
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  set query(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);
