import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessageModel {
  final String id;
  final String sender;
  final String text;
  final String time;
  final bool isTeacher;
  final bool isQuestion; // Q&A flag

  ChatMessageModel({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    this.isTeacher = false,
    this.isQuestion = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sender: json['sender']?.toString() ?? 'User',
      text: json['text']?.toString() ?? '',
      time: json['time']?.toString() ?? 'Just now',
      isTeacher: json['is_teacher'] == true,
      isQuestion: json['is_question'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'text': text,
      'time': time,
      'is_teacher': isTeacher,
      'is_question': isQuestion,
    };
  }
}

class ChatState {
  final List<ChatMessageModel> messages;
  final bool isConnected;
  final bool isQAndAMode;

  const ChatState({
    this.messages = const [],
    this.isConnected = true,
    this.isQAndAMode = false,
  });

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isConnected,
    bool? isQAndAMode,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isConnected: isConnected ?? this.isConnected,
      isQAndAMode: isQAndAMode ?? this.isQAndAMode,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier()
      : super(
          ChatState(
            messages: [
              ChatMessageModel(
                id: '1',
                sender: 'Shekhar Sir',
                text: 'Welcome students! Today we are discussing Young\'s Double Slit Experiment.',
                time: '10:30 AM',
                isTeacher: true,
              ),
              ChatMessageModel(
                id: '2',
                sender: 'Aarav Sharma',
                text: 'Sir, is fringe width independent of order of fringe?',
                time: '10:32 AM',
                isQuestion: true,
              ),
              ChatMessageModel(
                id: '3',
                sender: 'Ananya Gupta',
                text: 'Yes, β = λD/d formula applies for all bright fringes.',
                time: '10:33 AM',
              ),
            ],
          ),
        );

  void sendMessage({
    required String sender,
    required String text,
    required bool isTeacher,
    bool isQuestion = false,
  }) {
    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final newMsg = ChatMessageModel(
      id: now.millisecondsSinceEpoch.toString(),
      sender: sender,
      text: text,
      time: timeStr,
      isTeacher: isTeacher,
      isQuestion: isQuestion,
    );

    state = state.copyWith(messages: [...state.messages, newMsg]);
  }

  void toggleQAndAFilter() {
    state = state.copyWith(isQAndAMode: !state.isQAndAMode);
  }
}

final chatProvider =
    StateNotifierProvider.autoDispose<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
