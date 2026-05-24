import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;

    if (user == null) {
      // This should ideally not happen if the profile screen is protected
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please log in to see your profile.'),
              ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Login'))
            ],
          ),
        ),
      );
    }

    final profileStream = ref.watch(userProfileProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          profileStream.when(
            data: (profile) => profile.exists
                ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      context.go('/create-profile');
                    },
                  )
                : Container(),
            loading: () => Container(),
            error: (err, stack) => Container(),
          )
        ],
      ),
      body: profileStream.when(
        data: (profile) {
          if (!profile.exists || profile.data() == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You haven\'t created a profile yet.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.go('/create-profile');
                    },
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }
          final data = profile.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${data['name'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text('Contact: ${data['contact'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text('Address: ${data['address'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('An error occurred: $err')),
      ),
    );
  }
}
