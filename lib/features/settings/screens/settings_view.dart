import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// System Setting View — profile, theme, currency, security, DB sync status.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _darkMode = true;
  bool _biometrics = true;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryViolet,
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('My Wallet User', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                      SizedBox(height: 2),
                      Text('+91 74007 00500', style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('PRO', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text('System Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),

          _buildSwitchTile('Dark Mode Theme', 'Always use dark glassmorphism palette', _darkMode, (v) => setState(() => _darkMode = v)),
          _buildSwitchTile('Biometric / PIN Lock', 'Require PIN on app unlock', _biometrics, (v) => setState(() => _biometrics = v)),
          _buildSwitchTile('Push Notifications', 'Receive due date alerts & updates', _notifications, (v) => setState(() => _notifications = v)),

          const SizedBox(height: 20),

          // Cloud Sync Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: const [
                Icon(Icons.cloud_done_rounded, color: AppTheme.primaryTeal, size: 22),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PostgreSQL Cloud Sync', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      Text('Connected • Last synced just now', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
        value: value,
        activeTrackColor: AppTheme.primaryViolet,
        activeThumbColor: AppTheme.primaryTeal,
        onChanged: onChanged,
      ),
    );
  }
}
