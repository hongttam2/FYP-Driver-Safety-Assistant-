import 'package:eye_tracking_safety/widgets/consent_dialog.dart.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/eye_tracking_provider.dart';
import '../widgets/safety_stats_widget.dart';
import '../widgets/debug_overlay_widget.dart';
import '../services/camera_service.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  late final FaceDetector _faceDetector;
  bool _isPermissionGranted = false;
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  String _errorMessage = '';
  DateTime? _sessionStartTime;
  bool _hasShownConsent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFaceDetector();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _showConsentDialog();
  });
    _requestCameraPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EyeTrackingProvider>(context, listen: false)
          .setContext(context);
    });
  }



  Future<void> _showConsentDialog() async {                   //show consenet dialog 
  if (_hasShownConsent) return;
  
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ConsentDialog(
      onAccept: () {
        Navigator.of(context).pop();
        _hasShownConsent = true;
        _requestCameraPermission();
      },
    ),
  );
}


  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: true,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraService.isInitialized) return;
    
    switch (state) {
      case AppLifecycleState.inactive:
        _stopTracking();
        _cameraService.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        _initializeCamera();
        break;
      default:
        break;
    }
  }

  Future<void> _requestCameraPermission() async {
  if (!_hasShownConsent) return;
  
  final status = await Permission.camera.request();
  setState(() => _isPermissionGranted = status.isGranted);
  
  if (_isPermissionGranted) {
    await _initializeCamera();
  }
}

  void _stopTracking() {
    final provider = Provider.of<EyeTrackingProvider>(context, listen: false);
    if (provider.isTracking) {
      provider.stopTracking();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize();
      setState(() => _isCameraInitialized = true);
      await _startImageProcessing();
    } catch (e) {
      setState(() {
        _isCameraError = true;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }


  Future<void> _startImageProcessing() async {
    await _cameraService.startImageStream((inputImage) async {
      try {
        final faces = await _faceDetector.processImage(inputImage);
        if (faces.isNotEmpty && mounted) {
          final provider = Provider.of<EyeTrackingProvider>(context, listen: false);
          provider.processFace(faces.first);
        }
      } catch (e) {
        debugPrint('Error processing image: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
  return AppBar(
    title: const Text(
      'Driver Safety Assistant',
      style: TextStyle(fontSize: 16),
    ),
    actions: [
      Consumer<EyeTrackingProvider>(
        builder: (context, provider, _) => Switch(
          value: provider.isDebugVisible,
          onChanged: (_) => provider.toggleDebugVisibility(),
          activeColor: Colors.green,
          inactiveThumbColor: Colors.grey,
        ),
      ),
      IconButton(
        icon: const Icon(Icons.history),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistoryScreen()),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        ),
      ),
    ],
  );
}

  Widget _buildBody() {
    if (_isCameraError) {
      return _buildErrorState();
    }
    if (!_isPermissionGranted) {
      return _buildPermissionState();
    }
    if (!_isCameraInitialized) {
      return _buildLoadingState();
    }
    return _buildTrackingInterface();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeCamera,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off, size: 48),
          const SizedBox(height: 16),
          const Text('Camera permission is required'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _requestCameraPermission,
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildTrackingInterface() {
  return Consumer<EyeTrackingProvider>(
    builder: (context, provider, child) {
      return Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _buildCameraPreview(),
              ),
              _buildStatusBar(provider),
              SafetyStatsWidget(provider: provider),
              _buildControlButtons(provider),
            ],
          ),
          if (provider.isDebugVisible) 
            DebugOverlayWidget(provider: provider),
        ],
      );
    },
  );
}

  Widget _buildCameraPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CameraPreview(_cameraService.controller!),
    );
  }

  Widget _buildStatusBar(EyeTrackingProvider provider) {           // status bar of the main feature ( showing user real time status )
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            provider.isTracking ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            'Status: ${provider.status}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(EyeTrackingProvider provider) {               // start , stop button of the main feature
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (provider.isTracking) {
                  provider.stopTracking();
                } else {
                  provider.startTracking();
                  _sessionStartTime = DateTime.now();
                }
              },
              icon: Icon(provider.isTracking ? Icons.stop : Icons.play_arrow),      
              label: Text(provider.isTracking ? 'Stop' : 'Start'),
              style: ElevatedButton.styleFrom(
                backgroundColor: provider.isTracking ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}