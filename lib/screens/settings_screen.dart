import 'package:eye_tracking_safety/widgets/consent_dialog.dart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _showResetDialog(context),
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _buildAlertsSection(context, settings),
              const Divider(),
              _buildSensitivitySection(context, settings),
              const SizedBox(height: 20), 
              _buildConsentNavigator(context), 
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context, SettingsProvider settings) {           //button for disable / able sould alerts 
    return _buildSection(
      'Alerts',
      [
        SwitchListTile(
          title: const Text('Sound Alerts'),
          subtitle: const Text('Play sound when drowsiness detected'),
          value: settings.soundEnabled,
          onChanged: (value) => settings.updateSoundEnabled(value),
        ),
      ],
    );
  }

  Widget _buildSensitivitySection(BuildContext context, SettingsProvider settings) {
  return _buildSection(
    'Sensitivity',
    [
      ListTile(
        title: const Text('Blink Detection Sensitivity'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Slider(
              value: settings.blinkSensitivity,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(settings.blinkSensitivity * 100).round()}%',
              onChanged: (value) => settings.updateBlinkSensitivity(value),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Less Sensitive'),
                  Text('More Sensitive'),                         //label for better guidance 
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      ListTile(
        title: const Text('Drowsiness Detection Threshold (Default : 0.5 Seconds)'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Slider(
              value: settings.drowsyThreshold,
              min: -0.3,
              max: 0.3,
              divisions: 6,
              label: '${(settings.drowsyThreshold * 1000).round()}ms',
              onChanged: (value) => settings.updateDrowsyThreshold(value),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('-0.3 Sec'),
                  Text('0ms'),
                  Text('+0.3 Sec'),                                //label for better guidance 
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
  

  Widget _buildConsentNavigator(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => ConsentDialog(
            onAccept: () {
              Navigator.of(context).pop(); 
            },
          ),
        );
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Read our Consent Policy',
          style: TextStyle(
            color: Colors.blue, 
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _showResetDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'RESET',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await context.read<SettingsProvider>().resetSettings();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to defaults')),
        );
      }
    }
  }
}