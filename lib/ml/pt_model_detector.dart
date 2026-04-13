import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:ui';
import 'dart:typed_data';

class DetectionResult {
  final String label;
  final double confidence;
  final Rect boundingBox;
  final DateTime detectedAt;

  const DetectionResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.detectedAt,
  });
}

class PtModelDetector {
  PtModelDetector({required this.modelAssetPath});

  final String modelAssetPath;

  bool _isInitialized = false;
  bool _isModelAssetFound = false;
  Interpreter? _interpreter;

  int _inputHeight = 640;
  int _inputWidth = 640;
  int _inputChannels = 3;
  List<int> _outputShape = const [1, 1];
  List<List<List<List<double>>>>? _inputBuffer;
  bool _hasLoggedInferenceError = false;

  bool get isInitialized => _isInitialized;
  bool get isModelAssetFound => _isModelAssetFound;
  int get inputWidth => _inputWidth;
  int get inputHeight => _inputHeight;

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
        boundingBox: Rect.zero,
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
        Rect bestBox = Rect.zero;

        for (int b = 0; b < boxes; b++) {
          final x = ((channelMajor[0] as List)[b] as num).toDouble();
          final y = ((channelMajor[1] as List)[b] as num).toDouble();
          final width = ((channelMajor[2] as List)[b] as num).toDouble();
          final height = ((channelMajor[3] as List)[b] as num).toDouble();
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
            bestBox = _buildBoundingBox(x, y, width, height);
          }
        }

        return DetectionResult(
          label: bestClass == 0 ? 'road_hazard' : 'class_$bestClass',
          confidence: bestConfidence,
          boundingBox: bestBox,
          detectedAt: DateTime.now(),
        );
      }

      final boxes = shapeA;
      final channels = shapeB;
      final data = output as List;
      final boxMajor = data.first as List;

      int bestClass = 0;
      double bestConfidence = 0.0;
      Rect bestBox = Rect.zero;

      for (int b = 0; b < boxes; b++) {
        final row = boxMajor[b] as List;
        final x = (row[0] as num).toDouble();
        final y = (row[1] as num).toDouble();
        final width = (row[2] as num).toDouble();
        final height = (row[3] as num).toDouble();
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
          bestBox = _buildBoundingBox(x, y, width, height);
        }
      }

      return DetectionResult(
        label: bestClass == 0 ? 'road_hazard' : 'class_$bestClass',
        confidence: bestConfidence,
        boundingBox: bestBox,
        detectedAt: DateTime.now(),
      );
    }

    return null;
  }

  Rect _buildBoundingBox(
    double x,
    double y,
    double width,
    double height,
  ) {
    final looksNormalized = [x, y, width, height].every((value) => value.abs() <= 2.0);
    final scaleX = looksNormalized ? _inputWidth.toDouble() : 1.0;
    final scaleY = looksNormalized ? _inputHeight.toDouble() : 1.0;

    final boxWidth = (width * scaleX).abs().clamp(1.0, _inputWidth.toDouble());
    final boxHeight = (height * scaleY).abs().clamp(1.0, _inputHeight.toDouble());
    final centerX = x * scaleX;
    final centerY = y * scaleY;

    final left = (centerX - boxWidth / 2).clamp(0.0, _inputWidth.toDouble());
    final top = (centerY - boxHeight / 2).clamp(0.0, _inputHeight.toDouble());
    final right = (left + boxWidth).clamp(0.0, _inputWidth.toDouble());
    final bottom = (top + boxHeight).clamp(0.0, _inputHeight.toDouble());

    return Rect.fromLTRB(left, top, right, bottom);
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
