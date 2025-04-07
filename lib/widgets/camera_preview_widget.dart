import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraService cameraService;

  const CameraPreviewWidget({
    Key? key,
    required this.cameraService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!cameraService.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Transform.scale(
      scale: 1.0,
      child: Center(
        child: CameraPreview(cameraService.controller!),
      ),
    );
  }
}