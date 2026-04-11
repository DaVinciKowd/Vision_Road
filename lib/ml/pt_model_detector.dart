import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class DetectionResult {
  final String label;
  final double confidence;
  final DateTime detectedAt;

  const DetectionResult({
    required this.label,
    required this.confidence,
    required this.detectedAt,
  });
}

class PtModelDetector {
  PtModelDetector({required this.modelAssetPath});

  final String modelAssetPath;

  bool _isInitialized = false;
  bool _isModelAssetFound = false;
  Interpreter? _interpreter;

  int _inputHeight = 224;
  int _inputWidth = 224;
  int _inputChannels = 3;
  int _outputLength = 1;
  List<List<List<List<double>>>>? _inputBuffer;

  bool get isInitialized => _isInitialized;
  bool get isModelAssetFound => _isModelAssetFound;

  Future<void> initialize() async {
    try {
      final normalizedPath = modelAssetPath.toLowerCase();
      if (!normalizedPath.endsWith('.tflite')) {
        _isModelAssetFound = false;
        debugPrint(
          'Model must be .tflite for in-app inference. Provided: $modelAssetPath',
        );
        _isInitialized = true;
        return;
      }

      await rootBundle.load(modelAssetPath);

      _interpreter = await Interpreter.fromAsset(
        modelAssetPath,
        options: InterpreterOptions()..threads = 2,
      );

      final inputShape = _interpreter!.getInputTensor(0).shape;
      if (inputShape.length >= 4) {
        _inputHeight = inputShape[1];
        _inputWidth = inputShape[2];
        _inputChannels = inputShape[3];
      }

      final outputShape = _interpreter!.getOutputTensor(0).shape;
      _outputLength = 1;
      for (int i = 1; i < outputShape.length; i++) {
        _outputLength *= outputShape[i];
      }

      _isModelAssetFound = true;
      debugPrint('TFLite model loaded at $modelAssetPath');
    } catch (_) {
      _isModelAssetFound = false;
      debugPrint(
        'TFLite model is missing or invalid. Add your .tflite file at $modelAssetPath and rebuild.',
      );
    }

    _isInitialized = true;
  }

  Future<List<DetectionResult>> detect(CameraImage image) async {
    if (!_isInitialized || !_isModelAssetFound || _interpreter == null) {
      return const [];
    }

    try {
      final input = _buildInputTensor(image);
      final output = [List<double>.filled(_outputLength, 0.0)];
      _interpreter!.run(input, output);

      final scores = output.first;
      if (scores.isEmpty) {
        return const [];
      }

      int bestIndex = 0;
      double bestScore = scores[0];
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > bestScore) {
          bestScore = scores[i];
          bestIndex = i;
        }
      }

      if (bestScore < 0.5) {
        return const [];
      }

      return [
        DetectionResult(
          label: bestIndex == 0 ? 'road_hazard' : 'class_$bestIndex',
          confidence: bestScore,
          detectedAt: DateTime.now(),
        ),
      ];
    } catch (e) {
      debugPrint('Inference error: $e');
      return const [];
    }
  }

  List<List<List<List<double>>>> _buildInputTensor(CameraImage image) {
    final yPlane = image.planes.first.bytes;
    final srcWidth = image.width;
    final srcHeight = image.height;

    _inputBuffer ??= List.generate(
      1,
      (_) => List.generate(
        _inputHeight,
        (_) => List.generate(
          _inputWidth,
          (_) => List<double>.filled(_inputChannels, 0.0),
        ),
      ),
    );

    final input = _inputBuffer!;

    for (int y = 0; y < _inputHeight; y++) {
      final srcY = (y * srcHeight / _inputHeight).floor().clamp(0, srcHeight - 1);
      for (int x = 0; x < _inputWidth; x++) {
        final srcX = (x * srcWidth / _inputWidth).floor().clamp(0, srcWidth - 1);
        final luminance = yPlane[srcY * srcWidth + srcX] / 255.0;

        if (_inputChannels == 1) {
          input[0][y][x][0] = luminance;
        } else {
          for (int c = 0; c < _inputChannels; c++) {
            input[0][y][x][c] = luminance;
          }
        }
      }
    }

    return input;
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _inputBuffer = null;
  }
}
