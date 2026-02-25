import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/theme/theme_bloc.dart';
import '../../../blocs/theme/theme_event.dart';
import '../../../blocs/theme/theme_state.dart';
import '../../../constants/color_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
        ),
      ),
      body: ListView(
        children: [
          // Account section
          _sectionHeader('Account'),
          _tile(
            context,
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () => context.push('/edit-profile'),
          ),
          _tile(
            context,
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {},
          ),
          _tile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
            onTap: () {},
          ),
          _tile(
            context,
            icon: Icons.security_outlined,
            title: 'Security',
            onTap: () {},
          ),

          // Notifications section
          _sectionHeader('Notifications'),
          _switchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Push Notifications',
            value: true,
            onChanged: (_) {},
          ),
          _switchTile(
            icon: Icons.mark_email_unread_outlined,
            title: 'Email Notifications',
            value: false,
            onChanged: (_) {},
          ),

          // Appearance section
          _sectionHeader('Appearance'),
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return _switchTile(
                icon: themeState.isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                title: 'Dark Mode',
                subtitle: themeState.isDark ? 'On' : 'Off',
                value: themeState.isDark,
                onChanged: (_) => context.read<ThemeBloc>().add(ThemeToggled()),
              );
            },
          ),

          // About section
          _sectionHeader('About'),
          _tile(
            context,
            icon: Icons.info_outline,
            title: 'About Blackclap',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Blackclap',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Blackclap Inc.',
              );
            },
          ),
          _tile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),
          _tile(
            context,
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),

          // Danger zone
          const SizedBox(height: 16),
          const Divider(),
          _tile(
            context,
            icon: Icons.logout,
            title: 'Log Out',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                      },
                      child: const Text(
                        'Log Out',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          _tile(
            context,
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'This action is permanent and cannot be undone. '
                    'All your posts, stories, and data will be deleted.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.onSurface),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? AppColors.onSurface),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: const TextStyle(color: AppColors.textTertiary))
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.neutral400),
      onTap: onTap,
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.onSurface),
      title: Text(title, style: const TextStyle(color: AppColors.onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: const TextStyle(color: AppColors.textTertiary))
          : null,
      value: value,
      activeColor: AppColors.accent,
      onChanged: onChanged,
    );
  }
}
