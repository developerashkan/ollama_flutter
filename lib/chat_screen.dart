import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> chatMessages = [
    {"role": "system", "content": "You are an assistant."},
  ];

  Future<void> sendMessage(String prompt) async {
    final message = {"role": "user", "content": prompt};

    setState(() {
      chatMessages.add(message);
    });

    final data = {"model": "gemma3:1b", "messages": chatMessages, "stream": false};

    try {
      if (kDebugMode) {
        print('Sending request to Ollama...');
      }

      final response =
      //Android Emulator: http://10.0.2.2:11434
      await http.post(Uri.parse("http://10.0.2.2:11434/api/chat"),
          headers: {"Content-Type": "application/json"}, body: json.encode(data)).timeout(Duration(seconds: 30));

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          chatMessages.add({"role": "assistant", "content": responseData["message"]["content"] ?? "No response"});
        });
        _controller.clear();
      } else {
        if (kDebugMode) {
          print('Error: ${response.statusCode} - ${response.body}');
        }
        setState(() {
          chatMessages.remove(message);
          chatMessages.add({"role": "assistant", "content": "Error: ${response.statusCode}"});
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Exception: $e');
        print('Stack trace: $stackTrace');
      }

      setState(() {
        chatMessages.remove(message);
        chatMessages.add({"role": "assistant", "content": "Connection failed: $e"});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Ollama Chat"),
        centerTitle: true,
        backgroundColor: Colors.white.withOpacity(0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark, statusBarBrightness: Brightness.light),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFEBF8FF)]),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView.builder(
                      itemCount: chatMessages.length,
                      itemBuilder: (context, index) {
                        if (index == 0) return const SizedBox.shrink();
                        final message = chatMessages[index];
                        final isUserMessage = message["role"] == 'user';

                        final Color messageColor = isUserMessage ? Colors.blue : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.35);

                        final alignment = isUserMessage ? Alignment.centerRight : Alignment.centerLeft;

                        final borderRadius = BorderRadius.only(topLeft: Radius.circular(isUserMessage ? 20 : 4), topRight: Radius.circular(isUserMessage ? 4 : 20), bottomLeft: const Radius.circular(20), bottomRight: const Radius.circular(20));

                        return Align(
                          alignment: alignment,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: messageColor, borderRadius: borderRadius),
                            child: Text(message["content"] ?? '', style: TextStyle(color: isUserMessage ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: "Message Ollama...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(36), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_upward, color: Colors.white),
                            onPressed: () {
                              if (_controller.text.isNotEmpty) {
                                sendMessage(_controller.text);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    onSubmitted: (text) {
                      if (text.isNotEmpty) {
                        sendMessage(text);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}