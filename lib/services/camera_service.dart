import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class CameraService {
  CameraController? _cameraController;
  CameraDescription? _frontCamera;

  bool _isInitialized = false;
  static const int GC_INTERVAL = 2000; 

  Future<void> initialize() async {

    final cameras = await availableCameras();
    _frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);
    _cameraController = CameraController(_frontCamera!, ResolutionPreset.high);       //preset resolution
    await _cameraController!.initialize();
    _isInitialized = true;
  }

  Future<void> startImageStream(Function(InputImage) onImage) async {         //formatting image to metadata for future processing by Goggle ML Kit model
    if (!_isInitialized) return;
    await _cameraController!.startImageStream((CameraImage image) async {
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final InputImageRotation imageRotation = InputImageRotationValue.fromRawValue(_cameraController!.description.sensorOrientation) ?? InputImageRotation.rotation0deg;

      final InputImageFormat inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,               
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );

      onImage(inputImage);
    });
  }

  Future<void> stopImageStream() async {
    if (!_isInitialized) return;
      await _cameraController!.stopImageStream();
  }

  Future<void> dispose() async {
    await _cameraController?.dispose();
    _isInitialized = false;
  }

  CameraController? get controller => _cameraController;
  bool get isInitialized => _isInitialized;
}

