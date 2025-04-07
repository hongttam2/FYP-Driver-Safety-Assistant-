class BlinkDataPoint {
  final DateTime timestamp;
  final int blinksInMinute;
  final double blinksPerMinute;
  final int phoneChecksInMinute;
  final int longBlinksInMinute;

  BlinkDataPoint({
    required this.timestamp,
    required this.blinksInMinute,
    required this.blinksPerMinute,
    required this.phoneChecksInMinute,
    required this.longBlinksInMinute,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'blinksInMinute': blinksInMinute,
    'blinksPerMinute': blinksPerMinute,
    'phoneChecksInMinute': phoneChecksInMinute,
    'longBlinksInMinute': longBlinksInMinute,
  };

  factory BlinkDataPoint.fromJson(Map<String, dynamic> json) {
    return BlinkDataPoint(
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      blinksInMinute: json['blinksInMinute'] as int? ?? 0,                    // Handle null
      blinksPerMinute: (json['blinksPerMinute'] as num?)?.toDouble() ?? 0.0,
      phoneChecksInMinute: json['phoneChecksInMinute'] as int? ?? 0,          // Handle null
      longBlinksInMinute: json['longBlinksInMinute'] as int? ?? 0,            // Handle null
    );
  }
}

class DrivingSession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int totalBlinks;
  final int phoneChecks;
  final double averageBlinkDuration;
  final List<BlinkDataPoint> blinkData;
  final String? name;
  final int longBlinks;

  DrivingSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.totalBlinks,
    required this.phoneChecks,
    required this.averageBlinkDuration,
    this.blinkData = const [],
    this.name,
    required this.longBlinks,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalBlinks': totalBlinks,
      'phoneChecks': phoneChecks,
      'averageBlinkDuration': averageBlinkDuration,
      'blinkData': blinkData.map((point) => point.toJson()).toList(),
      'name': name,
      'longBlinks': longBlinks,
    };
  }

  factory DrivingSession.fromJson(Map<String, dynamic> json) {
    final blinkDataJson = json['blinkData'] as List<dynamic>?;
    final blinkDataList = blinkDataJson?.map((point) {
      try {
        return BlinkDataPoint.fromJson(point as Map<String, dynamic>);
      } catch (e) {
        print('Error parsing BlinkDataPoint: $e, JSON: $point');
        return BlinkDataPoint(
          timestamp: DateTime.now(),
          blinksInMinute: 0,
          blinksPerMinute: 0.0,
          phoneChecksInMinute: 0,
          longBlinksInMinute: 0,
        );
      }
    }).toList() ?? [];

    return DrivingSession(
      id: json['id'] as String? ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? '') ?? DateTime.now(),
      totalBlinks: json['totalBlinks'] as int? ?? 0,                        // Handle null
      phoneChecks: json['phoneChecks'] as int? ?? 0,                        // Handle null
      averageBlinkDuration: (json['averageBlinkDuration'] as num?)?.toDouble() ?? 0.0,
      blinkData: blinkDataList,
      name: json['name'] as String?,
      longBlinks: json['longBlinks'] as int? ?? 0,                          // Handle null
    );
  }
}