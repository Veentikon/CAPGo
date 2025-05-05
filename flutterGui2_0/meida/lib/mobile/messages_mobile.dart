import 'package:flutter/material.dart';
import 'package:meida/components/misc.dart';

class MessageScreenMobile extends StatefulWidget {
  const MessageScreenMobile({super.key});

  @override
  State<MessageScreenMobile> createState() => _MessageScreenMobileState();
}

class _MessageScreenMobileState extends State<MessageScreenMobile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(61, 61, 61, 1),
      body: Center(
        child: SansBold(text: "This is message screen mobile", size: 22.0),
      ),
    );
  }
}