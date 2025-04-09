import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// import '../app_data.dart';
import '../backend/chat_data.dart';
import '../app_data.dart';


/*
Screen user sees when exchanging messages with the other users
*/


class MessagingScreen extends StatelessWidget {
  // late List<Message> messages;
  final String chatId;
  const MessagingScreen({required this.chatId, super.key});

  @override
  Widget build(BuildContext context) {
    // var appState = context.watch<MyAppState>();
    final chat = context.read<MyAppState>().getChat(chatId);

    return ChangeNotifierProvider.value(
      value: chat, 
      child: ChatUI(),
    );
  }
}


class ChatUI extends StatelessWidget {
  const ChatUI({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final chat = Provider.of<ChatData>(context);
    var messageBoxController = TextEditingController();
    final currentUserId = context.read<MyAppState>().currentUser;
    FocusNode focusNode = FocusNode(); // add in your state

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8.0),
            children: chat.getMessages().map((msg) {
              return Align(
                alignment: msg.senderId == currentUserId // If current user is sender, align box to the right.
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
                  decoration: BoxDecoration(
                    color: msg.senderId == currentUserId
                        ? Colors.blue[100]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  constraints: const BoxConstraints(
                    maxWidth: 300, // Optional: to prevent too-long lines
                  ),
                  child: Text(
                    msg.content,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            alignment: Alignment.bottomCenter,
            padding: EdgeInsets.all(3.0), // This padding is applied inside of the Container
            decoration: BoxDecoration(color: const Color.fromARGB(255, 109, 177, 214), borderRadius: BorderRadius.circular(20.0)),
            child: Row(
              children: [
                Icon(Icons.emoji_emotions_outlined, color: Colors.amber),
                SizedBox(width: 4,),
                Expanded(child: KeyboardListener(
                  focusNode: focusNode,
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                      chat.addMessage(appState.currentUser, messageBoxController.text, DateTime.now());
                    }
                  },
                  child: TextField(
                    onEditingComplete: () => chat.addMessage("123", messageBoxController.text, DateTime.now()),
                    controller: messageBoxController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintStyle: TextStyle(),
                      hintText: "Message... ",
                    ),
                  ),
                )),
              ],
            )
          ),
        ),
      ],
    );
  }
}