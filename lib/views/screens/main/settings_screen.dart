import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/theme/theme_cubit.dart';
import '../../../constants/color_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _SectionHeader(label: 'Appearance'),
          _ThemeToggleTile(),
          _SectionDivider(),
          _SectionHeader(label: 'Account'),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: 'Privacy',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.security_outlined,
            label: 'Security',
            onTap: () {},
          ),
          _SectionDivider(),
          _SectionHeader(label: 'Content'),
          _SettingsTile(
            icon: Icons.language_outlined,
            label: 'Language',
            trailing: Text(
              'English',
              style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5), fontSize: 14),
            ),
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.data_usage_outlined,
            label: 'Data Usage',
            onTap: () {},
          ),
          _SectionDivider(),
          _SectionHeader(label: 'About'),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'App Version',
            trailing: Text(
              '1.0.0',
              style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5), fontSize: 14),
            ),
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {},
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final isDark = themeMode == ThemeMode.dark;
        final colors = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.neutral600 : AppColors.lightBorder,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Animated sun/moon icon with background circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? AppColors.neutral600
                          : AppColors.accent.withValues(alpha: 0.12),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: RotationTransition(
                          turns: animation,
                          child: child,
                        ),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        key: ValueKey(isDark),
                        color: isDark ? AppColors.neutral100 : AppColors.accent,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Label and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            isDark ? 'Currently using dark theme' : 'Currently using light theme',
                            key: ValueKey(isDark),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toggle switch
                  GestureDetector(
                    onTap: () => context.read<ThemeCubit>().toggle(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: 52,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: isDark
                            ? AppColors.accent
                            : AppColors.lightBorder,
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.white : AppColors.lightIconMuted,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: colors.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 0, endIndent: 0);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: colors.onSurface.withValues(alpha: 0.7), size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: colors.onSurface,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: colors.onSurface.withValues(alpha: 0.35),
            size: 20,
          ),
      onTap: onTap,
    );
  }
}
