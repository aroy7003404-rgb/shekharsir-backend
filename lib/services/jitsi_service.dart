import 'package:flutter/material.dart';

class JitsiService {
  static Future<void> joinMeeting({
    required String roomName,
    required String subject,
    required String displayName,
    required String email,
  }) async {
    debugPrint('Joining Jitsi Conference Room: $roomName as $displayName ($email)');
  }
}
