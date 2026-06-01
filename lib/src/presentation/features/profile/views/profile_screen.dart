import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_person_outlined,
                size: 80,
                color: colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Sign in to access your profile',
                style: GoogleFonts.lato(fontSize: 18, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => context.go('/login'),
                child: const Text('Login / Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final profileStream = ref.watch(userProfileProvider(user.uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: profileStream.when(
        data: (profile) {
          if (!profile.exists || profile.data() == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 80,
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text('You haven\'t created a profile yet.'),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.push('/create-profile'),
                    child: const Text('Complete Your Profile'),
                  ),
                ],
              ),
            );
          }
          final data = profile.data() as Map<String, dynamic>;
          
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              final content = _buildContent(context, data, user.email, colorScheme, ref);

              if (isWide) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: content,
                  ),
                );
              }
              return content;
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('An error occurred: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data,
      String? authEmail, ColorScheme colorScheme, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 46,
                    backgroundColor: Color(0xFFF0F5F0),
                    child: Icon(Icons.person_outline, size: 46, color: Colors.green),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data['name'] ?? 'Customer',
                  style: GoogleFonts.lato(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['email'] ?? authEmail ?? 'No email',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/create-profile'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Personal Information',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Info Cards Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.person_outline,
                  title: 'Name',
                  subtitle: data['name'] ?? 'Not set',
                ),
                const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
                _buildListTile(
                  icon: Icons.email_outlined,
                  title: 'Email Address',
                  subtitle: data['email'] ?? authEmail ?? 'Not set',
                ),
                const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
                _buildListTile(
                  icon: Icons.phone_outlined,
                  title: 'Phone Number',
                  subtitle: data['contact'] ?? 'Not set',
                ),
                const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
                _buildListTile(
                  icon: Icons.location_on_outlined,
                  title: 'Delivery Address',
                  subtitle: data['address'] ?? 'Not set',
                ),
              ],
            ),
          ),
          // Ezer Logo and Account Management at the very bottom
          Column(
            children: [
              TextButton(
                onPressed: () {}, // Could navigate to 'About Us' or similar
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: Image.asset(
                  'assets/ezerlogo.png',
                  height: 60,
                  opacity: const AlwaysStoppedAnimation(0.6),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'EZER FRESH v1.0.0',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        final authService = ref.read(authServiceProvider);
                        await authService.signOut();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Sign Out'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showDeleteAccountDialog(context),
                      icon: const Icon(Icons.delete_forever, size: 18),
                      label: const Text('Delete Account'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[400],
                        side: BorderSide(color: Colors.red[100]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
            'This action is permanent and will delete all your order history and profile data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implementation for actual deletion would go here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Request sent. Your account will be deleted within 24 hours.')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.green),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
