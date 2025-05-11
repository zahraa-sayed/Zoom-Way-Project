import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// CUBIT
class MessageCenterCubit extends Cubit<MessageCenterState> {
  MessageCenterCubit() : super(MessageCenterInitial());

  void loadMessages() {
    // Initially showing empty state, but here you would fetch messages
    emit(MessageCenterLoaded(messages: []));
  }

  void refreshMessages() {
    emit(MessageCenterLoading());
    // Simulate network request
    Future.delayed(const Duration(seconds: 1), () {
      loadMessages();
    });
  }
}

// STATES
abstract class MessageCenterState {}

class MessageCenterInitial extends MessageCenterState {}

class MessageCenterLoading extends MessageCenterState {}

class MessageCenterLoaded extends MessageCenterState {
  final List<Message> messages;

  MessageCenterLoaded({required this.messages});
}

class MessageCenterError extends MessageCenterState {
  final String message;

  MessageCenterError({required this.message});
}

// MODEL
class Message {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });
}

// MAIN SCREEN
class MessageCenterScreen extends StatelessWidget {
  const MessageCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MessageCenterCubit()..loadMessages(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Row(
            children: [
              Text(
                'Message Center',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black),
              onPressed: () {
                // Show options menu
              },
            ),
          ],
        ),
        body: const MessageCenterView(),
      ),
    );
  }
}

// MAIN VIEW
class MessageCenterView extends StatelessWidget {
  const MessageCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageCenterCubit, MessageCenterState>(
      builder: (context, state) {
        if (state is MessageCenterInitial || state is MessageCenterLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MessageCenterLoaded) {
          if (state.messages.isEmpty) {
            return const EmptyMessageCenter();
          }
          return MessageList(messages: state.messages);
        } else if (state is MessageCenterError) {
          return Center(child: Text((state).message));
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// EMPTY STATE
class EmptyMessageCenter extends StatelessWidget {
  const EmptyMessageCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search, color: Colors.grey),
                      ),
                      Text(
                        'Search messages',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mail_outline,
                    size: 36,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Messages Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.bottomCenter,
          child: Text(
            '394 x 831',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              backgroundColor: Colors.blue[400],
            ),
          ),
        ),
      ],
    );
  }
}

// MESSAGE LIST (would be used when there are messages)
class MessageList extends StatelessWidget {
  final List<Message> messages;

  const MessageList({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: messages.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageTile(message: message);
      },
    );
  }
}

// MESSAGE TILE
class MessageTile extends StatelessWidget {
  final Message message;

  const MessageTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: message.isRead ? Colors.grey[300] : Colors.blue,
        child: const Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        message.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(
        _formatDate(message.timestamp),
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: message.isRead
          ? null
          : const CircleAvatar(
              radius: 5,
              backgroundColor: Colors.blue,
            ),
      onTap: () {
        // Handle message tap
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    // Format date as needed
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }
}

// MAIN APP FOR TESTING
