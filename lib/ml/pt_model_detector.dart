import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'dart:typed_data';

class _PreprocessRequest {
  const _PreprocessRequest({
    required this.yPlane,
    required this.srcWidth,
    required this.srcHeight,
    required this.inputWidth,
    required this.inputHeight,
    required this.inputChannels,
  });

  final Uint8List yPlane;
  final int srcWidth;
  final int srcHeight;
  final int inputWidth;
  final int inputHeight;
  final int inputChannels;
}

List<List<List<List<double>>>> _buildInputTensorInIsolate(_PreprocessRequest request) {
  final input = List.generate(
    1,
    (_) => List.generate(
      request.inputHeight,
      (_) => List.generate(
        request.inputWidth,
        (_) => List<double>.filled(request.inputChannels, 0.0),
      ),
    ),
  );

  for (int y = 0; y < request.inputHeight; y++) {
    final srcY =
        (y * request.srcHeight / request.inputHeight).floor().clamp(0, request.srcHeight - 1);
    for (int x = 0; x < request.inputWidth; x++) {
      final srcX =
          (x * request.srcWidth / request.inputWidth).floor().clamp(0, request.srcWidth - 1);
      final luminance = request.yPlane[srcY * request.srcWidth + srcX] / 255.0;

      if (request.inputChannels == 1) {
        input[0][y][x][0] = luminance;
      } else {
        for (int c = 0; c < request.inputChannels; c++) {
          input[0][y][x][c] = luminance;
        }
      }
    }
  }

  return input;
}

dynamic _allocateOutputBufferForWorker(List<int> shape, int depth) {
  final dim = shape[depth];
  if (depth == shape.length - 1) {
    return List<double>.filled(dim, 0.0);
  }
  return List.generate(dim, (_) => _allocateOutputBufferForWorker(shape, depth + 1));
}

void _resetOutputBufferForWorker(dynamic buffer) {
  if (buffer is List<double>) {
    for (int i = 0; i < buffer.length; i++) {
      buffer[i] = 0.0;
    }
    return;
  }

  if (buffer is List) {
    for (final child in buffer) {
      _resetOutputBufferForWorker(child);
    }
  }
}

Rect _buildBoundingBoxForWorker(
  double x,
  double y,
  double width,
  double height,
  int inputWidth,
  int inputHeight,
) {
  final looksNormalized = [x, y, width, height].every((value) => value.abs() <= 2.0);
  final scaleX = looksNormalized ? inputWidth.toDouble() : 1.0;
  final scaleY = looksNormalized ? inputHeight.toDouble() : 1.0;

  final boxWidth = (width * scaleX).abs().clamp(1.0, inputWidth.toDouble());
  final boxHeight = (height * scaleY).abs().clamp(1.0, inputHeight.toDouble());
  final centerX = x * scaleX;
  final centerY = y * scaleY;

  final left = (centerX - boxWidth / 2).clamp(0.0, inputWidth.toDouble());
  final top = (centerY - boxHeight / 2).clamp(0.0, inputHeight.toDouble());
  final right = (left + boxWidth).clamp(0.0, inputWidth.toDouble());
  final bottom = (top + boxHeight).clamp(0.0, inputHeight.toDouble());

  return Rect.fromLTRB(left, top, right, bottom);
}

bool _isCandidateBoxValidForWorker(Rect box, int inputWidth, int inputHeight) {
  if (box.isEmpty) {
    return false;
  }

  final width = box.width;
  final height = box.height;
  if (width < 6 || height < 6) {
    return false;
  }

  final minArea = inputWidth * inputHeight * 0.0001;
  return width * height >= minArea;
}

