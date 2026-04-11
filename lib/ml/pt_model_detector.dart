import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';

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
  List<int> _outputShape = const [1, 1];
  List<List<List<List<double>>>>? _inputBuffer;
  bool _hasLoggedInferenceError = false;

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

      _outputShape = _interpreter!.getOutputTensor(0).shape;

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
    return detectFromLuma(image.planes.first.bytes, image.width, image.height);
  }

  Future<List<DetectionResult>> detectFromLuma(
    Uint8List yPlane,
    int srcWidth,
    int srcHeight,
  ) async {
    if (!_isInitialized || !_isModelAssetFound || _interpreter == null) {
      return const [];
    }

    try {
      final input = _buildInputTensor(yPlane, srcWidth, srcHeight);
      final output = _allocateOutputBuffer(_outputShape, 0);
      _interpreter!.run(input, output);
      _hasLoggedInferenceError = false;

      final result = _extractBestDetection(output);
      if (result == null || result.confidence < 0.45) {
        return const [];
      }

      return [result];
    } catch (e) {
      if (!_hasLoggedInferenceError) {
        debugPrint('Inference error: $e');
        _hasLoggedInferenceError = true;
      }
      return const [];
    }
  }

  dynamic _allocateOutputBuffer(List<int> shape, int depth) {
    final dim = shape[depth];
    if (depth == shape.length - 1) {
      return List<double>.filled(dim, 0.0);
    }
    return List.generate(dim, (_) => _allocateOutputBuffer(shape, depth + 1));
  }

  DetectionResult? _extractBestDetection(dynamic output) {
    if (_outputShape.length == 2 && _outputShape[0] == 1) {
      final scores = (output as List).first as List;
      if (scores.isEmpty) {
        return null;
      }

      int bestIndex = 0;
      double bestScore = (scores[0] as num).toDouble();
      for (int i = 1; i < scores.length; i++) {
        final value = (scores[i] as num).toDouble();
        if (value > bestScore) {
          bestScore = value;
          bestIndex = i;
        }
      }

      return DetectionResult(
        label: bestIndex == 0 ? 'road_hazard' : 'class_$bestIndex',
        confidence: bestScore,
        detectedAt: DateTime.now(),
      );
    }

    // YOLO-like output support, e.g. [1, 8, 8400] or [1, 8400, 8].
    if (_outputShape.length == 3 && _outputShape[0] == 1) {
      final shapeA = _outputShape[1];
      final shapeB = _outputShape[2];

      final classAxisLikelyA = shapeA <= 16;
      if (classAxisLikelyA) {
        final channels = shapeA;
        final boxes = shapeB;
        final data = output as List;
        final channelMajor = data.first as List;

        int bestClass = 0;
        double bestConfidence = 0.0;

        for (int b = 0; b < boxes; b++) {
          final objectness = channels > 4
              ? ((channelMajor[4] as List)[b] as num).toDouble()
              : 1.0;

          double classScore = objectness;
          int classIndex = 0;

          if (channels > 5) {
            double maxClass = 0.0;
            int maxIndex = 0;
            for (int c = 5; c < channels; c++) {
              final value = ((channelMajor[c] as List)[b] as num).toDouble();
              if (value > maxClass) {
                maxClass = value;
                maxIndex = c - 5;
              }
            }
            classScore = objectness * maxClass;
            classIndex = maxIndex;
          }

          if (classScore > bestConfidence) {
            bestConfidence = classScore;
            bestClass = classIndex;
          }
        }

        return DetectionResult(
          label: bestClass == 0 ? 'road_hazard' : 'class_$bestClass',
          confidence: bestConfidence,
          detectedAt: DateTime.now(),
        );
      }

      final boxes = shapeA;
      final channels = shapeB;
      final data = output as List;
      final boxMajor = data.first as List;

      int bestClass = 0;
      double bestConfidence = 0.0;

      for (int b = 0; b < boxes; b++) {
        final row = boxMajor[b] as List;
        final objectness = channels > 4 ? (row[4] as num).toDouble() : 1.0;

        double classScore = objectness;
        int classIndex = 0;

        if (channels > 5) {
          double maxClass = 0.0;
          int maxIndex = 0;
          for (int c = 5; c < channels; c++) {
            final value = (row[c] as num).toDouble();
            if (value > maxClass) {
              maxClass = value;
              maxIndex = c - 5;
            }
          }
          classScore = objectness * maxClass;
          classIndex = maxIndex;
        }

        if (classScore > bestConfidence) {
          bestConfidence = classScore;
          bestClass = classIndex;
        }
      }

      return DetectionResult(
        label: bestClass == 0 ? 'road_hazard' : 'class_$bestClass',
        confidence: bestConfidence,
        detectedAt: DateTime.now(),
      );
    }

    return null;
  }

  List<List<List<List<double>>>> _buildInputTensor(
    Uint8List yPlane,
    int srcWidth,
    int srcHeight,
  ) {
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
