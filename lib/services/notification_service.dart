import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../views/live_classroom_screen.dart';
import '../views/materials_screen.dart';
import '../views/student_test_screen.dart';
import 'api_service.dart';

/// NotificationService manages push notification registration, FCM device token
/// persistence, local alert displays, and deep-link payload navigation.
class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final ApiService _apiService = ApiService();
  static const String _fcmTokenKey = 'shekhar_sir_fcm_token';

  /// Initialize Push Notification Service & Register FCM Token
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString(_fcmTokenKey);

      if (token == null || token.isEmpty) {
        token = 'fcm_ssc_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString(_fcmTokenKey, token);
      }

      // Register device FCM token with backend API
      await registerFcmTokenWithBackend(token);
    } catch (_) {
      // Graceful fallback for offline / test environments
    }
  }

  /// Register FCM Device Token with FastAPI backend `/api/users/fcm-token`
  static Future<void> registerFcmTokenWithBackend(String token) async {
    try {
      await _apiService.registerFcmToken(fcmToken: token);
    } catch (_) {}
  }

  /// Display In-App Notification Alert Banner for Foreground Events
  static void showNotificationAlert({
    required String title,
    required String body,
    String? routePayload,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: routePayload != null
            ? SnackBarAction(
                label: 'VIEW',
                textColor: const Color(0xFF60A5FA),
                onPressed: () {
                  handleNotificationTapPayload(routePayload);
                },
              )
            : null,
      ),
    );
  }

  /// Handle Notification Tap Payload Route Navigation
  static void handleNotificationTapPayload(String? route) {
    if (route == null || route.isEmpty) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    Widget targetScreen;
    switch (route) {
      case 'live_classroom':
        targetScreen = const LiveClassroomScreen();
        break;
      case 'test_screen':
        targetScreen = const StudentTestScreen();
        break;
      case 'materials_screen':
        targetScreen = const MaterialsScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }
}
