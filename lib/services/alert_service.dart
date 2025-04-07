import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  DateTime? _lastAlertTime;

  // Prevent alert spamming by setting minimum interval
  static const _minimumAlertInterval = Duration(seconds: 3);

  Future<void> triggerAlert({
    required BuildContext context,
    required String message,
    required AlertType type,
    bool playSound = true,
  }) async {
    if (_lastAlertTime != null) {
      final timeSinceLastAlert = DateTime.now().difference(_lastAlertTime!);
      if (timeSinceLastAlert < _minimumAlertInterval) return;
    }
    _lastAlertTime = DateTime.now();
    _showVisualAlert(context, message, type);

    // Play sound only if enabled in setting
    if (playSound) {
      await _playAlertSound(type);
    }

  }

  void _showVisualAlert(BuildContext context, String message, AlertType type) {     // Show visual alert at the bottom
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              type.icon,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: type.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _playAlertSound(AlertType type) async {
  await _audioPlayer.play(AssetSource(type.soundFile));
}



  void dispose() {
    _audioPlayer.dispose();
  }
}

enum AlertType {
  drowsy(
    icon: Icons.bed,
    color: Colors.red,
    soundFile: 'sounds/alert.mp3',
  ),
  phoneDistraction(
    icon: Icons.phone_android,
    color: Colors.orange,
    soundFile: 'sounds/alert.mp3',  
  ),
  warning(
    icon: Icons.warning,
    color: Colors.amber,
    soundFile: 'sounds/alert.mp3',
  );

  final IconData icon;
  final Color color;
  final String soundFile;

  const AlertType({
    required this.icon,
    required this.color,
    required this.soundFile,
  });
}