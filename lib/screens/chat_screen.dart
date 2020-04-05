import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

FirebaseUser loggedInUser;
final _firestore = Firestore.instance;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String messageText;

  @override
  void initState() {
    super.initState();

    getCurrentUser();
  }

  // Get Logged In User
  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        // print(loggedInUser.email); // For debugging
      }
    } catch (e) {
      print(e);
    }  
  }

  // This section of commented out code is replaced by
  // class MessagesStream at line 138.

  // Retrieve saved messages from Firebase Database
  // void getMessages() async {
  //   final messages = await _firestore.collection('messages').getDocuments();
    
  //   // documents refers to the saved messages in the database
  //   for (var message in messages.documents) {
  //     print(message.data);
  //   }
  // }

  // Retrieve saved messages from Firebase Database
  // Actively retrieves messages from database
  // when there are new messages
  // Above method have to be triggered manually
//  void messagesStream() async {
//    await for ( var snapshot in _firestore.collection('messages').snapshots()) {
//      for (var message in snapshot.documents) {
//        print(message.data);
//      }
//    }
//  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Calls function that retrieves messages from Firebase Database
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    iconSize: 25.0,
                    color: Colors.yellow[700],
                    onPressed: () {
                      // Clear textbox words after pressing 'Send'
                      messageTextController.clear();

                      // Implement send functionality.
                      // messageText + loggedInUser.email

                      // From Firebase Database collections.
                      // The collection must be the same as
                      // one of the collection created there.
                      
                      // Messages are sent to Firebase database
                      // and saved there.
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                      });
                    },                 
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

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      // AsyncSnapshot, different snapshot from the one in MessagesStream
      builder: (context, snapshot) {
        if(!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        // As the ListView for Expanded (line 176) is reverse
        // messages will appear at the top instead of bottom
        // documents.reversed is used to ensure they appear at the bottom
        final messages = snapshot.data.documents.reversed;
        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          // Both message.data['field'] has to match
          // a collection found in Firebase Database.
          final messageText = message.data['text'];
          final messageSender = message.data['sender'];

          final currentUser = loggedInUser.email;

          final messageBubble = MessageBubble(
            sender: messageSender,
            text: messageText,
            isMe: currentUser == messageSender,
          );

          messageBubbles.add(messageBubble);
        }
        // Expanded prevents whole screen from being taken up
        // only takes up space that the screen can afford.
        return Expanded(
          child: ListView(
            // Page stays at bottom instead of top
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          )
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isMe});
  
  final String sender;
  final String text;
  final bool isMe; // To differentiate text between User and others

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender, 
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.black54,
            ),
          ),
          Material(
            // Customize edges to make them circular
            // or leave them sharp
            borderRadius: isMe ? BorderRadius.only(
              topLeft: Radius.circular(30.0),
              bottomLeft: Radius.circular(30.0)
            ) : BorderRadius.only(
              topRight: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0)
            ),
            // Make boxes "float" and cast shadows
            // elevation: 5.0,
            color: isMe ? Colors.yellow[100] : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16.0,
               ),
              ),
            ),
          ),
        ],
      ),
    );  
  }
}