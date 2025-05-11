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

// Cubit
class AIChatCubit extends Cubit<AIChatState> {
  AIChatCubit() : super(AIChatInitial());

  Future<void> sendMessage(String message) async {
    try {
      emit(MessageSending());

      final response = await http.post(
        Uri.parse('https://127c-35-194-244-167.ngrok-free.app/ask'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
        body: json.encode({'question': message}),
      );

      if (response.statusCode == 200) {
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
        emit(ChatError('فشل في استلام الرد من الذكاء الصناعي'));
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }
}

// Main Screen
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(130.h),
          child: ClipPath(
            clipper: CustomAppBarClipper(),
            child: Container(
              color: const Color(0xFF40C4A5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20.h),
                    Image.asset(
                      'assets/images/Chatbot.png',
                      height: 70.h,
                      width: 70.h,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Ask AI',
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    // زر الرجوع
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context); // العودة للصفحة السابقة
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: BlocConsumer<AIChatCubit, AIChatState>(
          listener: (context, state) {
            if (state is MessagesLoaded) {
              Future.delayed(const Duration(milliseconds: 200), () {
                _scrollToBottom();
              });
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: state is MessagesLoaded
                      ? ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];
                            return _MessageBubble(message: message);
                          },
                        )
                      : const Center(
                          child: Text('ابدأ المحادثة!',
                              style: TextStyle(fontFamily: 'Cairo')),
                        ),
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                hintStyle: TextStyle(fontFamily: 'Cairo'),
                fillColor: Colors.white,
                filled: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
              style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp),
            ),
          ),
          SizedBox(width: 8.w),
          InkWell(
            onTap: () {
              if (_messageController.text.trim().isNotEmpty) {
                context
                    .read<AIChatCubit>()
                    .sendMessage(_messageController.text.trim());
                _messageController.clear();
              }
            },
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF40C4A5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send, color: Colors.white, size: 24.sp),
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
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF40C4A5) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.shade300),
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
            height: 1.5,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// Custom Clipper for the AppBar curve
class CustomAppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
