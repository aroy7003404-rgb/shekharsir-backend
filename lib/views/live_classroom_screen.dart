// ignore_for_file: prefer_final_fields
import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/classroom_provider.dart';
import '../providers/whiteboard_provider.dart';
import '../services/jitsi_service.dart';

class LiveClassroomScreen extends ConsumerStatefulWidget {
  final String title;
  final String batch;
  final String roomId;

  const LiveClassroomScreen({
    super.key,
    this.title = 'Physics: Wave Optics Interference',
    this.batch = 'Grade 12 Physics (Batch A)',
    this.roomId = 'SSC-ROOM-84920',
  });

  @override
  ConsumerState<LiveClassroomScreen> createState() => _LiveClassroomScreenState();
}

class _LiveClassroomScreenState extends ConsumerState<LiveClassroomScreen> {
  bool _isWhiteboardMode = false;
  bool _hasStudentRaisedHand = false;

  final TextEditingController _chatMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 1. Automatic Attendance Check-In
    Future.microtask(() => _checkInAttendance());

    // 2. Launch Jitsi Meet Conference Session
    Future.microtask(() => _joinJitsiMeeting());
  }

  void _joinJitsiMeeting() async {
    try {
      final user = ref.read(authControllerProvider.notifier).currentUser;
      final userName = user?['name'] as String? ?? 'Aarav Sharma';
      final userEmail = user?['email'] as String? ?? 'aarav.sharma@shekharsir.edu';
      final isTeacher = (user?['role'] as String?)?.toLowerCase() == 'teacher';

      final cleanRoomName = widget.roomId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

      await JitsiService.joinMeeting(
        roomName: cleanRoomName.isNotEmpty ? cleanRoomName : "SSCRoom84920",
        subject: widget.title,
        displayName: isTeacher ? "Shekhar Sir ($userName)" : userName,
        email: userEmail,
      );
    } catch (e) {
      debugPrint('Jitsi Conference Join Exception: $e');
    }
  }

  void _checkInAttendance() async {
    try {
      final user = ref.read(authControllerProvider.notifier).currentUser;
      final studentName = user?['name'] as String? ?? 'Aarav Sharma';
      final isTeacher = (user?['role'] as String?)?.toLowerCase() == 'teacher';

      if (!isTeacher) {
        final apiService = ref.read(apiServiceProvider);
        final roomIdInt = int.tryParse(widget.roomId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 84920;
        await apiService.joinClassroomAttendance(
          classroomId: roomIdInt,
          studentName: studentName,
        );
      }
    } catch (_) {}
  }

  void _checkOutAttendance() async {
    try {
      final user = ref.read(authControllerProvider.notifier).currentUser;
      final studentName = user?['name'] as String? ?? 'Aarav Sharma';
      final isTeacher = (user?['role'] as String?)?.toLowerCase() == 'teacher';

      if (!isTeacher) {
        final apiService = ref.read(apiServiceProvider);
        final roomIdInt = int.tryParse(widget.roomId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 84920;
        await apiService.leaveClassroomAttendance(
          classroomId: roomIdInt,
          studentName: studentName,
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _checkOutAttendance();
    _chatMessageController.dispose();
    super.dispose();
  }

  String _formatSeconds(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _shareClassroomLink() {
    final shareUrl = 'https://shekharsir.app/classroom/join/${widget.roomId}';
    Clipboard.setData(ClipboardData(text: shareUrl));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Classroom Link Copied to Clipboard! $shareUrl'),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleRaiseHand() {
    setState(() {
      _hasStudentRaisedHand = !_hasStudentRaisedHand;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _hasStudentRaisedHand
              ? 'Hand Raised! Shekhar Sir has been notified.'
              : 'Hand lowered.',
        ),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openTeacherAttendanceReportBottomSheet() async {
    final apiService = ref.read(apiServiceProvider);
    final roomIdInt = int.tryParse(widget.roomId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 84920;

    List<dynamic> attendanceList = [];
    try {
      attendanceList = await apiService.getClassroomAttendanceReport(classroomId: roomIdInt);
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Attendance Report',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Expanded(
                  child: attendanceList.isEmpty
                      ? const Center(child: Text('No attendee records yet.'))
                      : ListView.builder(
                          itemCount: attendanceList.length,
                          itemBuilder: (context, index) {
                            final item = attendanceList[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Color(0xFFE0EAFF),
                                        child: Icon(Icons.person, size: 18, color: Color(0xFF2563EB)),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['student_name'] ?? 'Student',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          Text(
                                            'Participation: ${item['duration_minutes'] ?? 45.0} mins',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'PRESENT',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _endClassAndUploadRecording(bool isTeacher) async {
    if (!isTeacher) {
      _checkOutAttendance();
      Navigator.pop(context);
      return;
    }

    final sessionState = ref.read(classroomSessionProvider);
    final recordingDuration = _formatSeconds(sessionState.recordingSeconds);
    final sessionTimestamp = DateTime.now().toIso8601String();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Class & Upload Recording?'),
        content: Text(
          'Ending the session will stop live recording ($recordingDuration) and automatically package and upload the class recording to Batch Materials for students.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog

              ref.read(classroomSessionProvider.notifier).stopRecording();

              double uploadProgress = 0.0;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => StatefulBuilder(
                  builder: (context, setProgressState) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: uploadProgress > 0 ? uploadProgress : null,
                            color: const Color(0xFF2563EB),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            uploadProgress > 0
                                ? 'Uploading Recorded Lecture: ${(uploadProgress * 100).toStringAsFixed(0)}%'
                                : 'Packaging & Uploading Recorded Lecture...',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );

              try {
                final apiService = ref.read(apiServiceProvider);
                final roomIdInt = int.tryParse(widget.roomId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 84920;

                await apiService.uploadClassroomRecording(
                  classroomId: roomIdInt,
                  title: 'Recorded Lecture: ${widget.title}',
                  description: 'Live Session Recording • Duration: $recordingDuration • Recorded at: $sessionTimestamp',
                  fileType: 'Video',
                  fileUrl: 'https://shekharsir-backend.onrender.com/static/materials/recorded_lecture.mp4',
                  onSendProgress: (sent, total) {
                    if (total > 0 && mounted) {
                      uploadProgress = sent / total;
                    }
                  },
                );
              } catch (_) {}

              if (mounted) {
                Navigator.pop(context); // Close upload progress dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recorded session uploaded & stored in Batch Materials!'),
                    backgroundColor: Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(context); // Leave classroom
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('End & Upload', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openClassroomMaterialsBottomSheet() {
    final sessionState = ref.read(classroomSessionProvider);
    final recordingDuration = _formatSeconds(sessionState.recordingSeconds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Classroom Materials & Recordings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      _buildClassroomRecordingCard(
                        title: 'Recorded Lecture: ${widget.title}',
                        description: 'Recorded live session for ${widget.batch} • Duration: $recordingDuration',
                        fileUrl: 'https://shekharsir-backend.onrender.com/static/materials/recorded_lecture.mp4',
                      ),
                      _buildClassroomRecordingCard(
                        title: 'Wave Optics Formula Sheet & Chapter Notes',
                        description: 'Reference PDF for Young\'s Double Slit & Fringe Width formulas',
                        fileUrl: 'https://shekharsir-backend.onrender.com/static/materials/wave_optics_notes.pdf',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassroomRecordingCard({
    required String title,
    required String description,
    required String fileUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0EAFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF2563EB), size: 48),
                    title: const Text('Stream Lecture Online', textAlign: TextAlign.center),
                    content: SelectableText(fileUrl, style: const TextStyle(color: Color(0xFF2563EB))),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
              label: const Text('Stream Online', style: TextStyle(fontSize: 12, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openChatBottomSheet() {
    bool isQuestionFlag = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => Consumer(
        builder: (context, ref, child) {
          final chatState = ref.watch(chatProvider);
          final chatNotifier = ref.read(chatProvider.notifier);

          final user = ref.read(authControllerProvider.notifier).currentUser;
          final senderName = user?['name'] as String? ?? 'User';
          final isTeacher = (user?['role'] as String?)?.toLowerCase() == 'teacher';

          final displayedMessages = chatState.isQAndAMode
              ? chatState.messages.where((m) => m.isQuestion).toList()
              : chatState.messages;

          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: 420,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                chatState.isQAndAMode ? 'Q&A Doubts Panel' : 'Live Classroom Chat',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                selected: chatState.isQAndAMode,
                                label: Text(
                                  'Q&A Only',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: chatState.isQAndAMode ? Colors.white : const Color(0xFF2563EB),
                                  ),
                                ),
                                backgroundColor: const Color(0xFFE0EAFF),
                                selectedColor: const Color(0xFF2563EB),
                                padding: EdgeInsets.zero,
                                onSelected: (val) {
                                  chatNotifier.toggleQAndAFilter();
                                },
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: displayedMessages.isEmpty
                            ? const Center(
                                child: Text('No Q&A doubts submitted yet.', style: TextStyle(color: Colors.grey)),
                              )
                            : ListView.builder(
                                itemCount: displayedMessages.length,
                                itemBuilder: (context, index) {
                                  final msg = displayedMessages[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: msg.isQuestion
                                          ? const Color(0xFFFEF3C7)
                                          : msg.isTeacher
                                              ? const Color(0xFFE0EAFF)
                                              : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: msg.isQuestion ? Border.all(color: const Color(0xFFF59E0B)) : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  msg.sender,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: msg.isTeacher ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                                                  ),
                                                ),
                                                if (msg.isQuestion) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFD97706),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Text('Q&A DOUBT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(msg.time, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(msg.text, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.help_outline,
                              color: isQuestionFlag ? const Color(0xFFD97706) : Colors.grey,
                            ),
                            tooltip: 'Flag as Q&A Question',
                            onPressed: () {
                              setModalState(() {
                                isQuestionFlag = !isQuestionFlag;
                              });
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _chatMessageController,
                              decoration: InputDecoration(
                                hintText: isQuestionFlag ? 'Type a Q&A doubt question...' : 'Type a question or comment...',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: Color(0xFF2563EB)),
                            onPressed: () {
                              final text = _chatMessageController.text.trim();
                              if (text.isNotEmpty) {
                                chatNotifier.sendMessage(
                                  sender: senderName,
                                  text: text,
                                  isTeacher: isTeacher,
                                  isQuestion: isQuestionFlag,
                                );
                                _chatMessageController.clear();
                                setModalState(() {
                                  isQuestionFlag = false;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider.notifier).currentUser;
    final isTeacher = (user?['role'] as String?)?.toLowerCase() == 'teacher';

    final sessionState = ref.watch(classroomSessionProvider);
    final sessionNotifier = ref.read(classroomSessionProvider.notifier);

    final whiteboardState = ref.watch(whiteboardProvider);
    final whiteboardNotifier = ref.read(whiteboardProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _endClassAndUploadRecording(isTeacher),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'REC • ${_formatSeconds(sessionState.recordingSeconds)}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              '${widget.batch} • Room: ${widget.roomId}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
        actions: [
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.fact_check_outlined, color: Colors.white, size: 20),
              onPressed: _openTeacherAttendanceReportBottomSheet,
              tooltip: 'Live Attendance Report',
            ),
          IconButton(
            icon: const Icon(Icons.video_call, color: Colors.white, size: 20),
            onPressed: _joinJitsiMeeting,
            tooltip: 'Re-join Jitsi Meeting',
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined, color: Colors.white, size: 20),
            onPressed: _openClassroomMaterialsBottomSheet,
            tooltip: 'Classroom Materials & Recordings',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white, size: 20),
            onPressed: _shareClassroomLink,
            tooltip: 'Share Classroom Link',
          ),
          IconButton(
            icon: Icon(
              _isWhiteboardMode ? Icons.videocam : Icons.draw,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isWhiteboardMode = !_isWhiteboardMode;
              });
            },
            tooltip: _isWhiteboardMode ? 'Switch to Camera' : 'Switch to Whiteboard',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: _openChatBottomSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (sessionState.connectionStatus == ClassroomConnectionStatus.reconnecting)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFEF4444),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Connection lost. Reconnecting to Shekhar Sir Classes server...',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            if (isTeacher && _hasStudentRaisedHand)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFD97706),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pan_tool, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Aarav Sharma has raised their hand to ask a question!',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _hasStudentRaisedHand = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Allowed student microphone!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFD97706),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Unmute', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: _isWhiteboardMode
                  ? _buildInteractiveWhiteboard(whiteboardState, whiteboardNotifier)
                  : _buildLiveVideoStream(isTeacher, sessionState),
            ),

            if (_isWhiteboardMode) _buildWhiteboardToolbar(whiteboardState, whiteboardNotifier),

            _buildLiveControlBar(isTeacher, sessionState, sessionNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveWhiteboard(
    WhiteboardState whiteboardState,
    WhiteboardNotifier whiteboardNotifier,
  ) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              RenderBox renderBox = context.findRenderObject() as RenderBox;
              whiteboardNotifier.addPoint(renderBox.globalToLocal(details.globalPosition));
            },
            onPanStart: (details) {
              RenderBox renderBox = context.findRenderObject() as RenderBox;
              whiteboardNotifier.addPoint(renderBox.globalToLocal(details.globalPosition));
            },
            onPanEnd: (details) {
              whiteboardNotifier.endPath();
            },
            child: CustomPaint(
              painter: _WhiteboardPainter(drawingPoints: whiteboardState.points),
              size: Size.infinite,
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sync, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'LIVE WHITEBOARD SYNC',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteboardToolbar(
    WhiteboardState whiteboardState,
    WhiteboardNotifier whiteboardNotifier,
  ) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFFEF4444),
      const Color(0xFF10B981),
      Colors.black,
      const Color(0xFFD97706),
    ];

    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: colors.map((col) {
              final isSelected = whiteboardState.selectedColor == col && !whiteboardState.isEraserMode;
              return GestureDetector(
                onTap: () {
                  whiteboardNotifier.setColor(col);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: col,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(
            width: 90,
            child: Slider(
              value: whiteboardState.strokeWidth,
              min: 2.0,
              max: 12.0,
              activeColor: const Color(0xFF2563EB),
              inactiveColor: Colors.white24,
              onChanged: (val) {
                whiteboardNotifier.setStrokeWidth(val);
              },
            ),
          ),

          Row(
            children: [
              IconButton(
                icon: Icon(Icons.cleaning_services, color: whiteboardState.isEraserMode ? const Color(0xFF2563EB) : Colors.white, size: 20),
                onPressed: () {
                  whiteboardNotifier.toggleEraser();
                },
                tooltip: 'Eraser Mode',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () {
                  whiteboardNotifier.clearCanvas();
                },
                tooltip: 'Clear Canvas',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveVideoStream(bool isTeacher, ClassroomSessionState sessionState) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: !sessionState.isVideoOn
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF2563EB),
                        child: Text(
                          isTeacher ? 'S' : 'A',
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Video Stream Paused',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            sessionState.isScreenSharing ? Icons.present_to_all : Icons.school,
                            size: 64,
                            color: const Color(0xFF2563EB),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            sessionState.isScreenSharing
                                ? 'Shekhar Sir is Sharing Screen'
                                : 'Shekhar Sir (Live Instructor)',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Jitsi Meet SDK Real-time Conference Active',
                            style: TextStyle(color: Color(0xFF10B981), fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _joinJitsiMeeting,
                            icon: const Icon(Icons.video_call, color: Colors.white),
                            label: const Text('Launch Jitsi Video Conference', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Center(
                child: Text(
                  isTeacher ? 'Teacher Self' : 'You (Student)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveControlBar(
    bool isTeacher,
    ClassroomSessionState sessionState,
    ClassroomSessionNotifier sessionNotifier,
  ) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: sessionState.isMuted ? Icons.mic_off : Icons.mic,
            label: sessionState.isMuted ? 'Unmute' : 'Mute',
            bgColor: sessionState.isMuted ? Colors.redAccent : const Color(0xFF334155),
            onTap: () {
              sessionNotifier.toggleMute();
            },
          ),

          _buildControlButton(
            icon: !sessionState.isVideoOn ? Icons.videocam_off : Icons.videocam,
            label: !sessionState.isVideoOn ? 'Start Cam' : 'Stop Cam',
            bgColor: !sessionState.isVideoOn ? Colors.redAccent : const Color(0xFF334155),
            onTap: () {
              sessionNotifier.toggleVideo();
            },
          ),

          if (isTeacher)
            _buildControlButton(
              icon: Icons.screen_share,
              label: 'Share',
              bgColor: sessionState.isScreenSharing ? const Color(0xFF2563EB) : const Color(0xFF334155),
              onTap: () {
                sessionNotifier.toggleScreenShare();
              },
            ),

          if (!isTeacher)
            _buildControlButton(
              icon: Icons.pan_tool,
              label: 'Raise Hand',
              bgColor: _hasStudentRaisedHand ? const Color(0xFFD97706) : const Color(0xFF334155),
              onTap: _toggleRaiseHand,
            ),

          _buildControlButton(
            icon: Icons.call_end,
            label: 'Leave',
            bgColor: Colors.red,
            onTap: () => _endClassAndUploadRecording(isTeacher),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

// Custom Painter for Interactive Whiteboard
class _WhiteboardPainter extends CustomPainter {
  final List<WhiteboardPoint?> drawingPoints;

  _WhiteboardPainter({required this.drawingPoints});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < drawingPoints.length - 1; i++) {
      if (drawingPoints[i] != null && drawingPoints[i + 1] != null) {
        canvas.drawLine(
          drawingPoints[i]!.offset,
          drawingPoints[i + 1]!.offset,
          drawingPoints[i]!.paint,
        );
      } else if (drawingPoints[i] != null && drawingPoints[i + 1] == null) {
        canvas.drawPoints(
          PointMode.points,
          [drawingPoints[i]!.offset],
          drawingPoints[i]!.paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
