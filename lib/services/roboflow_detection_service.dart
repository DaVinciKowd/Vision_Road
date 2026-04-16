import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../ml/pt_model_detector.dart';

const int _roboflowUploadSize = 416;

Uint8List _buildRoboflowUploadFrame(Map<String, Object?> args) {
  final yPlane = args['yPlane'] as Uint8List;
  final uPlane = args['uPlane'] as Uint8List;
  final vPlane = args['vPlane'] as Uint8List;
  final srcWidth = args['srcWidth'] as int;
  final srcHeight = args['srcHeight'] as int;
  final targetWidth = args['targetWidth'] as int;
  final targetHeight = args['targetHeight'] as int;
  final uRowStride = args['uRowStride'] as int;
  final vRowStride = args['vRowStride'] as int;
  final uvPixelStride = args['uvPixelStride'] as int;

  final image = img.Image(width: targetWidth, height: targetHeight);

  for (int y = 0; y < targetHeight; y++) {
    final srcY = (y * srcHeight / targetHeight).floor().clamp(0, srcHeight - 1);
    final uvY = srcY ~/ 2;
    for (int x = 0; x < targetWidth; x++) {
      final srcX = (x * srcWidth / targetWidth).floor().clamp(0, srcWidth - 1);
      final uvX = srcX ~/ 2;

      final yValue = yPlane[srcY * srcWidth + srcX].toDouble();
      final uIndex = uvY * uRowStride + uvX * uvPixelStride;
      final vIndex = uvY * vRowStride + uvX * uvPixelStride;

      final u = uPlane[uIndex].toDouble() - 128.0;
      final v = vPlane[vIndex].toDouble() - 128.0;

      final r = (yValue + 1.402 * v).clamp(0.0, 255.0).toInt();
      final g =
          (yValue - 0.344136 * u - 0.714136 * v).clamp(0.0, 255.0).toInt();
      final b = (yValue + 1.772 * u).clamp(0.0, 255.0).toInt();

      image.setPixelRgb(x, y, r, g, b);
    }
  }

  return Uint8List.fromList(img.encodeJpg(image, quality: 75));
}

class RoboflowDetectionService {
  static const double _minApiConfidence = 0.10;
  // Replace these with your actual Roboflow credentials/config.
  static const String _apiKeyValue = 'leoEVvrG3QpCkiyGV9Pw';
  static const String _modelIdValue = 'vision_road';
  static const String _modelVersionValue = '2';

  RoboflowDetectionService({String? apiKey, String? modelId, String? version})
    : _configuredApiKey = _pickConfiguredValue(apiKey, _apiKeyValue),
      _configuredModelId = _pickConfiguredValue(modelId, _modelIdValue),
      _configuredVersion = _pickConfiguredValue(version, _modelVersionValue);

  final String? _configuredApiKey;
  final String? _configuredModelId;
  final String? _configuredVersion;

  bool get isConfigured =>
      _configuredApiKey != null &&
      _configuredModelId != null &&
      _configuredVersion != null;

  Future<List<DetectionResult>> detectFromYuv420({
    required Uint8List yPlane,
    required Uint8List uPlane,
    required Uint8List vPlane,
    required int srcWidth,
    required int srcHeight,
    required int uRowStride,
    required int vRowStride,
    required int uvPixelStride,
  }) async {
    if (!isConfigured) {
      final missing = <String>[];
      if (_configuredApiKey == null) missing.add('apiKey');
      if (_configuredModelId == null) missing.add('modelId');
      if (_configuredVersion == null) missing.add('version');
      debugPrint('[ROBOFLOW] ❌ Not configured: ${missing.join(", ")}');
      return const [];
    }

    final apiKey = _configuredApiKey!;
    final modelId = _configuredModelId!;
    final version = _configuredVersion!;

    final jpegBytes =
        await compute(_buildRoboflowUploadFrame, <String, Object?>{
          'yPlane': yPlane,
          'uPlane': uPlane,
          'vPlane': vPlane,
          'srcWidth': srcWidth,
          'srcHeight': srcHeight,
          'targetWidth': _roboflowUploadSize,
          'targetHeight': _roboflowUploadSize,
          'uRowStride': uRowStride,
          'vRowStride': vRowStride,
          'uvPixelStride': uvPixelStride,
        });

    final uri = Uri.parse(
      'https://detect.roboflow.com/$modelId/$version?api_key=$apiKey&format=json&confidence=10&overlap=30',
    );

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes('file', jpegBytes, filename: 'frame.jpg'),
      );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 4),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[ROBOFLOW] HTTP ${response.statusCode}: ${response.body}');
      return const [];
    }

    final parsed = jsonDecode(response.body);
    if (parsed is! Map<String, dynamic>) {
      debugPrint('[ROBOFLOW] Invalid JSON response: ${response.body}');
      return const [];
    }

    final predictions = parsed['predictions'];
    if (predictions is! List || predictions.isEmpty) {
      debugPrint('[ROBOFLOW] No predictions returned');
      return const [];
    }

    Map<String, dynamic>? best;
    double bestConfidence = 0.0;
    for (final item in predictions) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final confidence = (item['confidence'] as num?)?.toDouble() ?? 0.0;
      if (confidence > bestConfidence) {
        bestConfidence = confidence;
        best = item;
      }
    }

    if (best == null) {
      debugPrint('[ROBOFLOW] Unable to find a best prediction');
      return const [];
    }

    if (bestConfidence < _minApiConfidence) {
      debugPrint(
        '[ROBOFLOW] Top confidence ${bestConfidence.toStringAsFixed(3)} below threshold $_minApiConfidence',
      );
      return const [];
    }

    final x = (best['x'] as num?)?.toDouble() ?? 0.0;
    final y = (best['y'] as num?)?.toDouble() ?? 0.0;
    final width = (best['width'] as num?)?.toDouble() ?? 0.0;
    final height = (best['height'] as num?)?.toDouble() ?? 0.0;

    final left = (x - width / 2).clamp(0.0, srcWidth.toDouble());
    final top = (y - height / 2).clamp(0.0, srcHeight.toDouble());
    final right = (left + width).clamp(0.0, srcWidth.toDouble());
    final bottom = (top + height).clamp(0.0, srcHeight.toDouble());

    final label = (best['class'] as String?) ?? 'roboflow_object';

    return [
      DetectionResult(
        label: label,
        confidence: bestConfidence,
        boundingBox: Rect.fromLTRB(left, top, right, bottom),
        detectedAt: DateTime.now(),
      ),
    ];
  }

  static String? _pickConfiguredValue(
    String? runtimeValue,
    String compileTimeValue,
  ) {
    final runtimeTrimmed = runtimeValue?.trim();
    if (runtimeTrimmed != null && runtimeTrimmed.isNotEmpty) {
      return runtimeTrimmed;
    }

    final compileTrimmed = compileTimeValue.trim();
    if (compileTrimmed.isNotEmpty) {
      return compileTrimmed;
    }

    return null;
  }
}
