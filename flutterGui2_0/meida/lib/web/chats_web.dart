import 'package:flutter/material.dart';

class ChatsWeb extends StatefulWidget {
  const ChatsWeb({super.key});

  @override
  State<ChatsWeb> createState() => _ChatsWebState();
}

class _ChatsWebState extends State<ChatsWeb> {
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          flex: 2,
          child: ListView(
            scrollDirection: Axis.vertical,
            controller: scrollController,
            padding: EdgeInsets.all(4.3),
            children: [
              Icon(Icons.circle),
              Icon(Icons.circle),
              Icon(Icons.circle),
            ],
          ),
        ),
        Flexible(
          child: ListView()
        ),
      ],
    );
  }
}