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

    if (user == null) {
      return _SignedOutProfile(onLogin: () => context.go('/login'));
    }

    final profileStream = ref.watch(userProfileProvider(user.uid));

    return profileStream.when(
      data: (profile) {
        final data = profile.data() as Map<String, dynamic>?;

        if (!profile.exists || data == null) {
          return _MissingProfile(
            email: user.email,
            onCreateProfile: () => context.push('/create-profile'),
            onSignOut: () => _signOut(context, ref),
          );
        }

        return _ProfileContent(
          data: data,
          authEmail: user.email,
          onEdit: () => context.push('/create-profile'),
          onSignOut: () => _signOut(context, ref),
          onDelete: () => _showDeleteAccountDialog(context),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _SimpleMessage(
        icon: Icons.error_outline,
        title: 'Could not load profile',
        message: '$error',
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) context.go('/login');
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This request is permanent and will remove your profile and account data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion request sent.'),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? authEmail;
  final VoidCallback onEdit;
  final VoidCallback onSignOut;
  final VoidCallback onDelete;

  const _ProfileContent({
    required this.data,
    required this.authEmail,
    required this.onEdit,
    required this.onSignOut,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = _value(data['name'], fallback: 'Your Name');
    final email = _value(data['email'], fallback: authEmail ?? 'No email');
    final role = _value(data['role'], fallback: 'customer');
    final phone = _value(data['contact']);
    final address = _address(data);
    final initials = _initials(name);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                _HeaderCard(
                  initials: initials,
                  name: name,
                  email: email,
                  role: role,
                  onEdit: onEdit,
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Account',
                  children: [
                    _ProfileRow(
                      icon: Icons.person_outline,
                      label: 'Name',
                      value: name,
                    ),
                    _ProfileRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email,
                    ),
                    _ProfileRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: phone,
                    ),
                    _ProfileRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: address,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'App',
                  children: [
                    _ActionRow(
                      icon: Icons.edit_outlined,
                      label: 'Edit profile',
                      onTap: onEdit,
                    ),
                    const _ProfileRow(
                      icon: Icons.info_outline,
                      label: 'Version',
                      value: 'Ezer Fresh 1.0.5',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Session',
                  children: [
                    _ActionRow(
                      icon: Icons.logout,
                      label: 'Sign out',
                      color: Colors.red,
                      onTap: onSignOut,
                    ),
                    _ActionRow(
                      icon: Icons.delete_outline,
                      label: 'Delete account',
                      color: Colors.red,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _address(Map<String, dynamic> data) {
    final address = _value(data['address']);
    final suite = _value(data['apartmentSuite'], fallback: '');
    if (address == 'Not set') return address;
    if (suite.isEmpty) return address;
    return '$address, $suite';
  }
}

class _HeaderCard extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final String role;
  final VoidCallback onEdit;

  const _HeaderCard({
    required this.initials,
    required this.name,
    required this.email,
    required this.role,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(role);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: roleColor.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: GoogleFonts.lato(
                color: roleColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: GoogleFonts.lato(
                      color: roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: GoogleFonts.lato(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ..._withDividers(children),
        ],
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> rows) {
    final widgets = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      widgets.add(rows[i]);
      if (i != rows.length - 1) {
        widgets.add(const Divider(height: 1, indent: 56));
      }
    }
    return widgets;
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2E7D32)),
      title: Text(label),
      subtitle: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final rowColor = color ?? Colors.black87;

    return ListTile(
      leading: Icon(icon, color: rowColor),
      title: Text(
        label,
        style: TextStyle(color: rowColor, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _SignedOutProfile extends StatelessWidget {
  final VoidCallback onLogin;

  const _SignedOutProfile({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return _SimpleMessage(
      icon: Icons.lock_person_outlined,
      title: 'Sign in to view your profile',
      message: 'Your account details and settings will appear here.',
      action: FilledButton(
        onPressed: onLogin,
        child: const Text('Login / Sign Up'),
      ),
    );
  }
}

class _MissingProfile extends StatelessWidget {
  final String? email;
  final VoidCallback onCreateProfile;
  final VoidCallback onSignOut;

  const _MissingProfile({
    required this.email,
    required this.onCreateProfile,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 96),
      children: [
        _SimpleMessage(
          icon: Icons.person_add_outlined,
          title: 'Complete your profile',
          message: email ?? 'Add your details so the app can serve you better.',
          action: FilledButton(
            onPressed: onCreateProfile,
            child: const Text('Complete Profile'),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ),
      ],
    );
  }
}

class _SimpleMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _SimpleMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: const Color(0xFF2E7D32)),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(color: Colors.grey[600]),
              ),
              if (action != null) ...[
                const SizedBox(height: 18),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _value(dynamic value, {String fallback = 'Not set'}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'EF';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'admin':
      return const Color(0xFF2E7D32);
    case 'rider':
      return const Color(0xFF00B894);
    default:
      return const Color(0xFFFDAA5E);
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE8ECE8)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
