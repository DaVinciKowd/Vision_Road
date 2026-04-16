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
    this.uPlane,
    this.vPlane,
    required this.srcWidth,
    required this.srcHeight,
    required this.inputWidth,
    required this.inputHeight,
    required this.inputChannels,
    this.uRowStride,
    this.vRowStride,
    this.uvPixelStride,
    this.quantizeInput = false,
    this.inputScale = 1.0,
    this.inputZeroPoint = 0,
    this.inputMinValue = 0,
    this.inputMaxValue = 255,
  });

  final Uint8List yPlane;
  final Uint8List? uPlane;
  final Uint8List? vPlane;
  final int srcWidth;
  final int srcHeight;
  final int inputWidth;
  final int inputHeight;
  final int inputChannels;
  final int? uRowStride;
  final int? vRowStride;
  final int? uvPixelStride;
  final bool quantizeInput;
  final double inputScale;
  final int inputZeroPoint;
  final int inputMinValue;
  final int inputMaxValue;
}

dynamic _buildInputTensorInIsolate(_PreprocessRequest request) {
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
      final yValue = request.yPlane[srcY * request.srcWidth + srcX].toDouble();

      final hasChroma = request.uPlane != null &&
          request.vPlane != null &&
          request.uRowStride != null &&
          request.vRowStride != null &&
          request.uvPixelStride != null;

      if (!hasChroma) {
        final luminance = yValue / 255.0;
        if (request.inputChannels == 1) {
          input[0][y][x][0] = luminance;
        } else {
          for (int c = 0; c < request.inputChannels; c++) {
            input[0][y][x][c] = luminance;
          }
        }
      } else {
        final uvX = srcX ~/ 2;
        final uvY = srcY ~/ 2;
        final uIndex = uvY * request.uRowStride! + uvX * request.uvPixelStride!;
        final vIndex = uvY * request.vRowStride! + uvX * request.uvPixelStride!;

        final u = request.uPlane![uIndex].toDouble() - 128.0;
        final v = request.vPlane![vIndex].toDouble() - 128.0;

        final r = (yValue + 1.402 * v).clamp(0.0, 255.0) / 255.0;
        final g = (yValue - 0.344136 * u - 0.714136 * v).clamp(0.0, 255.0) / 255.0;
        final b = (yValue + 1.772 * u).clamp(0.0, 255.0) / 255.0;

        if (request.inputChannels == 1) {
          input[0][y][x][0] = (0.299 * r + 0.587 * g + 0.114 * b);
        } else if (request.inputChannels >= 3) {
          input[0][y][x][0] = r;
          input[0][y][x][1] = g;
          input[0][y][x][2] = b;
          for (int c = 3; c < request.inputChannels; c++) {
            input[0][y][x][c] = r;
          }
        } else {
          input[0][y][x][0] = r;
        }
      }
    }
  }

  if (!request.quantizeInput || request.inputScale <= 0) {
    return input;
  }

  return _quantizeInputTensor(
    input,
    request.inputScale,
    request.inputZeroPoint,
    request.inputMinValue,
    request.inputMaxValue,
  );
}

dynamic _quantizeInputTensor(
  dynamic buffer,
  double scale,
  int zeroPoint,
  int minValue,
  int maxValue,
) {
  if (buffer is List) {
    return buffer
        .map((child) => _quantizeInputTensor(child, scale, zeroPoint, minValue, maxValue))
        .toList();
  }

  if (buffer is num) {
    final quantized = (buffer.toDouble() / scale + zeroPoint).round();
    return quantized.clamp(minValue, maxValue);
  }

  return buffer;
}

dynamic _allocateOutputBufferForWorker(
  List<int> shape,
  int depth, {
  required bool useIntBuffer,
}) {
  final dim = shape[depth];
  if (depth == shape.length - 1) {
    return useIntBuffer ? List<int>.filled(dim, 0) : List<double>.filled(dim, 0.0);
  }
  return List.generate(
    dim,
    (_) => _allocateOutputBufferForWorker(shape, depth + 1, useIntBuffer: useIntBuffer),
  );
}

