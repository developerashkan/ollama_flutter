import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:ollama_flutter/chat_event.dart';
import 'package:ollama_flutter/chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(ChatState.initial()) {
    on<SendMessageEvent>(_onSendMessage);
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) async {
    final userMessage = {"role": "user", "content": event.prompt};

    final updatedMessages = List<Map<String, String>>.from(state.messages)..add(userMessage);
    emit(state.copyWith(messages: updatedMessages, isLoading: true));

    final data = {
      "model": "gemma3:1b",
      "messages": updatedMessages,
      "stream": false
    };

    try {
      if (kDebugMode) {
        print('Sending request to Ollama...');
      }
      //Android Emulator: http://10.0.2.2:11434
      final response = await http
          .post(
        Uri.parse("http://10.0.2.2:11434/api/chat"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      )
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final messageContent = (responseData["message"] as Map<String, dynamic>)["content"] as String?;

        final assistantMessage = {
          "role": "assistant",
          "content": messageContent ?? "No response"
        };

        final finalMessages = List<Map<String, String>>.from(updatedMessages)..add(assistantMessage);
        emit(state.copyWith(messages: finalMessages, isLoading: false));
      } else {
        if (kDebugMode) {
          print('Error: ${response.statusCode} - ${response.body}');
        }

        final errorMessage = {
          "role": "assistant",
          "content": "Error: ${response.statusCode}"
        };

        final errorMessages = List<Map<String, String>>.from(state.messages)
          ..remove(userMessage)
          ..add(errorMessage);

        emit(state.copyWith(messages: errorMessages, isLoading: false));
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Exception: $e');
        print('Stack trace: $stackTrace');
      }

      final errorMessage = {
        "role": "assistant",
        "content": "Connection failed: $e"
      };

      final errorMessages = List<Map<String, String>>.from(state.messages)
        ..remove(userMessage)
        ..add(errorMessage);

      emit(state.copyWith(messages: errorMessages, isLoading: false, error: e.toString()));
    }
  }
}