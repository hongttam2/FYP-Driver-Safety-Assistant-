import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/driving_session.dart';
import '../services/alert_service.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';
import 'package:light/light.dart';


class EyeTrackingProvider extends ChangeNotifier {
  final AlertService _alertService = AlertService();
  final StorageService _storageService = StorageService();
  final SettingsProvider settingsProvider;
  late BuildContext _context;
   Light _lightSensor = Light();
  StreamSubscription<int>? _lightSubscription;

  
  // Constants for eye tracking
  static const double EYE_OPEN_THRESHOLD = 0.85;
  static const double EYE_CLOSED_THRESHOLD = 0.25;
  static const double BLINK_THRESHOLD = 0.15;
  static const int DROWSY_BLINK_THRESHOLD = 600;          //  threshold for drowsy blinks
  static const int PHONE_CHECK_CONFIRMATION_TIME = 1500; // 1.5 seconds to confirm phone check
  static const int SUSTAINED_LOOK_DOWN_TIME = 1000;      // Time to consider as intentional look down

  
  static const int ALERT_INTERVAL = 3000;
    static const double HEAD_DOWN_THRESHOLD = -20.0; // Negative value indicates looking down
    static const double HEAD_ROTATION_THRESHOLD = 15.0; // Threshold for head rotation




  static const double HEAD_SIDE_THRESHOLD = 20.0;
  static const int PHONE_CHECK_DURATION_THRESHOLD = 1500; // in millisecond
  static const double PHONE_PARALLEL_THRESHOLD_Z = 15.0; // Face rotation relative to phone
  static const double PHONE_TILT_THRESHOLD_X = 2;   // Looking down angle
  static const int PHONE_CHECK_DURATION = 100;    

  static const double CAMERA_FOCAL_LENGTH = 800.0; // Approximate focal length in pixels
  static const double AVERAGE_FACE_WIDTH = 0.15; // Average face width in meters
  static const double SENSOR_WIDTH = 0.00368; // Average phone camera sensor width in meters 
  

  // Session tracking
  DateTime? _sessionStartTime;
  String? _currentSessionId;
  List<BlinkDataPoint> _blinkData = [];
  Timer? _blinkDataTimer;
  int _blinksInCurrentMinute = 0;
  DateTime? _currentMinuteStart;
  

  int _phoneChecksInCurrentMinute = 0;
  int _longBlinksInCurrentMinute = 0;




  // Head position tracking
  DateTime? _headDownStartTime;
  bool _isLookingDown = false;
  bool _hasConfirmedPhoneCheck = false;

  // Eye state tracking
  bool _isTracking = false;
  bool _areEyesClosed = false;
  bool _isPreviouslyOpen = true;
  int _eyeClosedDuration = 0;

  DateTime? _lastAlertTime;
  bool _isPotentialPhoneCheck = false;
  bool _isDebugVisible = false; // Add debug visibility control
  // Statistics
  double _lastBlinkDuration = 0;
  double _totalBlinkDuration = 0;
  int _totalBlinks = 0;
  int _longBlinkCount = 0;
  int _phoneCheckCount = 0;
  String _status = 'Not Tracking';
  double _faceDistance = 0.0;
  double _faceAngleX = 0.0;
  double _faceAngleY = 0.0;
  double _faceAngleZ = 0.0;
  double _brightness = 0.0;
  double _lastBlinkDurationdisplay = 0.0;
  

  // Timers
  Timer? _eyeClosedTimer;
  Timer? _sessionTimer;
  
  // Getters
  bool get isTracking => _isTracking;
  bool get isDebugVisible => _isDebugVisible;
  String get status => _status;
  double get lastBlinkDuration => _lastBlinkDuration;
  int get phoneCheckCount => _phoneCheckCount;
  double get blinksPerMinute {
  if (_sessionDuration.inSeconds == 0 || _totalBlinks == 0) return 0.0;
  return (_totalBlinks * 60.0) / _sessionDuration.inSeconds;
}

    // Add getters
  double get faceDistance => _faceDistance;
  double get faceAngleX => _faceAngleX;
  double get faceAngleY => _faceAngleY;
  double get faceAngleZ => _faceAngleZ;
  double get brightness => _brightness;

  // getter for blink data graph
  List<BlinkDataPoint> get blinkData => _blinkData;



  EyeTrackingProvider(this.settingsProvider){
    _lightSubscription = _lightSensor.lightSensorStream.listen((lux) {
      _calculateBrightness(lux.toDouble());
      print('Current Brightness: $_brightness lux'); 
    });
    
  }

  void _calculateBrightness(double luxValue) {
    
    _brightness = luxValue;
    notifyListeners();
  }

