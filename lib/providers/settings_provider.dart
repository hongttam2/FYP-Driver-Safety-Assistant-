import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  
  bool _soundEnabled = true;
  double _blinkSensitivity = 0.8;
  double _drowsyThreshold = 0.0;
  
  // Getters
  bool get soundEnabled => _soundEnabled;
  double get blinkSensitivity => _blinkSensitivity;
  double get drowsyThreshold => _drowsyThreshold;

  // Initialize settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _blinkSensitivity = prefs.getDouble('blink_sensitivity') ?? 0.8;
    notifyListeners();
  }

  // Save settings
  Future<void> updateSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    notifyListeners();
  }

  Future<void> updateBlinkSensitivity(double value) async {
    _blinkSensitivity = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('blink_sensitivity', value);
    notifyListeners();
  }

  Future<void> updateDrowsyThreshold(double value) async {
    _drowsyThreshold = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('drowsy_threshold', value);
    notifyListeners();
  }

  Future<void> resetSettings() async {
    _soundEnabled = true;
    _blinkSensitivity = 0.5;
    _drowsyThreshold = 0.0;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}