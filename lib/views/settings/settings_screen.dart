import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_urls.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/url_launcher_service.dart';
import '../../services/notification_service.dart';
import '../../viewmodels/subscription_provider.dart';
import '../../viewmodels/settings_provider.dart';
import '../paywall/premium_paywall_screen.dart';
import 'widgets/settings_section_header.dart';
import 'widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    if (settings.isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Settings'),
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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

          // // ========== TEST SECTION (Remove after testing) ==========
          // const SettingsSectionHeader(title: '🧪 TEST NOTIFICATIONS'),

          // SettingsTile(
          //   icon: Icons.notifications_active,
          //   title: 'Test Instant Notification',
          //   subtitle: 'Shows notification immediately',
          //   onTap: () => _testInstantNotification(context),
          // ),

          // SettingsTile(
          //   icon: Icons.checklist,
          //   title: 'Check Pending Notifications',
          //   subtitle: 'See scheduled notifications in console',
          //   onTap: () => _checkPending(context),
          // ),

          // const SizedBox(height: 24),
          // // ========== END TEST SECTION ==========

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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumPaywallScreen(),
                ),
              );
            },
          ),
          SettingsTile(
            icon: Icons.restore_outlined,
            title: 'Restore Purchases',
            onTap: () async {
              final subscriptionService = ref.read(subscriptionProvider);
              await subscriptionService.restorePurchases();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restore purchases initiated')),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // Notification Section
          const SettingsSectionHeader(title: 'Notifications'),
          SettingsTile(
            icon: settings.isNotificationEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            title: 'Daily Reminder',
            subtitle: settings.isNotificationEnabled
                ? 'Enabled - daily reminders'
                : 'Disabled',
            trailing: Switch(
              value: settings.isNotificationEnabled,
              onChanged: (value) =>
                  _toggleNotification(context, ref, value, settings),
            ),
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Support Section
          const SettingsSectionHeader(title: 'Support'),
          SettingsTile(
            icon: Icons.star_outline,
            title: 'Write a Review',
            onTap: () => UrlLauncherService().openAppStore(),
          ),
          SettingsTile(
            icon: Icons.share_outlined,
            title: 'Share App',
            onTap: () => UrlLauncherService().shareApp(),
          ),
          SettingsTile(
            icon: Icons.support_agent_outlined,
            title: 'Contact Support',
            onTap: () => UrlLauncherService().sendEmail(
              'techrozsolutions.co@gmail.com',
              subject: 'Speaker Cleaner Support',
            ),
          ),

          const SizedBox(height: 24),

          // Legal Section
          const SettingsSectionHeader(title: 'Legal'),
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => UrlLauncherService().launchURL(AppUrls.privacyPolicy),
          ),
          SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Use',
            onTap: () => UrlLauncherService().launchURL(AppUrls.termsOfUse),
          ),

          const SizedBox(height: 24),

          // About Section
          const SettingsSectionHeader(title: 'About'),
          SettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: () {},
            trailing: const SizedBox(),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // // ========== TEST FUNCTIONS ==========

  // Future<void> _testInstantNotification(BuildContext context) async {
  //   await NotificationService().showTestNotification();
  //   if (context.mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('✅ Check your notification panel!'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   }
  // }

  // Future<void> _checkPending(BuildContext context) async {
  //   await NotificationService().checkPendingNotifications();
  //   if (context.mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Check console for pending notifications'),
  //       ),
  //     );
  //   }
  // }

  // ========== MAIN FUNCTIONS ==========

  Future<void> _toggleNotification(
    BuildContext context,
    WidgetRef ref,
    bool value,
    SettingsState settings,
  ) async {
    final notificationService = NotificationService();

    if (value) {
      await notificationService.requestPermissions();

      bool enabled = await notificationService.areNotificationsEnabled();
      if (!enabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Please enable notifications in device Settings'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await ref.read(settingsProvider.notifier).setNotificationEnabled(true);
      await notificationService.scheduleDailyNotification(
        title: 'Speaker Cleaner 🔊',
        body: 'Keep your speakers clean for the best sound quality!',
      );

      // Verify it's scheduled
      await notificationService.checkPendingNotifications();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('-> Daily reminder enabled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await ref.read(settingsProvider.notifier).setNotificationEnabled(false);
      await notificationService.cancelAllNotifications();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('-> Daily reminder disabled')),
        );
      }
    }
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
            _buildThemeOption(context, ref, 'System Default', ThemeMode.system, currentMode),
            _buildThemeOption(context, ref, 'Light', ThemeMode.light, currentMode),
            _buildThemeOption(context, ref, 'Dark', ThemeMode.dark, currentMode),
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
          color: isSelected ? theme.colorScheme.primary : null,
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
