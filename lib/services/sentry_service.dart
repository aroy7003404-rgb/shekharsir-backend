import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SentryService {
  static Future<void> init({required VoidCallback appRunner}) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      captureException(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      captureException(error, stack);
      return true;
    };

    appRunner();
  }

  static void captureException(dynamic exception, StackTrace? stackTrace) {
    debugPrint('Sentry Exception Captured: $exception');
  }

  static void captureMessage(String message) {
    debugPrint('Sentry Message Captured: $message');
  }
}
