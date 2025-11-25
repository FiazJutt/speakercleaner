import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_provider.dart';
import 'widgets/settings_section_header.dart';
import 'widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Appearance Section
          const SettingsSectionHeader(title: 'Appearance'),
          SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: _getThemeModeLabel(themeMode),
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),
          const SizedBox(height: 24),

          // Subscription Section
          const SettingsSectionHeader(title: 'Subscription'),
          SettingsTile(
            icon: Icons.card_membership_outlined,
            title: 'Manage Subscriptions',
            onTap: () => _showComingSoon(context, 'Manage Subscriptions'),
          ),
          SettingsTile(
            icon: Icons.restore_outlined,
            title: 'Restore Purchases',
            onTap: () => _showComingSoon(context, 'Restore Purchases'),
          ),

          const SizedBox(height: 24),

          // Data Section
          const SettingsSectionHeader(title: 'Data'),
          SettingsTile(
            icon: Icons.backup_outlined,
            title: 'Backup Data',
            onTap: () => _showComingSoon(context, 'Backup Data'),
          ),
          SettingsTile(
            icon: Icons.restore_page_outlined,
            title: 'Restore Data',
            onTap: () => _showComingSoon(context, 'Restore Data'),
          ),

          const SizedBox(height: 24),

          // Support Section
          const SettingsSectionHeader(title: 'Support'),
          SettingsTile(
            icon: Icons.star_outline,
            title: 'Write a Review',
            onTap: () => _showComingSoon(context, 'Write a Review'),
          ),
          SettingsTile(
            icon: Icons.share_outlined,
            title: 'Share App',
            onTap: () => _showComingSoon(context, 'Share App'),
          ),
          SettingsTile(
            icon: Icons.support_agent_outlined,
            title: 'Contact Support',
            onTap: () => _showComingSoon(context, 'Contact Support'),
          ),

          const SizedBox(height: 24),

          // Legal Section
          const SettingsSectionHeader(title: 'Legal'),
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _showComingSoon(context, 'Privacy Policy'),
          ),
          SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Use',
            onTap: () => _showComingSoon(context, 'Terms of Use'),
          ),

          const SizedBox(height: 24),

          // About Section
          const SettingsSectionHeader(title: 'About'),
          SettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: () {},
            trailing: const SizedBox(), // No chevron for version
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(feature, style: theme.textTheme.titleLarge),
        content: Text(
          'This feature is coming soon!',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Choose Theme', style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              ref,
              'System Default',
              ThemeMode.system,
              currentMode,
            ),
            _buildThemeOption(
              context,
              ref,
              'Light',
              ThemeMode.light,
              currentMode,
            ),
            _buildThemeOption(
              context,
              ref,
              'Dark',
              ThemeMode.dark,
              currentMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    ThemeMode mode,
    ThemeMode currentMode,
  ) {
    final theme = Theme.of(context);
    final isSelected = mode == currentMode;

    return ListTile(
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }
}
