import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class CollisionTriggerData {
  final double maxAccelG;
  final double maxGyro;
  final double accelThresholdG;
  final double gyroThreshold;
  final double latestAccelAfterDelayG;

  CollisionTriggerData({
    required this.maxAccelG,
    required this.maxGyro,
    required this.accelThresholdG,
    required this.gyroThreshold,
    required this.latestAccelAfterDelayG,
  });
}

class CollisionDetectionService {
  StreamSubscription<UserAccelerometerEvent>?
      _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>?
      _gyroscopeSubscription;

  bool _isCooldownActive = false;
  bool _isPotentialCollisionDetected = false;

  /// Buffers (time-windowed sensor data)
  final List<_SensorSample> _accelBuffer = [];
  final List<_SensorSample> _gyroBuffer = [];

  /// THRESHOLDS (adjustable for testing)
  /// You should calibrate these after real-world testing
  static const double accelThreshold = 5.0; // in g
  static const double gyroThreshold = 0.3;

  /// Inactivity threshold after impact
  /// Lower movement after collision helps confirm accident
  static const double inactivityThreshold = 1.0; // in g

  /// Cooldown duration
  static const int cooldownSeconds = 10;

  /// Time window for buffers
  static const int bufferWindowMilliseconds = 1000;

  /// Delay before checking inactivity
  static const int inactivityCheckDelaySeconds = 3;

  /// Callback when collision is confirmed
  Function(CollisionTriggerData)? _onCollisionDetected;

  /// Stores the values that originally triggered the possible collision
  double _lastTriggeredMaxAccelG = 0.0;
  double _lastTriggeredMaxGyro = 0.0;

  /// START LISTENING
  void startListening(
    Function(CollisionTriggerData) onCollisionDetected,
  ) {
    _onCollisionDetected = onCollisionDetected;

    /// Using userAccelerometerEvents so gravity is removed
    _accelerometerSubscription =
        userAccelerometerEvents.listen((event) {
      final alaMs2 = sqrt(
        event.x * event.x +
            event.y * event.y +
            event.z * event.z,
      );

      final alaG = alaMs2 / 9.80665;

      if (DateTime.now().millisecond % 500 < 50) {
        print("ALA (m/s²): $alaMs2 | ALA (g): $alaG");
      }

      _accelBuffer.add(
        _SensorSample(
          DateTime.now(),
          alaG,
        ),
      );

      _cleanupOldData();

      _checkCollision();
    });

    _gyroscopeSubscription =
        gyroscopeEvents.listen((event) {
      final value = sqrt(
        event.x * event.x +
            event.y * event.y +
            event.z * event.z,
      );

      _gyroBuffer.add(
        _SensorSample(
          DateTime.now(),
          value,
        ),
      );

      _cleanupOldData();

      _checkCollision();
    });

    print(
      "Collision detection started.",
    );
  }

  /// REMOVE OLD SENSOR DATA
  /// Keeps only recent values inside sliding window
  void _cleanupOldData() {
    final now = DateTime.now();

    _accelBuffer.removeWhere(
      (sample) =>
          now
              .difference(sample.time)
              .inMilliseconds >
          bufferWindowMilliseconds,
    );

    _gyroBuffer.removeWhere(
      (sample) =>
          now
              .difference(sample.time)
              .inMilliseconds >
          bufferWindowMilliseconds,
    );
  }

  /// MAIN COLLISION CHECK
  void _checkCollision() {
    if (_isCooldownActive) return;

    if (_isPotentialCollisionDetected) return;

    if (_accelBuffer.isEmpty ||
        _gyroBuffer.isEmpty) {
      return;
    }

    final double maxAccelG =
        _accelBuffer
            .map((e) => e.value)
            .reduce(max);

    final double maxGyro =
        _gyroBuffer
            .map((e) => e.value)
            .reduce(max);

    final bool strongImpact =
        maxAccelG > accelThreshold;

    final bool abnormalRotation =
        maxGyro > gyroThreshold;

    print("---- COLLISION DEBUG ----");
    print(
      "maxAccel: $maxAccelG g (threshold: $accelThreshold g)",
    );
    print(
      "maxGyro: $maxGyro (threshold: $gyroThreshold)",
    );
    print(
      "strongImpact: $strongImpact",
    );
    print(
      "abnormalRotation: $abnormalRotation",
    );
    print(
      "Condition Result: ${strongImpact && abnormalRotation}",
    );
    print("-------------------------");

    /// Require BOTH conditions
    if (strongImpact &&
        abnormalRotation) {
      print(
        "🚨 Possible Collision Detected",
      );

      /// Save the values that triggered the detection
      _lastTriggeredMaxAccelG = maxAccelG;
      _lastTriggeredMaxGyro = maxGyro;

      _isPotentialCollisionDetected = true;

      _checkInactivityAfterImpact();
    }
  }

  /// STEP 2:
  /// Confirm collision by checking inactivity
  /// after impact + abnormal rotation
  void _checkInactivityAfterImpact() {
    print(
      "Checking inactivity after impact...",
    );

    Future.delayed(
      const Duration(
        seconds: inactivityCheckDelaySeconds,
      ),
      () {
        if (_accelBuffer.isEmpty) {
          _isPotentialCollisionDetected =
              false;
          return;
        }

        final latestAccel =
            _accelBuffer.last.value;

        final bool inactivityDetected =
            latestAccel <
                inactivityThreshold;

        print(
          "Latest Acceleration After Delay: $latestAccel g",
        );
        print(
          "Inactivity Detected: $inactivityDetected",
        );

        if (inactivityDetected) {
          print(
            "✅ Collision Confirmed",
          );

          _triggerCollision(latestAccel);
        } else {
          print(
            "❌ False Positive Ignored",
          );

          _isPotentialCollisionDetected =
              false;
        }
      },
    );
  }

  /// FINAL TRIGGER
  /// Calls your emergency dialog / SMS workflow
  void _triggerCollision(double latestAccelAfterDelayG) {
    _isCooldownActive = true;
    _isPotentialCollisionDetected =
        false;

    _onCollisionDetected?.call(
      CollisionTriggerData(
        maxAccelG: _lastTriggeredMaxAccelG,
        maxGyro: _lastTriggeredMaxGyro,
        accelThresholdG: accelThreshold,
        gyroThreshold: gyroThreshold,
        latestAccelAfterDelayG:
            latestAccelAfterDelayG,
      ),
    );

    print(
      "Cooldown started ($cooldownSeconds seconds)",
    );

    Future.delayed(
      const Duration(
        seconds: cooldownSeconds,
      ),
      () {
        _isCooldownActive = false;

        print(
          "Cooldown ended. Detection active again.",
        );
      },
    );
  }

  /// MANUAL TEST FUNCTION
  /// Use for simulator testing
  void simulateCollision() {
    print(
      "🧪 SIMULATING COLLISION...",
    );

    _accelBuffer.add(
      _SensorSample(
        DateTime.now(),
        6.0,
      ),
    );

    _gyroBuffer.add(
      _SensorSample(
        DateTime.now(),
        4.0,
      ),
    );

    _checkCollision();
  }

  /// STOP LISTENING
  void stopListening() {
    _accelerometerSubscription
        ?.cancel();

    _gyroscopeSubscription
        ?.cancel();

    print(
      "Collision detection stopped.",
    );
  }
}

/// SENSOR DATA MODEL
class _SensorSample {
  final DateTime time;
  final double value;

  _SensorSample(
    this.time,
    this.value,
  );
}