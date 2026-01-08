import 'package:equatable/equatable.dart';

class ChatState extends Equatable {
  final List<Map<String, String>> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  factory ChatState.initial() {
    return const ChatState(
      messages: [
        {"role": "system", "content": "You are an assistant."},
      ],
      isLoading: false,
    );
  }

  ChatState copyWith({
    List<Map<String, String>>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error == null ? null : (error == '' ? null : error),
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, error];
}