  String _getLightingCondition() {
  if (_brightness >= 20 && _brightness <= 160) {
    return 'Ideal';
  } else if (_brightness >= 10 && _brightness < 20) {
    return 'Moderate';
  } else {
    return 'Poor';
  }
}

  void setContext(BuildContext context) {
    _context = context;
  }

  void startTracking() {
    _isTracking = true;
    _sessionStartTime = DateTime.now();
    _currentMinuteStart = _sessionStartTime;
    _currentSessionId = const Uuid().v4();
    _status = 'Tracking Started';
    _startSessionTimer();
    _startBlinkDataCollection();
    notifyListeners();
  }


  void _startBlinkDataCollection() {
  _blinkDataTimer?.cancel();
  _blinksInCurrentMinute = 0;
  _phoneChecksInCurrentMinute = 0;    
  _longBlinksInCurrentMinute = 0;     
  _currentMinuteStart = DateTime.now();

  _blinkDataTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
    if (!_isTracking) {
      timer.cancel();
      return;
    }

    final now = DateTime.now();
    final minuteDuration = now.difference(_currentMinuteStart!).inSeconds / 60.0;
    final blinksPerMinute = _blinksInCurrentMinute / minuteDuration;

    // Add data point with all metrics
    _blinkData.add(BlinkDataPoint(
      timestamp: _currentMinuteStart!,
      blinksInMinute: _blinksInCurrentMinute,
      blinksPerMinute: blinksPerMinute,
      phoneChecksInMinute: _phoneChecksInCurrentMinute,    
      longBlinksInMinute: _longBlinksInCurrentMinute,     
    ));

    // Reset counters
    _blinksInCurrentMinute = 0;
    _phoneChecksInCurrentMinute = 0;   
    _longBlinksInCurrentMinute = 0;    
    _currentMinuteStart = now;
    notifyListeners();
  });
}


  void toggleDebugVisibility() {
    _isDebugVisible = !_isDebugVisible;
    notifyListeners();
  }

  Duration get _sessionDuration {
  if (_sessionStartTime == null) return Duration.zero;
  return DateTime.now().difference(_sessionStartTime!);
}


  void stopTracking() {
  if (_isTracking && _sessionStartTime != null) {
    // Add the final minute's data before saving
    _addFinalMinuteData();
    _saveCurrentSession();
  }
  _resetTracking();
  notifyListeners();
}


  void _addFinalMinuteData() {
  if (_currentMinuteStart != null) {
    final now = DateTime.now();
    final minuteDuration = now.difference(_currentMinuteStart!).inSeconds / 60.0;
    // Only add if there's meaningful data (more than a few seconds)
    if (minuteDuration > 0.1) {
      final blinksPerMinute = _blinksInCurrentMinute / minuteDuration;
      
      _blinkData.add(BlinkDataPoint(
        timestamp: _currentMinuteStart!,
        blinksInMinute: _blinksInCurrentMinute,
        blinksPerMinute: blinksPerMinute,
        phoneChecksInMinute: _phoneChecksInCurrentMinute,    
        longBlinksInMinute: _longBlinksInCurrentMinute,     
      ));
    }
  }
}
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isTracking) {
        timer.cancel();
        return;
      }
      // Update session duration
      notifyListeners();
    });
  }

  Future<void> _saveCurrentSession() async {
    if (_sessionStartTime == null) return;
    // Add final minute data before saving
    _addFinalMinuteData();

    print("Saving session with ${_blinkData.length} blink data points");
    print("Blink data before saving: ${_blinkData.map((e) => e.toJson()).toList()}");

    final session = DrivingSession(
      id: _currentSessionId!,
      startTime: _sessionStartTime!,
      endTime: DateTime.now(),
      totalBlinks: _totalBlinks,
      phoneChecks: _phoneCheckCount,
      averageBlinkDuration: _totalBlinks > 0 
          ? _totalBlinkDuration / _totalBlinks 
          : 0,
      blinkData: List<BlinkDataPoint>.from(_blinkData), // Create a new list to avoid reference issues
      longBlinks: _longBlinkCount,
    );

    await _storageService.saveSession(session);
  }

  void processFace(Face face) {
    if (!_isTracking) return;


    if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
      double avgEyeOpenness = (face.leftEyeOpenProbability! + face.rightEyeOpenProbability!) / 2;
      
      // Apply sensitivity adjustment
      double adjustedOpenThreshold = EYE_OPEN_THRESHOLD * (1 - settingsProvider.blinkSensitivity);
      double adjustedClosedThreshold = EYE_CLOSED_THRESHOLD * settingsProvider.blinkSensitivity;
      double adjustedBlinkThreshold = BLINK_THRESHOLD * settingsProvider.blinkSensitivity;
      

      bool isCurrentlyOpen = avgEyeOpenness > adjustedOpenThreshold;
      bool isCurrentlyClosed = avgEyeOpenness < adjustedClosedThreshold;
      bool isBlinking = avgEyeOpenness < adjustedBlinkThreshold;

      _processEyeState(isCurrentlyOpen, isCurrentlyClosed, isBlinking);
      _checkHeadPosition(face);
      _calculateFaceMetrics(face);
      notifyListeners();
    }
  }

  void _calculateFaceMetrics(Face face) {
    //  face angles
    _faceAngleX = face.headEulerAngleX ?? 0.0;
    _faceAngleY = face.headEulerAngleY ?? 0.0;
    _faceAngleZ = face.headEulerAngleZ ?? 0.0;
    if (face.boundingBox.width > 0) {  
      // D = (W × F) / P
      // Where: D = Distance, W = Real face width, F = Focal length, P = Face width in pixels
      _faceDistance = (AVERAGE_FACE_WIDTH * CAMERA_FOCAL_LENGTH) / face.boundingBox.width;
    }

    notifyListeners();
  }

  

 void _processEyeState(bool isCurrentlyOpen, bool isCurrentlyClosed, bool isBlinking) {
  
    // Handle eye closure
    if (isCurrentlyClosed && !_areEyesClosed) {
      _handleEyeClose();
    } else if (isCurrentlyOpen && _areEyesClosed) {
      _handleEyeOpen();
    }
    // Handle blink detection
    if (isBlinking && _isPreviouslyOpen) {
      _handleBlink();
    } 
    _isPreviouslyOpen = isCurrentlyOpen;
  }

  

  void _handleEyeOpen() {
    _areEyesClosed = false;
    _eyeClosedDuration = 0;
    _eyeClosedTimer?.cancel();
    _status = 'Eyes Open';
  }

  void _handleEyeClose() {
    _areEyesClosed = true;
    _status = 'Eyes Closed';
    
    _eyeClosedTimer?.cancel();
    _eyeClosedTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) { // Increment by 100 milliseconds each time
      _eyeClosedDuration += 100;
       double adjustedDrowsyThreshold = DROWSY_BLINK_THRESHOLD + (settingsProvider.drowsyThreshold * 1000);
      if (_eyeClosedDuration >= adjustedDrowsyThreshold && _canTriggerAlert()) {
        _alertService.triggerAlert(
          context: _context,
          message: 'Warning! Eyes closed for too long!',
          type: AlertType.drowsy,
          playSound: settingsProvider.soundEnabled,
        );
        _longBlinkCount++;
        _longBlinksInCurrentMinute++;
        _lastAlertTime = DateTime.now();
      }
      notifyListeners();
      _lastBlinkDurationdisplay = _eyeClosedDuration / 1000;
    });
}

  void _handleBlink() {
    _status = 'Blink Detected';
    _totalBlinks++;
    _blinksInCurrentMinute++;
  }


  void _checkHeadPosition(Face face) {
    if (face.headEulerAngleX == null || 
        face.headEulerAngleY == null || 
        face.headEulerAngleZ == null) return;

    final headDown = face.headEulerAngleX! > HEAD_DOWN_THRESHOLD;
    final headRotation = face.headEulerAngleY!.abs() < HEAD_ROTATION_THRESHOLD;
    final headTilt = face.headEulerAngleZ!.abs() < HEAD_ROTATION_THRESHOLD;

    // Check if face is in position that similar to phone checking
    bool isPotentialPhoneCheckPosition = headDown && headRotation && headTilt;

    if (isPotentialPhoneCheckPosition && !_isLookingDown) {
      // Start tracking potential phone check
      _isLookingDown = true;
      _headDownStartTime = DateTime.now();
      _status = 'Potential phone check detected';
    } 
    else if (isPotentialPhoneCheckPosition && _isLookingDown) {
      // Continue tracking the phone check
      if (_headDownStartTime != null && !_hasConfirmedPhoneCheck) {
        final lookDownDuration = DateTime.now().difference(_headDownStartTime!).inMilliseconds;
        
        if (lookDownDuration > SUSTAINED_LOOK_DOWN_TIME) {
          _isPotentialPhoneCheck = true;
          _status = 'Sustained look down detected';
        }
      
        if (lookDownDuration > PHONE_CHECK_CONFIRMATION_TIME && _canTriggerAlert()) {
          _confirmPhoneCheck();
        }
      }
    }

   
    else if (!isPotentialPhoneCheckPosition) {

      _resetPhoneCheckTracking(); // Reset tracking when head position changes
    }

    notifyListeners();
  }

  void _confirmPhoneCheck() {
    _phoneCheckCount++;
    _hasConfirmedPhoneCheck = true;
    _status = 'Phone check confirmed';

    
     _phoneChecksInCurrentMinute++;  
    
    _alertService.triggerAlert(
      context: _context,
      message: 'Phone use detected! Please keep your eyes on the road.',
      type: AlertType.phoneDistraction,
      playSound: settingsProvider.soundEnabled,
    );
    
    _lastAlertTime = DateTime.now();
    notifyListeners();
  }

  void _resetPhoneCheckTracking() {
    _isLookingDown = false;
    _isPotentialPhoneCheck = false;
    _hasConfirmedPhoneCheck = false;
    _headDownStartTime = null;
    if (_status.contains('phone check')) {
      _status = 'Face aligned';
    }
  }
  bool _canTriggerAlert() {
    if (_lastAlertTime == null) return true;
    return DateTime.now().difference(_lastAlertTime!) > 
           const Duration(milliseconds: ALERT_INTERVAL);
  }

  void _resetTracking() {
    _isTracking = false;
    _areEyesClosed = false;
    _isPreviouslyOpen = true;
    _eyeClosedDuration = 0;
    _eyeClosedTimer?.cancel();
    _sessionTimer?.cancel();
    _lastBlinkDuration = 0;
    _totalBlinkDuration = 0;
    _totalBlinks = 0;
    _longBlinkCount = 0;
    _phoneCheckCount = 0;
    _sessionStartTime = null;
    _currentSessionId = null;
    _status = 'Not Tracking';
    _blinkData.clear();
    _blinkDataTimer?.cancel();
    _blinksInCurrentMinute = 0;
    _currentMinuteStart = null;
    _phoneChecksInCurrentMinute = 0;
    _longBlinksInCurrentMinute = 0;
    _isLookingDown = false;
    _hasConfirmedPhoneCheck = false;
    _isPotentialPhoneCheck = false;
    _headDownStartTime = null;
    _faceDistance = 0.0;
    _lastBlinkDurationdisplay = 0.0;
  }

  @override
  void dispose() {
    _lightSubscription?.cancel();
    _eyeClosedTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  
  Map<String, dynamic> getDebugStats() {
    final baseStats = {
      'isTracking': _isTracking,
      'user status': _status,
      'totalBlinks': _totalBlinks,
      'blinksPerMinute': blinksPerMinute.toStringAsFixed(1),
      'lastDrowsyBlinkDuration': '$_lastBlinkDurationdisplay Sec ', //check
      //'eyeClosedDuration': _eyeClosedDuration,
      'phoneCheckCount': _phoneCheckCount,
      'longBlinkCount': _longBlinkCount,
        'Brightness': brightness,
      'lighting Condition': _getLightingCondition(), 
      'faceDistance': '${(_faceDistance * 100).toStringAsFixed(0)}cm',
      'faceStatus': _isTracking? _getFaceOrientationStatus() : 'Not Tracking',
      'distanceStatus': _isTracking ? _getFaceDistanceStatus() : 'Not Tracking',
      //'headAngles': 'X: ${_faceAngleX.toStringAsFixed(1)}°, Y: ${_faceAngleY.toStringAsFixed(1)}°, Z: ${_faceAngleZ.toStringAsFixed(1)}°',
      //'isLookingDown': _isLookingDown,
      'isPotentialPhoneCheck': _isPotentialPhoneCheck,
      'lookDownDuration': _headDownStartTime != null && _isTracking
          ? DateTime.now().difference(_headDownStartTime!).inMilliseconds 
          : 0,
    };
    return baseStats;
  }


  String _getFaceDistanceStatus() {
    if (_faceDistance == 0.0) return 'No face detected';
    if (_faceDistance < 0.1) return 'Too Close';
    if (_faceDistance > 0.4) return 'Too Far';
    return 'Optimal';       // these are in cm 
  }

  String _getFaceOrientationStatus() {
    if (_faceAngleX.abs() > 30 || 
        _faceAngleY.abs() > 30 || 
        _faceAngleZ.abs() > 30) {
      return 'Face Not Aligned';
    }
    return 'Face Aligned';
  }

/*
  bool _getFaceOrientationStatusbool() {
    if (_faceAngleX.abs() > 30 || 
        _faceAngleY.abs() > 30 || 
        _faceAngleZ.abs() > 30) {
      return false;
    }
    return true;
  }
  */
}