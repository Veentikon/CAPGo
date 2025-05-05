import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class TextForm extends StatelessWidget {
  final TextEditingController controller;
  final String text;
  final double? containerWidth;
  final int? maxLines;
  final Color? hintColor;
  final bool? obscure;
  final int? maxChars;

  const TextForm({super.key, required this.text, required this.controller, this.containerWidth, this.maxLines, this.hintColor, this.obscure, this.maxChars});


  @override
  Widget build(BuildContext context) {
    Color color1 = Color.fromRGBO(247, 55, 79, 1.0);
    Color color1Accent = Color.fromRGBO(230, 67, 86, 1);
    Color color2 = Color.fromRGBO(136, 48, 78, 1.0);
    Color color2Accent = Color.fromRGBO(97, 37, 57, 1);
    Color color3 = Color.fromRGBO(82, 37, 70, 1.0);
    Color color3Accent = Color.fromRGBO(145, 63, 123, 1);
    Color color4 = Color.fromRGBO(44, 44, 44, 1.0);
    Color color4Accent = Color.fromRGBO(61, 61, 61, 1);
    return SizedBox(
      width: containerWidth,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines ?? 1,
        obscureText: obscure??false,
        maxLength: maxChars??40,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: text,
          hintStyle: TextStyle(color: hintColor ?? Colors.white),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red,width: 2),
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color1,width:2),
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color1Accent,width:2),
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          // validator: (text) {
          //   if (RegExp("\\bvitalii\\b", caseSensitive: false).hasMatch(text.toString())){
          //     return "Match found";
          //   }
          // },
        ),
      ),
    );
  }
}

class SansBold extends StatelessWidget {
  final text;
  final size;
  final color;
  const SansBold({super.key, required this.text, required this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.openSans(
      fontSize: size, 
      fontWeight: FontWeight.bold,
      color: color ?? Colors.white,
      ),
    );
  }
}

class Sans extends StatelessWidget {
  final text;
  final size;
  final color;
  const Sans({super.key, required this.text, required this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text, style: GoogleFonts.openSans(
        fontSize: size,
        fontWeight: FontWeight.normal,
        color: color ?? Colors.white,
      )
    );
  }
}


class TabsWeb extends StatefulWidget {
  final String title;
  final String route;
  const TabsWeb({super.key, required this.title, required this.route});

  @override
  State<TabsWeb> createState() => _TabsWebState();
}

class _TabsWebState extends State<TabsWeb> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go(widget.route);
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            isSelected = true;
          });
        },
        onExit: (_) {
          setState(() {
            isSelected = false;
          });
        },
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 100),
          curve: Curves.elasticIn,
          style: isSelected?GoogleFonts.oswald(
            shadows: [Shadow(color: Colors.white, offset: Offset(0, -6 ),
            )],
            fontSize: 25.0,
            color: Colors.transparent,
            decoration: TextDecoration.underline,
            decorationThickness: 2.0,
            // decorationColor: Colors.tealAccent,
            decorationColor: Color.fromRGBO(247, 55, 79, 1.0),
          ): 
          GoogleFonts.oswald(color: Colors.black, fontSize:20.0 ),
          child: Text(widget.title
          ),
        ),
      ),
    );
  }
}

class TabsMobile extends StatefulWidget {
  final String text;
  final String route;
  const TabsMobile({super.key, required this.text, required this.route});

  @override
  State<TabsMobile> createState() => _TabsMobileState();
}

class _TabsMobileState extends State<TabsMobile> {
  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      elevation: 20.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      color: Color.fromRGBO(139, 39, 51, 1),
      height: 50.0,
      minWidth: 200.0,
      child: Text(widget.text,
        style: GoogleFonts.openSans(
          fontSize: 20.0,
          color: Colors.white,
        )
      ),
      onPressed: () {
        context.go(widget.route);
      },
    );
  }
}


/// Elements used to display communication channel / conversations and messages
class ChatBox extends StatelessWidget {
  // Need to get all the info from the Chat data
  const ChatBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.account_balance_outlined),
        Sans(text: "User", size: 10.0),
      ],
    );
  }
}

class MessageBox extends StatelessWidget {
  const MessageBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}