Map<String, dynamic>? _extractBestDetectionForWorker(
  dynamic output,
  List<int> outputShape,
  int inputWidth,
  int inputHeight,
  double minDetectionConfidence,
) {
  if (outputShape.length == 2 && outputShape[0] == 1) {
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

    if (bestScore < minDetectionConfidence) {
      return null;
    }

    return {
      'label': bestIndex == 0 ? 'road_hazard' : 'class_$bestIndex',
      'confidence': bestScore,
      'left': 0.0,
      'top': 0.0,
      'right': 0.0,
      'bottom': 0.0,
    };
  }

  if (outputShape.length == 3 && outputShape[0] == 1) {
    final shapeA = outputShape[1];
    final shapeB = outputShape[2];

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
        final candidateBox = _buildBoundingBoxForWorker(x, y, width, height, inputWidth, inputHeight);
        final objectness = channels > 4 ? ((channelMajor[4] as List)[b] as num).toDouble() : 1.0;

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
          bestBox = _isCandidateBoxValidForWorker(candidateBox, inputWidth, inputHeight)
              ? candidateBox
              : Rect.zero;
        }
      }

      if (bestConfidence < minDetectionConfidence) {
        return null;
      }

      return {
        'label': bestClass == 0 ? 'road_hazard' : 'class_$bestClass',
        'confidence': bestConfidence,
        'left': bestBox.left,
        'top': bestBox.top,
        'right': bestBox.right,
        'bottom': bestBox.bottom,
      };
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
      final candidateBox = _buildBoundingBoxForWorker(x, y, width, height, inputWidth, inputHeight);
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
        bestBox = _isCandidateBoxValidForWorker(candidateBox, inputWidth, inputHeight)
            ? candidateBox
            : Rect.zero;
      }
    }

    if (bestConfidence < minDetectionConfidence) {
      return null;
    }

    return {
      'label': bestClass == 0 ? 'road_hazard' : 'class_$bestClass',
      'confidence': bestConfidence,
      'left': bestBox.left,
      'top': bestBox.top,
      'right': bestBox.right,
      'bottom': bestBox.bottom,
    };
  }

  return null;
}

