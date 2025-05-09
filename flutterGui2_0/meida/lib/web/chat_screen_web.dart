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


class ChatUI extends StatefulWidget {
  const ChatUI({super.key});

  @override
  State<ChatUI> createState() => _MessagingPageState();
}
  
class _MessagingPageState extends State<ChatUI> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  
  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final chat = Provider.of<ChatData>(context);
    final currentUserId = context.read<MyAppState>().currentUser;
    final FocusNode _focusNode = FocusNode();
    final ScrollController _scrollController = ScrollController();
    // FocusNode focusNode = FocusNode(); // add in your state

    // _scrollController.jumpTo(_scrollController.position.maxScrollExtent); // Display from the bottom

    return Column(
      children: [
        Expanded(
          child: ListView( // On new elements inserted, scroll down
            controller: _scrollController,
            
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
                    maxWidth: 360, // Optional: to prevent too-long lines
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
            // decoration: BoxDecoration(color: const Color.fromARGB(255, 109, 177, 214), borderRadius: BorderRadius.circular(20.0)),
            
            child: Row(
              children: [
                Icon(Icons.emoji_emotions_outlined, color: Colors.amber),
                SizedBox(width: 4,),
                Expanded(child: KeyboardListener(
                  focusNode: _focusNode,
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                      final message = _controller.text;
                      if (message.isNotEmpty) {
                        chat.addMessage(appState.currentUser, _controller.text, DateTime.now());
                        _controller.clear();
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent + 500, // add some buffer
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                        FocusScope.of(context).requestFocus(_focusNode);
                      }
                    }
                  },
                  child: TextField(
                    autofocus: true,
                    canRequestFocus: true,
                    // textInputAction: TextInputAction.newline,
                    controller: _controller,
                    maxLines: 3,
                    minLines: 1,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20.0)), borderSide: BorderSide(color: Color.fromRGBO(247, 55, 79, 1.0))),
                      // border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20.0)), borderSide: BorderSide(color: Color.fromRGBO(247, 55, 79, 1.0))),
                      hintStyle: TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20.0)), borderSide: BorderSide(color: Color.fromRGBO(247, 55, 79, 1.0))),
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