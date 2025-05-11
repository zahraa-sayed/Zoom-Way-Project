import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Message Model
class AIChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AIChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// Cubit
class AIChatCubit extends Cubit<AIChatState> {
  AIChatCubit() : super(AIChatInitial());

  Future<void> sendMessage(String message) async {
    try {
      emit(MessageSending());

      final response = await http.post(
        Uri.parse('https://a519-35-226-33-107.ngrok-free.app/ask'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
        body: json.encode({'question': message}),
      );

      if (response.statusCode == 200) {
        // Ensure proper UTF-8 decoding
        final String responseBody = utf8.decode(response.bodyBytes);
        final data = json.decode(responseBody);
        final aiResponse = data['answer'] as String;

        final currentState = state;
        if (currentState is MessagesLoaded) {
          final updatedMessages =
              List<AIChatMessage>.from(currentState.messages)
                ..addAll([
                  AIChatMessage(
                    text: message,
                    isUser: true,
                    timestamp: DateTime.now(),
                  ),
                  AIChatMessage(
                    text: aiResponse,
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                ]);
          emit(MessagesLoaded(messages: updatedMessages));
        } else {
          emit(MessagesLoaded(messages: [
            AIChatMessage(
              text: message,
              isUser: true,
              timestamp: DateTime.now(),
            ),
            AIChatMessage(
              text: aiResponse,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          ]));
        }
      } else {
        emit(ChatError('Failed to get response from AI'));
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }
}

// States
abstract class AIChatState {}

class AIChatInitial extends AIChatState {}

class MessageSending extends AIChatState {}

class MessagesLoaded extends AIChatState {
  final List<AIChatMessage> messages;
  MessagesLoaded({required this.messages});
}

class ChatError extends AIChatState {
  final String message;
  ChatError(this.message);
}

// Main Screen
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AIChatCubit(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF40C4A5),
          title: Column(
            children: [
              Image.asset(
                'assets/images/Chatbot.png',
                height: 32.h,
                width: 32.h,
                fit: BoxFit.contain,
              ),
              const Text(
                'Ask AI',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocConsumer<AIChatCubit, AIChatState>(
          listener: (context, state) {
            if (state is MessagesLoaded) {
              Future.delayed(
                const Duration(milliseconds: 100),
                _scrollToBottom,
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: state is MessagesLoaded
                      ? ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(16.w),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];
                            return _MessageBubble(message: message);
                          },
                        )
                      : const Center(child: Text('Start a conversation!')),
                ),
                _buildInputField(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputField(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              // Add RTL support
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                hintStyle: TextStyle(
                  fontFamily: 'Cairo', // Add Arabic font support
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 10.h,
                ),
              ),
              style: TextStyle(
                fontFamily: 'Cairo', // Add Arabic font support
                fontSize: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF40C4A5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                if (_messageController.text.trim().isNotEmpty) {
                  context
                      .read<AIChatCubit>()
                      .sendMessage(_messageController.text.trim());
                  _messageController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AIChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF40C4A5) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.r),
        ),
        constraints: BoxConstraints(maxWidth: 0.7.sw),
        child: Text(
          message.text,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 16.sp,
            fontFamily: 'Cairo',
            height: 1.5, // Add line height for better Arabic text readability
            letterSpacing: 0.5, // Adjust letter spacing for Arabic
          ),
        ),
      ),
    );
  }
}