void _resetOutputBufferForWorker(dynamic buffer) {
  if (buffer is List<double>) {
    for (int i = 0; i < buffer.length; i++) {
      buffer[i] = 0.0;
    }
    return;
  }

  if (buffer is List<int>) {
    for (int i = 0; i < buffer.length; i++) {
      buffer[i] = 0;
    }
    return;
  }

  if (buffer is List) {
    for (final child in buffer) {
      _resetOutputBufferForWorker(child);
    }
  }
}

dynamic _dequantizeOutputBuffer(dynamic buffer, double scale, int zeroPoint) {
  if (buffer is List) {
    return buffer
        .map((child) => _dequantizeOutputBuffer(child, scale, zeroPoint))
        .toList();
  }

  if (buffer is num) {
    return (buffer.toDouble() - zeroPoint) * scale;
  }

  return 0.0;
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
  if (width < 2 || height < 2) {
    return false;
  }

  final minArea = inputWidth * inputHeight * 0.00001;
  return width * height >= minArea;
}

String _labelForClassIndex(int index, List<String> classLabels) {
  if (index >= 0 && index < classLabels.length) {
    return classLabels[index];
  }
  return 'class_$index';
}

Map<String, dynamic>? _extractBestDetectionForWorker(
  dynamic output,
  List<int> outputShape,
  int inputWidth,
  int inputHeight,
  double minDetectionConfidence,
  List<String> classLabels,
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
      'label': _labelForClassIndex(bestIndex, classLabels),
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
    final classCount = classLabels.length;

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
        if (!_isCandidateBoxValidForWorker(candidateBox, inputWidth, inputHeight)) {
          continue;
        }
        double classScore = 0.0;
        int classIndex = 0;

        if (channels == 4 + classCount) {
          for (int c = 0; c < classCount; c++) {
            final value = ((channelMajor[c + 4] as List)[b] as num).toDouble();
            if (value > classScore) {
              classScore = value;
              classIndex = c;
            }
          }
        } else if (channels == 5 + classCount) {
          final objectness = ((channelMajor[4] as List)[b] as num).toDouble();
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
        } else if (channels > 4) {
          final objectness = ((channelMajor[4] as List)[b] as num).toDouble();
          double maxClassFrom5 = 0.0;
          int maxIndexFrom5 = 0;
          for (int c = 5; c < channels; c++) {
            final value = ((channelMajor[c] as List)[b] as num).toDouble();
            if (value > maxClassFrom5) {
              maxClassFrom5 = value;
              maxIndexFrom5 = c - 5;
            }
          }

          double maxClassFrom4 = 0.0;
          int maxIndexFrom4 = 0;
          for (int c = 4; c < channels; c++) {
            final value = ((channelMajor[c] as List)[b] as num).toDouble();
            if (value > maxClassFrom4) {
              maxClassFrom4 = value;
              maxIndexFrom4 = c - 4;
            }
          }

          final scoreWithObjectness = objectness * maxClassFrom5;
          if (maxClassFrom4 > scoreWithObjectness) {
            classScore = maxClassFrom4;
            classIndex = maxIndexFrom4;
          } else {
            classScore = scoreWithObjectness;
            classIndex = maxIndexFrom5;
          }
        } else {
          classIndex = 0;
          classScore = ((channelMajor[0] as List)[b] as num).toDouble();
        }

        if (classScore > bestConfidence) {
          bestConfidence = classScore;
          bestClass = classIndex;
          bestBox = candidateBox;
        }
      }

      if (bestConfidence < minDetectionConfidence) {
        return null;
      }

      return {
        'label': _labelForClassIndex(bestClass, classLabels),
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
      if (!_isCandidateBoxValidForWorker(candidateBox, inputWidth, inputHeight)) {
        continue;
      }
      double classScore = 0.0;
      int classIndex = 0;

      if (channels == 4 + classCount) {
        for (int c = 0; c < classCount; c++) {
          final value = (row[c + 4] as num).toDouble();
          if (value > classScore) {
            classScore = value;
            classIndex = c;
          }
        }
      } else if (channels == 5 + classCount) {
        final objectness = (row[4] as num).toDouble();
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
      } else if (channels > 4) {
        final objectness = (row[4] as num).toDouble();
        double maxClassFrom5 = 0.0;
        int maxIndexFrom5 = 0;
        for (int c = 5; c < channels; c++) {
          final value = (row[c] as num).toDouble();
          if (value > maxClassFrom5) {
            maxClassFrom5 = value;
            maxIndexFrom5 = c - 5;
          }
        }

        double maxClassFrom4 = 0.0;
        int maxIndexFrom4 = 0;
        for (int c = 4; c < channels; c++) {
          final value = (row[c] as num).toDouble();
          if (value > maxClassFrom4) {
            maxClassFrom4 = value;
            maxIndexFrom4 = c - 4;
          }
        }

        final scoreWithObjectness = objectness * maxClassFrom5;
        if (maxClassFrom4 > scoreWithObjectness) {
          classScore = maxClassFrom4;
          classIndex = maxIndexFrom4;
        } else {
          classScore = scoreWithObjectness;
          classIndex = maxIndexFrom5;
        }
      } else {
        classIndex = 0;
        classScore = (row[0] as num).toDouble();
      }

      if (classScore > bestConfidence) {
        bestConfidence = classScore;
        bestClass = classIndex;
        bestBox = candidateBox;
      }
    }

    if (bestConfidence < minDetectionConfidence) {
      return null;
    }

    return {
      'label': _labelForClassIndex(bestClass, classLabels),
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
  final classLabels = (initMessage['classLabels'] as List).cast<String>();

  final commandPort = ReceivePort();
  mainSendPort.send(commandPort.sendPort);

  final interpreter = Interpreter.fromAddress(interpreterAddress);
  final inputTensor = interpreter.getInputTensor(0);
  final outputTensor = interpreter.getOutputTensor(0);
  final inputType = inputTensor.type.toString().toLowerCase();
  final outputType = outputTensor.type.toString().toLowerCase();

  double inputScale = 1.0;
  int inputZeroPoint = 0;
  try {
    final params = (inputTensor as dynamic).params;
    inputScale = (params.scale as num?)?.toDouble() ?? inputScale;
    inputZeroPoint = (params.zeroPoint as num?)?.toInt() ?? inputZeroPoint;
  } catch (_) {}

  double outputScale = 1.0;
  int outputZeroPoint = 0;
  try {
    final params = (outputTensor as dynamic).params;
    outputScale = (params.scale as num?)?.toDouble() ?? outputScale;
    outputZeroPoint = (params.zeroPoint as num?)?.toInt() ?? outputZeroPoint;
  } catch (_) {}

  final inputIsQuantized = !inputType.contains('float');
  final inputIsSigned = inputType.contains('int8') && !inputType.contains('uint8');
  final outputIsQuantized = !outputType.contains('float') && outputScale > 0;

  final outputShape = interpreter.getOutputTensor(0).shape;
  final outputBuffer = _allocateOutputBufferForWorker(
    outputShape,
    0,
    useIntBuffer: outputIsQuantized,
  );

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
      final frameY = (message['frameY'] as TransferableTypedData).materialize().asUint8List();
      final srcWidth = message['srcWidth'] as int;
      final srcHeight = message['srcHeight'] as int;

      final frameUData = message['frameU'];
      final frameVData = message['frameV'];
      final frameU = frameUData is TransferableTypedData
          ? frameUData.materialize().asUint8List()
          : null;
      final frameV = frameVData is TransferableTypedData
          ? frameVData.materialize().asUint8List()
          : null;
      final uRowStride = message['uRowStride'] as int?;
      final vRowStride = message['vRowStride'] as int?;
      final uvPixelStride = message['uvPixelStride'] as int?;

      final input = _buildInputTensorInIsolate(
        _PreprocessRequest(
          yPlane: frameY,
          uPlane: frameU,
          vPlane: frameV,
          srcWidth: srcWidth,
          srcHeight: srcHeight,
          inputWidth: inputWidth,
          inputHeight: inputHeight,
          inputChannels: inputChannels,
          uRowStride: uRowStride,
          vRowStride: vRowStride,
          uvPixelStride: uvPixelStride,
          quantizeInput: inputIsQuantized && inputScale > 0,
          inputScale: inputScale,
          inputZeroPoint: inputZeroPoint,
          inputMinValue: inputIsSigned ? -128 : 0,
          inputMaxValue: inputIsSigned ? 127 : 255,
        ),
      );

      _resetOutputBufferForWorker(outputBuffer);
      interpreter.run(input, outputBuffer);

      final parsedOutput = outputIsQuantized
          ? _dequantizeOutputBuffer(outputBuffer, outputScale, outputZeroPoint)
          : outputBuffer;

      final result = _extractBestDetectionForWorker(
        parsedOutput,
        outputShape,
        inputWidth,
        inputHeight,
        minDetectionConfidence,
        classLabels,
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
  static const List<String> _classLabels = <String>[
    '0_Longitudinal_Crack',
    '1_Transverse_Crack',
    '2_Alligator_Crack',
    '3_Pothole',
    '4_Uneven_Terrain',
    '5_Debris',
  ];

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

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      debugPrint(
        'TFLite tensors: input=${inputTensor.shape} ${inputTensor.type}, output=${outputTensor.shape} ${outputTensor.type}',
      );

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
        'classLabels': _classLabels,
      },
    );

    await _workerReadyCompleter!.future.timeout(const Duration(seconds: 2));
  }

  Future<List<DetectionResult>> detect(CameraImage image) async {
    return detectFromLuma(image.planes.first.bytes, image.width, image.height);
  }

  Future<Map<String, dynamic>?> _sendDetectionRequest(Map<String, dynamic> message) async {
    final sendPort = _inferenceSendPort;
    if (!_isInitialized) {
      debugPrint('[PT_DETECTOR] ⚠️ Detector not initialized yet');
      return null;
    }
    if (!_isModelAssetFound) {
      debugPrint('[PT_DETECTOR] ❌ Model asset not found');
      return null;
    }
    if (sendPort == null) {
      debugPrint('[PT_DETECTOR] ❌ Inference worker not ready (sendPort null)');
      return null;
    }
    if (_isRunningInference) {
      debugPrint('[PT_DETECTOR] ⏳ Previous frame still processing, skipping frame');
      return null;
    }

    _isRunningInference = true;

    try {
      final requestId = ++_nextRequestId;
      final completer = Completer<Map<String, dynamic>?>();
      _pendingRequests[requestId] = completer;

      sendPort.send({'id': requestId, 'type': 'detect', ...message});

      final payload = await completer.future;
      _hasLoggedInferenceError = false;
      return payload;
    } catch (e) {
      if (!_hasLoggedInferenceError) {
        debugPrint('Inference error: $e');
        _hasLoggedInferenceError = true;
      }
      return null;
    } finally {
      _isRunningInference = false;
    }
  }

  Future<List<DetectionResult>> detectFromYuv420(
    Uint8List yPlane,
    Uint8List uPlane,
    Uint8List vPlane,
    int srcWidth,
    int srcHeight,
    int uRowStride,
    int vRowStride,
    int uvPixelStride,
  ) async {
    final payload = await _sendDetectionRequest({
      'frameY': TransferableTypedData.fromList([yPlane]),
      'frameU': TransferableTypedData.fromList([uPlane]),
      'frameV': TransferableTypedData.fromList([vPlane]),
      'srcWidth': srcWidth,
      'srcHeight': srcHeight,
      'uRowStride': uRowStride,
      'vRowStride': vRowStride,
      'uvPixelStride': uvPixelStride,
    });

    if (payload == null) {
      return const [];
    }

    return _payloadToDetectionList(payload);
  }

  Future<List<DetectionResult>> detectFromLuma(
    Uint8List yPlane,
    int srcWidth,
    int srcHeight,
  ) async {
    final payload = await _sendDetectionRequest({
      'frameY': TransferableTypedData.fromList([yPlane]),
      'srcWidth': srcWidth,
      'srcHeight': srcHeight,
    });

    if (payload == null) {
      return const [];
    }

    return _payloadToDetectionList(payload);
  }

  List<DetectionResult> _payloadToDetectionList(Map<String, dynamic> payload) {
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