void _inferenceWorkerMain(Map<String, dynamic> initMessage) {
  final mainSendPort = initMessage['mainSendPort'] as SendPort;
  final interpreterAddress = initMessage['interpreterAddress'] as int;
  final inputWidth = initMessage['inputWidth'] as int;
  final inputHeight = initMessage['inputHeight'] as int;
  final inputChannels = initMessage['inputChannels'] as int;
  final minDetectionConfidence = (initMessage['minDetectionConfidence'] as num).toDouble();

  final commandPort = ReceivePort();
  mainSendPort.send(commandPort.sendPort);

  final interpreter = Interpreter.fromAddress(interpreterAddress);
  final outputShape = interpreter.getOutputTensor(0).shape;
  final outputBuffer = _allocateOutputBufferForWorker(outputShape, 0);

  commandPort.listen((dynamic message) {
    if (message is! Map) {
      return;
    }

    final id = message['id'];
    final type = message['type'];

    if (type == 'dispose') {
      commandPort.close();
      Isolate.exit();
    }

    if (id is! int || type != 'detect') {
      return;
    }

    try {
      final frameData = (message['frame'] as TransferableTypedData).materialize().asUint8List();
      final srcWidth = message['srcWidth'] as int;
      final srcHeight = message['srcHeight'] as int;

      final input = _buildInputTensorInIsolate(
        _PreprocessRequest(
          yPlane: frameData,
          srcWidth: srcWidth,
          srcHeight: srcHeight,
          inputWidth: inputWidth,
          inputHeight: inputHeight,
          inputChannels: inputChannels,
        ),
      );

      _resetOutputBufferForWorker(outputBuffer);
      interpreter.run(input, outputBuffer);

      final result = _extractBestDetectionForWorker(
        outputBuffer,
        outputShape,
        inputWidth,
        inputHeight,
        minDetectionConfidence,
      );
      mainSendPort.send({'id': id, 'result': result});
    } catch (e) {
      mainSendPort.send({'id': id, 'error': e.toString()});
    }
  });
}

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

  static const double _minDetectionConfidence = 0.10;

  final String modelAssetPath;

  bool _isInitialized = false;
  bool _isModelAssetFound = false;
  Interpreter? _interpreter;

  int _inputHeight = 640;
  int _inputWidth = 640;
  int _inputChannels = 3;
  List<int> _outputShape = const [1, 1];
  bool _hasLoggedInferenceError = false;
  bool _isRunningInference = false;
  Isolate? _inferenceIsolate;
  ReceivePort? _inferenceReceivePort;
  SendPort? _inferenceSendPort;
  StreamSubscription<dynamic>? _inferenceSubscription;
  final Map<int, Completer<Map<String, dynamic>?>> _pendingRequests =
      <int, Completer<Map<String, dynamic>?>>{};
  int _nextRequestId = 0;
  Completer<void>? _workerReadyCompleter;

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

      await _startInferenceWorker();

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

  Future<void> _startInferenceWorker() async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      return;
    }

    _inferenceReceivePort = ReceivePort();
    _workerReadyCompleter = Completer<void>();

    _inferenceSubscription = _inferenceReceivePort!.listen((dynamic message) {
      if (message is SendPort) {
        _inferenceSendPort = message;
        if (!(_workerReadyCompleter?.isCompleted ?? true)) {
          _workerReadyCompleter!.complete();
        }
        return;
      }

      if (message is! Map) {
        return;
      }

      final id = message['id'];
      if (id is! int) {
        return;
      }

      final completer = _pendingRequests.remove(id);
      if (completer == null || completer.isCompleted) {
        return;
      }

      final error = message['error'];
      if (error != null) {
        completer.completeError(StateError(error.toString()));
        return;
      }

      final result = message['result'];
      completer.complete(result is Map<String, dynamic> ? result : null);
    });

    _inferenceIsolate = await Isolate.spawn(
      _inferenceWorkerMain,
      {
        'mainSendPort': _inferenceReceivePort!.sendPort,
        'interpreterAddress': interpreter.address,
        'inputWidth': _inputWidth,
        'inputHeight': _inputHeight,
        'inputChannels': _inputChannels,
        'minDetectionConfidence': _minDetectionConfidence,
      },
    );

    await _workerReadyCompleter!.future.timeout(const Duration(seconds: 2));
  }

  Future<List<DetectionResult>> detect(CameraImage image) async {
    return detectFromLuma(image.planes.first.bytes, image.width, image.height);
  }

  Future<List<DetectionResult>> detectFromLuma(
    Uint8List yPlane,
    int srcWidth,
    int srcHeight,
  ) async {
    final sendPort = _inferenceSendPort;
    if (!_isInitialized || !_isModelAssetFound || sendPort == null || _isRunningInference) {
      return const [];
    }

    _isRunningInference = true;

    try {
      final requestId = ++_nextRequestId;
      final completer = Completer<Map<String, dynamic>?>();
      _pendingRequests[requestId] = completer;

      sendPort.send({
        'id': requestId,
        'type': 'detect',
        'frame': TransferableTypedData.fromList([yPlane]),
        'srcWidth': srcWidth,
        'srcHeight': srcHeight,
      });

      final payload = await completer.future;
      _hasLoggedInferenceError = false;

      if (payload == null) {
        return const [];
      }

      final confidence = (payload['confidence'] as num?)?.toDouble() ?? 0.0;
      if (confidence < _minDetectionConfidence) {
        return const [];
      }

      final left = (payload['left'] as num?)?.toDouble() ?? 0.0;
      final top = (payload['top'] as num?)?.toDouble() ?? 0.0;
      final right = (payload['right'] as num?)?.toDouble() ?? 0.0;
      final bottom = (payload['bottom'] as num?)?.toDouble() ?? 0.0;

      return [
        DetectionResult(
          label: (payload['label'] as String?) ?? 'unknown',
          confidence: confidence,
          boundingBox: Rect.fromLTRB(left, top, right, bottom),
          detectedAt: DateTime.now(),
        ),
      ];
    } catch (e) {
      if (!_hasLoggedInferenceError) {
        debugPrint('Inference error: $e');
        _hasLoggedInferenceError = true;
      }
      return const [];
    } finally {
      _isRunningInference = false;
    }
  }

  Future<void> dispose() async {
    if (_inferenceSendPort != null) {
      _inferenceSendPort!.send({'type': 'dispose'});
    }

    for (final entry in _pendingRequests.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError(StateError('Detector disposed'));
      }
    }
    _pendingRequests.clear();

    await _inferenceSubscription?.cancel();
    _inferenceReceivePort?.close();
    _inferenceReceivePort = null;
    _inferenceSendPort = null;

    _inferenceIsolate?.kill(priority: Isolate.immediate);
    _inferenceIsolate = null;

    _interpreter?.close();
    _interpreter = null;
  }
}
