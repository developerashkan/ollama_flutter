import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class SendMessageEvent extends ChatEvent {
  final String prompt;
  const SendMessageEvent(this.prompt);

  @override
  List<Object> get props => [prompt];

}
