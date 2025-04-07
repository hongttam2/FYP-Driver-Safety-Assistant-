// lib/services/storage_service.dart
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driving_session.dart';

class StorageService {
  static const String _sessionsKey = 'driving_sessions';
  
  Future<void> saveSession(DrivingSession session) async {        // save session when ended
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getSessions();
    sessions.add(session);
    
    print('Saving session: ${session.id}, BlinkData: ${session.blinkData.length} points');
    final jsonSessions = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, jsonSessions);
  }

  Future<void> updateSessionName(String sessionId, String newName) async {      // rename function
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getSessions();
    final sessionIndex = sessions.indexWhere((s) => s.id == sessionId);
    
    if (sessionIndex != -1) {
      final updatedSession = DrivingSession(
        id: sessions[sessionIndex].id,
        startTime: sessions[sessionIndex].startTime,
        endTime: sessions[sessionIndex].endTime,
        totalBlinks: sessions[sessionIndex].totalBlinks,
        phoneChecks: sessions[sessionIndex].phoneChecks,
        averageBlinkDuration: sessions[sessionIndex].averageBlinkDuration,
        blinkData: sessions[sessionIndex].blinkData,
        name: newName,
        longBlinks: sessions[sessionIndex].longBlinks,
      );
      sessions[sessionIndex] = updatedSession;
      final jsonSessions = sessions.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_sessionsKey, jsonSessions);
    }
  }

  Future<List<DrivingSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonSessions = prefs.getStringList(_sessionsKey) ?? [];
    
    try {
      final sessions = jsonSessions.map((s) {
        final decoded = jsonDecode(s);
        print('Decoded session JSON: $decoded');
        return DrivingSession.fromJson(decoded);
      }).toList();
      
      for (var session in sessions) {
        print('Loaded session: ${session.id}, BlinkData length: ${session.blinkData.length}');
      }
      return sessions;
    } catch (e) {
      print('Error parsing sessions: $e');
      rethrow;
    }
  }




  // clear all sessions in storage

  Future<void> clearSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }

  // delete a specific session from storage
  Future<void> deleteSession(String sessionId) async {
  final prefs = await SharedPreferences.getInstance();
  final sessions = await getSessions();
  sessions.removeWhere((s) => s.id == sessionId);
  final jsonSessions = sessions.map((s) => jsonEncode(s.toJson())).toList();
  await prefs.setStringList(_sessionsKey, jsonSessions);
}

 String generateSessionsReport(List<DrivingSession> sessions) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('MMM d, y - h:mm a');

    for (var session in sessions) {
      final durationInMinutes = session.endTime
          .difference(session.startTime)
          .inSeconds / 60.0;
          
      // Calculate blinks per minute for showing in session detail
      final blinksPerMinute = durationInMinutes > 0 
          ? (session.totalBlinks / durationInMinutes)
          : 0.0;
          
      buffer.writeln('Session: ${session.name ?? dateFormat.format(session.startTime)}');
      buffer.writeln('Start Time: ${dateFormat.format(session.startTime)}');
      buffer.writeln('End Time: ${dateFormat.format(session.endTime)}');
      buffer.writeln('Duration: ${durationInMinutes.toStringAsFixed(1)} minutes');
      buffer.writeln('Total Blinks: ${session.totalBlinks}');
      buffer.writeln('Phone Checks: ${session.phoneChecks}');
      buffer.writeln('Long Blinks: ${session.longBlinks}');
      buffer.writeln('Average Blinks Per Minute: ${blinksPerMinute.toStringAsFixed(1)}');
      buffer.writeln('==================');           //seperating session for better display 
      buffer.writeln();
    }

    return buffer.toString();
  }
}