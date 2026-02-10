import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_settings_service.dart';
import '../../core/models/user_settings.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../profile/presentation/edit_profile_screen.dart';
import '../support/presentation/support_screen.dart';
import '../profile/presentation/policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel user;

  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserSettingsService _settingsService = UserSettingsService();
  String _appVersion = '';
  
  // Local state for instant UI feedback
  UserSettings? _localSettings;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  Future<void> _updateNotificationSetting(
    NotificationSettings Function(NotificationSettings) update,
  ) async {
    if (_localSettings == null || _isUpdating) return;

    final oldSettings = _localSettings!;
    final newNotifications = update(oldSettings.notifications);
    
    // Optimistic update
    setState(() {
      _localSettings = oldSettings.copyWith(notifications: newNotifications);
    });

    try {
      setState(() => _isUpdating = true);
      await _settingsService.updateNotificationSettings(
        widget.user.uid,
        newNotifications,
      );
    } catch (e) {
      // Revert on error
      setState(() {
        _localSettings = oldSettings;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _updatePrivacySetting(
    PrivacySettings Function(PrivacySettings) update,
  ) async {
    if (_localSettings == null || _isUpdating) return;

    final oldSettings = _localSettings!;
    final newPrivacy = update(oldSettings.privacy);
    
    // Optimistic update
    setState(() {
      _localSettings = oldSettings.copyWith(privacy: newPrivacy);
    });

    try {
      setState(() => _isUpdating = true);
      await _settingsService.updatePrivacySettings(
        widget.user.uid,
        newPrivacy,
      );
    } catch (e) {
      // Revert on error
      setState(() {
        _localSettings = oldSettings;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            color: AppTheme.textColor,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<UserSettings>(
        stream: _settingsService.streamUserSettings(widget.user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _localSettings == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Use local settings if available, otherwise use stream data
          final settings = _localSettings ?? snapshot.data ?? UserSettings.defaults();
          
          // Update local settings from stream if not updating
          if (!_isUpdating && snapshot.hasData && _localSettings == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _localSettings = snapshot.data;
                });
              }
            });
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // Notifications Section
                _buildSectionHeader('NOTIFICATIONS'),
                _buildSettingsCard([
                  _buildSwitchTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'Push Notifications',
                    subtitle: 'Master toggle for all notifications',
                    value: settings.notifications.enabled,
                    onChanged: (value) {
                      _updateNotificationSetting(
                        (n) => n.copyWith(enabled: value),
                      );
                    },
                  ),
                  if (settings.notifications.enabled) ...[
                    const Divider(height: 1, indent: 60),
                    _buildSwitchTile(
                      icon: Icons.event_note_rounded,
                      title: 'Booking Updates',
                      subtitle: 'Status changes and reminders',
                      value: settings.notifications.bookingUpdates,
                      onChanged: (value) {
                        _updateNotificationSetting(
                          (n) => n.copyWith(bookingUpdates: value),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 60),
                    _buildSwitchTile(
                      icon: Icons.local_offer_rounded,
                      title: 'Promotions & Offers',
                      subtitle: 'Deals and special discounts',
                      value: settings.notifications.promotions,
                      onChanged: (value) {
                        _updateNotificationSetting(
                          (n) => n.copyWith(promotions: value),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 60),
                    _buildSwitchTile(
                      icon: Icons.payment_rounded,
                      title: 'Payments & Wallet',
                      subtitle: 'Transaction alerts',
                      value: settings.notifications.payments,
                      onChanged: (value) {
                        _updateNotificationSetting(
                          (n) => n.copyWith(payments: value),
                        );
                      },
                    ),
                    if (widget.user.role?.toLowerCase() == 'technician') ...[
                      const Divider(height: 1, indent: 60),
                      _buildSwitchTile(
                        icon: Icons.work_outline_rounded,
                        title: 'Technician Status',
                        subtitle: 'Job requests and updates',
                        value: settings.notifications.technicianStatus,
                        onChanged: (value) {
                          _updateNotificationSetting(
                            (n) => n.copyWith(technicianStatus: value),
                          );
                        },
                      ),
                    ],
                  ],
                ]),

                const SizedBox(height: 32),

                // Account Section
                _buildSectionHeader('ACCOUNT'),
                _buildSettingsCard([
                  _buildNavigationTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: widget.user),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildNavigationTile(
                    icon: Icons.phone_android_rounded,
                    title: 'Change Phone Number',
                    subtitle: 'Update your mobile number',
                    onTap: () => _showComingSoonDialog('Change Phone Number'),
                  ),
                  if (widget.user.email?.isNotEmpty ?? false) ...[
                    const Divider(height: 1, indent: 60),
                    _buildNavigationTile(
                      icon: Icons.email_outlined,
                      title: 'Email Preferences',
                      subtitle: 'Manage email notifications',
                      onTap: () => _showComingSoonDialog('Email Preferences'),
                    ),
                  ],
                  const Divider(height: 1, indent: 60),
                  _buildNavigationTile(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    subtitle: 'English (UK)',
                    onTap: () => _showComingSoonDialog('Language Selection'),
                  ),
                ]),

                const SizedBox(height: 32),

                // Privacy & Security Section
                _buildSectionHeader('PRIVACY & SECURITY'),
                _buildSettingsCard([
                  _buildSwitchTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'App Lock',
                    subtitle: 'Require PIN/biometric to open app',
                    value: settings.privacy.appLock,
                    onChanged: (value) {
                      _showComingSoonDialog('App Lock');
                    },
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildNavigationTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    onTap: () => _confirmLogout(authService),
                    iconColor: Colors.orange,
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildNavigationTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Account',
                    subtitle: 'Permanently remove your account',
                    onTap: () => _confirmDeleteAccount(),
                    iconColor: Colors.redAccent,
                  ),
                ]),

                const SizedBox(height: 32),

                // Support & Info Section
                _buildSectionHeader('SUPPORT & INFO'),
                _buildSettingsCard([
                  _buildNavigationTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'FAQs and customer service',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SupportScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildNavigationTile(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    subtitle: 'Service agreement',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PolicyScreen(title: 'Terms & Conditions'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildNavigationTile(
                    icon: Icons.policy_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How we protect your data',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PolicyScreen(title: 'Privacy Policy'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildNavigationTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About HomeFix',
                    subtitle: _appVersion.isNotEmpty ? 'Version $_appVersion' : 'Loading...',
                    onTap: () => _showAboutDialog(),
                  ),
                ]),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppTheme.subtitleColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppTheme.textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: AppTheme.subtitleColor,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppTheme.textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: AppTheme.subtitleColor,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey,
        size: 20,
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Coming Soon',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Text(
          '$feature will be available in a future update. Stay tuned!',
          style: GoogleFonts.outfit(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'GOT IT',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Logout?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: GoogleFonts.outfit(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authService.signOut();
            },
            child: Text(
              'LOGOUT',
              style: GoogleFonts.outfit(
                color: Colors.orange,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Account?',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This action cannot be undone. All your data, bookings, and wallet balance will be permanently deleted.\n\nTo proceed, please contact our support team.',
          style: GoogleFonts.outfit(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              );
            },
            child: Text(
              'CONTACT SUPPORT',
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home_repair_service_rounded,
                color: AppTheme.primaryColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'HomeFix',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
            Text(
              'Version $_appVersion',
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        content: Text(
          'Your trusted partner for home services. We connect you with verified professionals for all your home maintenance needs.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CLOSE',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
