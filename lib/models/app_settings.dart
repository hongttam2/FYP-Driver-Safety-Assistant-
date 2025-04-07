class AppSettings {
  final bool enableSoundAlerts;
  final double blinkDurationThreshold;
  final int phoneCheckThreshold;
  final bool enableBackgroundTracking;
  final bool darkModeEnabled;

  AppSettings({
    this.enableSoundAlerts = true,
    this.blinkDurationThreshold = 500.0,
    this.phoneCheckThreshold = 3,
    this.enableBackgroundTracking = false,
    this.darkModeEnabled = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      enableSoundAlerts: json['enableSoundAlerts'] ?? true,
      blinkDurationThreshold: json['blinkDurationThreshold']?.toDouble() ?? 500.0,     //defult set to 500ms if no changes 
      phoneCheckThreshold: json['phoneCheckThreshold'] ?? 3,                    //same for phone checking
      enableBackgroundTracking: json['enableBackgroundTracking'] ?? false,      //tried to implement backgroundtracking , not developed in this project 
     
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableSoundAlerts': enableSoundAlerts,
      'blinkDurationThreshold': blinkDurationThreshold,
      'phoneCheckThreshold': phoneCheckThreshold,
      'enableBackgroundTracking': enableBackgroundTracking,
      
    };
  }

  AppSettings copyWith({
    bool? enableSoundAlerts,
    double? blinkDurationThreshold,
    int? phoneCheckThreshold,
    bool? enableBackgroundTracking,
   
  }) {
    return AppSettings(
      enableSoundAlerts: enableSoundAlerts ?? this.enableSoundAlerts,
      blinkDurationThreshold: blinkDurationThreshold ?? this.blinkDurationThreshold,
      phoneCheckThreshold: phoneCheckThreshold ?? this.phoneCheckThreshold,
      enableBackgroundTracking: enableBackgroundTracking ?? this.enableBackgroundTracking,

    );
  }
}