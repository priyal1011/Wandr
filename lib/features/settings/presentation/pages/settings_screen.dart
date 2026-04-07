import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../../../core/in_memory_store.dart';
import '../../../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final store = getIt<InMemoryStore>();
    final user = store.currentUser;
    final isDarkMode = store.settings.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _ProfileSection(user: user),
          const Gap(32),
          Text('Preferences', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          const Gap(16),
          _SettingTile(
            title: 'Dark Mode',
            subtitle: 'Toggle app theme',
            icon: Icons.dark_mode_outlined,
            trailing: Switch(
              value: isDarkMode,
              onChanged: (v) {
                setState(() => store.settings = AppSettings(isDarkMode: v));
                store.saveToDisk();
                // Notify the main app state to rebuild with new theme
                context.findAncestorStateOfType<WandrAppState>()?.toggleTheme(v);
              },
            ),
          ),
          const Gap(24),
          Text('Account', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          const Gap(16),
          _SettingTile(
            title: 'Edit Profile',
            subtitle: 'Name, email and photo',
            icon: Icons.person_outline,
            onTap: () async {
              await context.push('/settings/edit-profile');
              setState(() {}); // Rebuild to show updated profile info
            },
          ),
          _SettingTile(
            title: 'Privacy & Security',
            subtitle: 'Change password',
            icon: Icons.lock_outline,
            // onTap: () => context.push('/settings/change-password'),
          ),
          const Gap(32),
          ElevatedButton.icon(
            onPressed: () {
              store.currentUser = null;
              context.go('/login');
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.05),
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final UserModel? user;
  const _ProfileSection({this.user});

  ImageProvider _getAvatarImage() {
    if (user?.photoUrl == null) return const NetworkImage('https://i.pravatar.cc/150?u=wandr');
    if (user!.photoUrl!.startsWith('http')) return NetworkImage(user!.photoUrl!);
    return FileImage(File(user!.photoUrl!));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white24,
            backgroundImage: _getAvatarImage(),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Explorer',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? 'wandr@email.com',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      onTap: onTap,
    );
  }
}