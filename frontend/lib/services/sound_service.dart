import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static const MethodChannel _channel = MethodChannel('healthcare_app/sound');
  
  // Play notification sound
  static Future<void> playNotificationSound() async {
    try {
      if (kIsWeb) {
        // For web, we can use HTML5 audio or just system feedback
        await HapticFeedback.lightImpact();
        return;
      }
      
      // For mobile platforms, we would use platform-specific sound APIs
      await _channel.invokeMethod('playNotificationSound');
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
      // Fallback to haptic feedback
      await HapticFeedback.lightImpact();
    }
  }
  
  // Vibrate device
  static Future<void> vibrate({int duration = 200}) async {
    try {
      if (kIsWeb) {
        // Web doesn't support vibration in most browsers
        return;
      }
      
      await _channel.invokeMethod('vibrate', {'duration': duration});
    } catch (e) {
      debugPrint('Error vibrating device: $e');
      // Fallback to haptic feedback
      await HapticFeedback.mediumImpact();
    }
  }
  
  // Play sound with haptic feedback
  static Future<void> playNotificationAlert() async {
    await Future.wait([
      playNotificationSound(),
      vibrate(duration: 100),
    ]);
  }
  
  // Different alert types
  static Future<void> playUrgentAlert() async {
    await HapticFeedback.heavyImpact();
    await vibrate(duration: 300);
  }
  
  static Future<void> playInfoAlert() async {
    await HapticFeedback.lightImpact();
  }
  
  static Future<void> playSuccessAlert() async {
    await HapticFeedback.selectionClick();
  }
}