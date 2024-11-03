import 'package:flutter/material.dart';
import "package:flash_chat_flutter/constants.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:cloud_firestore/cloud_firestore.dart";

final _fireStore = FirebaseFirestore.instance;
User? loggedInUser;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String messageText = '';

  Future<void> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      // print(e);
    }
  }

  void sendMessage() {
    _fireStore.collection('messages').add(
      {
        "text": messageText,
        "sender": loggedInUser?.email,
        'createdAt': DateTime.now(),
      },
    );
  }

  // Future<void> getMessages() async {
  //   final messages = await _fireStore.collection('messages').get();
  //   for (var doc in snapshot.docs) {
  //         print(doc.data());
  //   }
  // }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pushNamed(context, "/");
              }),
        ],
        title: const Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.black),
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (messageText != "") {
                        sendMessage();
                        messageText = "";
                      }
                      messageTextController.clear();
                    },
                    child: const Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MassageBubble extends StatelessWidget {
  const MassageBubble({super.key, required this.text, required this.sender});
  final String text;
  final String sender;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: loggedInUser?.email == sender
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(sender,
              style: const TextStyle(fontSize: 15.0, color: Colors.black)),
          Card(
            elevation: 5.0,
            color: loggedInUser?.email == sender
                ? Colors.lightBlueAccent
                : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 15.0,
                    color: loggedInUser?.email == sender
                        ? Colors.white
                        : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  const MessageStream({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _fireStore
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final msgs = snapshot.data?.docs;
          return Expanded(
            child: ListView(
              reverse: true,
              children: msgs!.map((msg) {
                return MassageBubble(text: msg['text'], sender: msg['sender']);
              }).toList(),
            ),
          );
        });
  }
}
