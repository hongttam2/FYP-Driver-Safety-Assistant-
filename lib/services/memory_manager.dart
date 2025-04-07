import 'dart:async';
import 'package:flutter/foundation.dart';

class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  Timer? _memoryMonitorTimer;
  
  void startMonitoring() {        //memory monitoring for garbage collection , the app easily crash in early development stage , so i added this
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      debugPrint('Memory monitor check');
    });
  }

  void stopMonitoring() {
    _memoryMonitorTimer?.cancel();
  }
}