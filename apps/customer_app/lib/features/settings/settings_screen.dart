import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  String _locationStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    final status = await Geolocator.checkPermission();
    setState(() {
      _locationStatus = status.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection('Preferences'),
          _buildSettingsTile(
            Icons.notifications_outlined, 
            'Notifications', 
            'Receive booking updates', 
            trailing: Switch(value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            Icons.location_on_outlined, 
            'Location Access', 
            'Status: $_locationStatus', 
            onTap: () async {
              await Geolocator.requestPermission();
              _checkLocationStatus();
            },
          ),
          const SizedBox(height: 24),
          _buildSection('General'),
          _buildSettingsTile(Icons.language_outlined, 'Language', 'English (US)'),
          const SizedBox(height: 12),
          _buildSettingsTile(Icons.privacy_tip_outlined, 'Privacy Policy', 'Read our policies'),
          const SizedBox(height: 12),
          _buildSettingsTile(Icons.description_outlined, 'Terms of Service', 'Read our terms'),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                const Text('HomeFix Customer App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Version 1.0.0 (Build 123)', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {Widget? trailing, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }
}
