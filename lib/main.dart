// lib/main.dart
import 'package:eye_tracking_safety/providers/settings_provider.dart';
import 'package:eye_tracking_safety/services/memory_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/eye_tracking_provider.dart';

class EyeTrackingApp extends StatelessWidget {
  const EyeTrackingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eye Tracking Safety',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  // Initialize memory manager
  MemoryManager().startMonitoring();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(
          create: (context) => EyeTrackingProvider(settingsProvider),
        ),
      ],
      child: const EyeTrackingApp(),
    ),

  );
}