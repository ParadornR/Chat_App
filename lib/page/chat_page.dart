import 'package:chatapp/components/chat_bubble.dart';
import 'package:chatapp/services/chat/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final receiverUserEmail;
  final receiverUserID;
  const ChatPage({
    super.key,
    required this.receiverUserEmail,
    required this.receiverUserID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String extractPrefix(String email) {
    return email.split('@')[0];
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate(); // แปลง Timestamp เป็น DateTime
    return DateFormat('hh:mm a').format(date); // ใช้รูปแบบเวลา 12 ชั่วโมง
  }

  void sendMessage() async {
    // only send message if there is something to send
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
          widget.receiverUserID, _messageController.text);
      // clearthe text controller after sending the message
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverUserEmail),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        }, // Unfocus เมื่อแตะบริเวณอื่น,
        child: Column(children: [
          // message
          Expanded(
            child: _buildMessageList(),
          ),
          //user input
          _buillMessageInput(),
        ]),
      ),
    );
  }

  // build message list
  Widget _buildMessageList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder(
        stream: _chatService.getMessages(
            widget.receiverUserID, _firebaseAuth.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('loading..');
          }
          return ListView(
            children: snapshot.data!.docs
                .map((document) => _buildMessageItem(document))
                .toList(),
          );
        },
      ),
    );
  }

  // build message item
  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    var aligment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      alignment: aligment,
      child: Column(
        crossAxisAlignment: (data['senderId'] == _firebaseAuth.currentUser!.uid)
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisAlignment: (data['senderId'] == _firebaseAuth.currentUser!.uid)
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Text(extractPrefix(data['senderEmail'])),
          Row(
            mainAxisAlignment:
                (data['senderId'] == _firebaseAuth.currentUser!.uid)
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
            children: data['senderId'] == _firebaseAuth.currentUser!.uid
                ? [
                    Text(
                      formatTimestamp(data['timestamp']).toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    ChatBubble(message: data['message']),
                  ]
                : [
                    ChatBubble(message: data['message']),
                    const SizedBox(width: 8),
                    Text(
                      formatTimestamp(data['timestamp']).toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  // build message input
  Widget _buillMessageInput() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8), border: Border.all(width: 2)),
      child: Row(
        children: [
          // send image
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: Colors.black,
            ),
          ),
          // textField
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '',
              ),
              obscureText: false,
            ),
          ),
          const SizedBox(width: 8),

          // send message
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(
              Icons.arrow_circle_right_outlined,
              size: 40,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
