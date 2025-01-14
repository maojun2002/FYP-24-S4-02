import 'dart:async';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class OTPGenerator {
  String _currentOtp = ''; // Stores the current OTP
  int _remainingSeconds = 60; // Countdown timer for OTP expiration
  Timer? _timer; // Timer for OTP expiration
  final _otpStreamController = StreamController<String>.broadcast(); // Stream for OTP updates
  final _countdownStreamController = StreamController<int>.broadcast(); // Stream for countdown updates

  /// Stream for the generated OTP
  Stream<String> get otpStream => _otpStreamController.stream;

  /// Stream for the countdown timer
  Stream<int> get countdownStream => _countdownStreamController.stream;

  /// Initializes and generates the first OTP
  OTPGenerator() {
    _generateAndStart();
  }

  /// Generates a new OTP and starts/restarts the timer
  Future<void> _generateAndStart() async {
    try {
      _currentOtp = await _generateOTP();
      _remainingSeconds = 60; // Reset the timer to 60 seconds
      _otpStreamController.add(_currentOtp); // Notify listeners of the new OTP
      _startCountdown(); // Start the countdown timer
    } catch (e) {
      _otpStreamController.addError('Error generating OTP: ${e.toString()}');
    }
  }

  /// Generates a 6-digit OTP using device ID, time zone, and current timestamp
  Future<String> _generateOTP() async {
    final deviceId = await _getDeviceId();
    final timeZoneOffset = DateTime.now().timeZoneOffset.inMinutes;
    final currentTimeInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Current time in seconds
    final seed = _generateSeed(deviceId, timeZoneOffset, currentTimeInSeconds);
    return _generateSixDigitOTP(seed);
  }

  /// Retrieves the unique device ID
  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (await _isAndroid()) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id ?? "UnknownAndroidID";
      } else if (await _isIOS()) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? "UnknownIOSID";
      }
    } catch (e) {
      throw PlatformException(
        code: "DEVICE_ID_ERROR",
        message: "Failed to retrieve device ID",
        details: e.toString(),
      );
    }
    throw PlatformException(
        code: "UNSUPPORTED_PLATFORM", message: "This platform is not supported.");
  }

  /// Checks if the platform is Android
  Future<bool> _isAndroid() async {
    try {
      return await DeviceInfoPlugin().androidInfo != null;
    } catch (_) {
      return false;
    }
  }

  /// Checks if the platform is iOS
  Future<bool> _isIOS() async {
    try {
      return await DeviceInfoPlugin().iosInfo != null;
    } catch (_) {
      return false;
    }
  }

  /// Generates a seed based on device ID, time zone offset, and current timestamp
  int _generateSeed(String deviceId, int timeZoneOffset, int currentTimeInSeconds) {
    return (deviceId.hashCode ^ timeZoneOffset.hashCode ^ currentTimeInSeconds).abs();
  }

  /// Generates a 6-digit OTP based on a seed
  String _generateSixDigitOTP(int seed) {
    final random = Random(seed);
    return (random.nextInt(900000) + 100000).toString(); // Ensures a 6-digit number
  }

  /// Starts or restarts the countdown timer
  void _startCountdown() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _countdownStreamController.add(_remainingSeconds); // Notify listeners
      } else {
        timer.cancel(); // Stop the current timer
        _generateAndStart(); // Generate a new OTP
      }
    });
  }

  /// Cleans up resources when no longer needed
  void dispose() {
    _timer?.cancel();
    _otpStreamController.close();
    _countdownStreamController.close();
  }
}
