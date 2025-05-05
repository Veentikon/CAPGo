import 'package:flutter/material.dart';
import 'package:meida/app_data.dart';
// import 'package:meida/components/misc.dart';
import 'package:meida/web/chat_screen_web.dart';
import 'package:provider/provider.dart';

class MessageScreenWeb extends StatefulWidget {
  const MessageScreenWeb({super.key});

  @override
  State<MessageScreenWeb> createState() => _MessageScreenWebState();
}

class _MessageScreenWebState extends State<MessageScreenWeb> {
  var rooms = <String>['0', '1', '2', '3', '4']; // These can be objects with room_id, etc.
  String? selectedRoom;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return Center(
        child: Text('No messages'),
      );
    }

    var appState = context.watch<MyAppState>();

    return Scaffold(
      backgroundColor: Color.fromRGBO(61, 61, 61, 1),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: ListView( // Display active chats / communications
              padding: EdgeInsets.all(5.0),
              children: [
                for (var chat in rooms)
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text("Chat: $chat", style: TextStyle(color: Colors.white),),
                    // title: Text("Chat: $chat",),
                    selectedColor: Color.fromRGBO(230, 67, 86, 1),
                    enabled: true,
                    selected: selectedRoom == chat,
                    onTap: () => {
                      // selectedRoom = chat,
                      setState(() {
                        selectedRoom = chat;
                      }),
                    },
                  ),
              ],
            ),
          ),
          SizedBox(child: VerticalDivider(color: Color.fromRGBO(230, 67, 86, 1),)),
          Expanded(
            flex: 5,
            child: Container(
              // color: Theme.of(context).colorScheme.surfaceContainerHighest,
              color: Color.fromRGBO(61, 61, 61, 1),
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
      )
      // body: Center(
      //   child: SansBold(text: "This is message screen", size: 22.0),
      // ),
    );
  }
}