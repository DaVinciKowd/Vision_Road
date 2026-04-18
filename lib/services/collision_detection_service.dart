import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

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
  static const double accelThreshold = 5.0;
  static const double gyroThreshold = 0.3;

  /// Inactivity threshold after impact
  /// Lower movement after collision helps confirm accident
  static const double inactivityThreshold = 1.0;

  /// Cooldown duration
  static const int cooldownSeconds = 10;

  /// Time window for buffers
  static const int bufferWindowMilliseconds = 1000;

  /// Delay before checking inactivity
  static const int inactivityCheckDelaySeconds = 3;

  /// Callback when collision is confirmed
  Function? _onCollisionDetected;

  /// START LISTENING
  void startListening(Function onCollisionDetected) {
    _onCollisionDetected = onCollisionDetected;

    /// Using userAccelerometerEvents so gravity is removed
    _accelerometerSubscription =
        userAccelerometerEvents.listen((event) {
      final value = sqrt(
        event.x * event.x +
            event.y * event.y +
            event.z * event.z,
      );

      _accelBuffer.add(
        _SensorSample(
          DateTime.now(),
          value,
        ),
      );

      _cleanupOldData();

      /*print(
        "User Acceleration Force: $value",
      );*/

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

      /*print(
        "Gyroscope Rotation: $value",
      );*/

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

    final double maxAccel =
        _accelBuffer
            .map((e) => e.value)
            .reduce(max);

    final double maxGyro =
        _gyroBuffer
            .map((e) => e.value)
            .reduce(max);

    final bool strongImpact =
        maxAccel > accelThreshold;

    final bool abnormalRotation =
        maxGyro > gyroThreshold;

    print("---- COLLISION DEBUG ----");
    print(
      "maxAccel: $maxAccel (threshold: $accelThreshold)",
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
        seconds:
            inactivityCheckDelaySeconds,
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
          "Latest Acceleration After Delay: $latestAccel",
        );
        print(
          "Inactivity Detected: $inactivityDetected",
        );

        if (inactivityDetected) {
          print(
            "✅ Collision Confirmed",
          );

          _triggerCollision();
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
  void _triggerCollision() {
    _isCooldownActive = true;
    _isPotentialCollisionDetected =
        false;

    _onCollisionDetected?.call();

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
        80.0,
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