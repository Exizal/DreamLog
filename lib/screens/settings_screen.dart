import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../widgets/liquid_glass_time_picker.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  bool _notificationsEnabled = false;
  TimeOfDay? _notificationTime;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController.forward();
    _loadNotificationSettings();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationSettings() async {
    final time = await NotificationService.getNotificationTime();
    if (mounted) {
      setState(() {
        _notificationTime = time;
        _notificationsEnabled = time != null;
      });
    }
  }

  Future<void> _selectNotificationTime() async {
    final currentTime = _notificationTime ?? const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay? selectedTime = currentTime;

    final result = await showDialog<TimeOfDay>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: AppTheme.responsiveHorizontalPadding(context),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return LiquidGlassTimePicker(
              initialTime: currentTime,
              onTimeChanged: (time) {
                selectedTime = time;
                setDialogState(() {});
              },
            );
          },
        ),
      ),
    );

    final finalTime = result ?? selectedTime;
    if (finalTime != null && mounted) {
      await NotificationService.scheduleDailyNotification(finalTime);
      setState(() {
        _notificationTime = finalTime;
        _notificationsEnabled = true;
      });
      _showSnackBar('Notification set for ${finalTime.format(context)}');
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (enabled) {
      // Request permissions first
      final granted = await NotificationService.requestPermissions();
      if (!granted) {
        if (mounted) {
          _showSnackBar('Notification permissions are required');
        }
        setState(() => _notificationsEnabled = false);
        return;
      }

      // If time is already set, schedule it
      if (_notificationTime != null) {
        await NotificationService.scheduleDailyNotification(_notificationTime!);
      } else {
        // Set default time and schedule
        const defaultTime = TimeOfDay(hour: 8, minute: 0);
        await NotificationService.scheduleDailyNotification(defaultTime);
        setState(() => _notificationTime = defaultTime);
      }
    } else {
      // Cancel all notifications
      await NotificationService.cancelAllNotifications();
      setState(() => _notificationsEnabled = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.backgroundTertiary.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppTheme.dreamBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          leading: _buildGlassBackButton(),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeController,
            child: ListView(
              padding: AppTheme.responsivePadding(context),
              children: [
                SizedBox(height: AppTheme.spacingM),
                
                // Notifications Glass Card
                _buildGlassCard(
                  icon: Icons.notifications_outlined,
                  iconColor: AppTheme.joyfulAmber,
                  title: 'Notifications',
                  child: Column(
                    children: [
                      // Enable/Disable Toggle
                      _buildSettingTile(
                        icon: Icons.notifications_active_rounded,
                        title: 'Daily Reminder',
                        subtitle: _notificationsEnabled
                            ? (_notificationTime != null 
                                ? 'Set for ${_notificationTime!.format(context)}'
                                : 'Enabled')
                            : 'Disabled',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          activeColor: AppTheme.accentPrimary,
                        ),
                        onTap: null,
                      ),
                      if (_notificationsEnabled) ...[
                        const SizedBox(height: 12),
                        Divider(
                          color: AppTheme.glassBorder.withOpacity(0.3),
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        // Time Picker Button
                        _buildSettingTile(
                          icon: Icons.access_time_rounded,
                          title: 'Set Time',
                          subtitle: _notificationTime != null
                              ? _notificationTime!.format(context)
                              : 'Tap to set',
                          onTap: _selectNotificationTime,
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingM),
                
                // About Glass Card
                _buildGlassCard(
                  icon: Icons.info_rounded,
                  iconColor: AppTheme.cosmicBlue,
                  title: 'About',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DreamLog',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.starLight,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.moonGlow.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'A beautiful dream journal with liquid glass design',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.moonGlow.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Dreamy credits
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.nightlight_round,
                        size: 40,
                        color: AppTheme.deepViolet.withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Made with ✨ and dreams',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.cosmicGray.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBackButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Stronger liquid glass blur
            child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.glassOverlay,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorder, width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () {
                HapticFeedback.selectionClick(); // Apple-style haptic
                Navigator.pop(context);
              },
              color: AppTheme.starLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Stronger liquid glass blur
            child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassContainer(borderRadius: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          iconColor.withOpacity(0.3),
                          iconColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.starLight,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.glassOverlay.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.dreamPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.dreamPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.starLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.moonGlow.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (onTap != null && trailing == null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.cosmicGray.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

}
