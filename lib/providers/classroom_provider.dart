import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ClassroomConnectionStatus {
  connected,
  reconnecting,
  disconnected,
  error,
}

class ClassroomSessionState {
  final bool isMuted;
  final bool isVideoOn;
  final bool isScreenSharing;
  final bool isRecording;
  final int recordingSeconds;
  final ClassroomConnectionStatus connectionStatus;
  final String? errorMessage;

  const ClassroomSessionState({
    this.isMuted = false,
    this.isVideoOn = true,
    this.isScreenSharing = false,
    this.isRecording = true,
    this.recordingSeconds = 0,
    this.connectionStatus = ClassroomConnectionStatus.connected,
    this.errorMessage,
  });

  ClassroomSessionState copyWith({
    bool? isMuted,
    bool? isVideoOn,
    bool? isScreenSharing,
    bool? isRecording,
    int? recordingSeconds,
    ClassroomConnectionStatus? connectionStatus,
    String? errorMessage,
  }) {
    return ClassroomSessionState(
      isMuted: isMuted ?? this.isMuted,
      isVideoOn: isVideoOn ?? this.isVideoOn,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isRecording: isRecording ?? this.isRecording,
      recordingSeconds: recordingSeconds ?? this.recordingSeconds,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ClassroomSessionNotifier extends StateNotifier<ClassroomSessionState> {
  Timer? _recordingTimer;

  ClassroomSessionNotifier() : super(const ClassroomSessionState()) {
    _startRecordingTimer();
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isRecording) {
        state = state.copyWith(recordingSeconds: state.recordingSeconds + 1);
      }
    });
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void toggleVideo() {
    state = state.copyWith(isVideoOn: !state.isVideoOn);
  }

  void toggleScreenShare() {
    state = state.copyWith(isScreenSharing: !state.isScreenSharing);
  }

  void stopRecording() {
    state = state.copyWith(isRecording: false);
  }

  void simulateNetworkDrop() {
    state = state.copyWith(
      connectionStatus: ClassroomConnectionStatus.reconnecting,
      errorMessage: 'Network connection dropped. Attempting reconnection...',
    );

    Timer(const Duration(seconds: 3), () {
      state = state.copyWith(
        connectionStatus: ClassroomConnectionStatus.connected,
        errorMessage: null,
      );
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
}

final classroomSessionProvider =
    StateNotifierProvider.autoDispose<ClassroomSessionNotifier, ClassroomSessionState>((ref) {
  return ClassroomSessionNotifier();
});
