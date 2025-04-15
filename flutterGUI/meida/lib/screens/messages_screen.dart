import './messaging_screen.dart';
import 'package:flutter/material.dart';

/*
Screen that displayes all the active chatrooms/message sessions with the other users.
Consists of two parts:
Left side displayes all active chatrooms / message sessions
Right side is messaging screen showing conversation of the selected chatroom / message session
*/

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesScreen> {
  var rooms = <String>['0', '1', '2', '3', '4']; // These can be objects with room_id, etc.
  String? selectedRoom;

  @override
  Widget build(BuildContext context) {

    if (rooms.isEmpty) {
      return Center(
        child: Text('No messages'),
      );
    }

    return Scaffold(
      // appBar: AppBar(title: Text('My App')),
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: ListView(
              children: [
                for (var chat in rooms)
                  ListTile(
                    leading: Icon(Icons.person), // Icons.person is placeholder for CircleAvatar
                    title: Text("Chat: $chat"),
                    selectedColor: Colors.deepOrange,
                    enabled: true,
                    selected: selectedRoom == chat,
                    onTap: () => {
                      setState(() {
                        selectedRoom = chat;
                      })
                    },
                  )
              ]
            ),
          ),
          SizedBox(child: VerticalDivider(width: 1.5, color: Colors.black)),
          Expanded(
            flex: 5,
            child: Container(
              // color: Theme.of(context).colorScheme.surfaceContainerHighest,
              color: Colors.white,
              child: selectedRoom != null // Conditionally render
                ? MessagingScreen(chatId: selectedRoom!)
                : Center (
                  child: Text(
                    'Select a chat room to start messaging',
                    style: Theme.of(context).textTheme.bodyLarge,
                  )
                )
              // Center(child: MessagingScreen(chatId: selectedRoom!)),// This is where you load the messaging screen
            )
          )
        ],
      ),
    );
  }
}