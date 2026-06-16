import 'package:ezer_fresh/src/core/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Analytics'),
      ),
      body: usersAsync.when(
        data: (users) {
          final admins    = users.where((u) => u.role == 'admin').length;
          final riders    = users.where((u) => u.role == 'rider').length;
          final customers = users.where((u) => u.role == 'customer').length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
            children: [
              Row(
                children: [
                  _Stat(label: 'Total',     value: '${users.length}', icon: Icons.people_outline,              color: const Color(0xFF0984E3)),
                  _Stat(label: 'Admins',    value: '$admins',          icon: Icons.admin_panel_settings_outlined, color: const Color(0xFF2E7D32)),
                  _Stat(label: 'Riders',    value: '$riders',          icon: Icons.delivery_dining_outlined,    color: const Color(0xFF00B894)),
                  _Stat(label: 'Customers', value: '$customers',       icon: Icons.person_outline,              color: const Color(0xFFFDAA5E)),
                ],
              ),
              const SizedBox(height: 10),
              if (users.isEmpty)
                const _Empty(message: 'No users found')
              else
                ...users.map((u) => _UserRow(user: u)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// Compact stat tile
class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8ECE8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final AppUser user;
  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final color = switch (user.role) {
      'admin'  => const Color(0xFF2E7D32),
      'rider'  => const Color(0xFF00B894),
      _        => const Color(0xFF0984E3),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(Icons.person_outline, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      ),
    );
  }
}
