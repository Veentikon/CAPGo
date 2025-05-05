import 'package:flutter/material.dart';
import 'package:meida/components/misc.dart';

class AuthWindowWeb extends StatefulWidget {
  final Widget child;
  const AuthWindowWeb({super.key, required this.child});

  @override
  State<AuthWindowWeb> createState() => _AuthWindowWebState();
}

class _AuthWindowWebState extends State<AuthWindowWeb> {
  
  Color color1 = Color.fromRGBO(247, 55, 79, 1.0);
  Color color1b = Color.fromRGBO(139, 39, 51, 1);
  Color color1Accent = Color.fromRGBO(230, 67, 86, 1);
  Color color2 = Color.fromRGBO(136, 48, 78, 1.0);
  Color color2Accent = Color.fromRGBO(97, 37, 57, 1);
  Color color3 = Color.fromRGBO(82, 37, 70, 1.0);
  Color color3Accent = Color.fromRGBO(145, 63, 123, 1);
  Color color4 = Color.fromRGBO(44, 44, 44, 1.0);
  Color color4Accent = Color.fromRGBO(61, 61, 61, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10.0,
        shadowColor: Colors.black,
        backgroundColor: color4Accent,
        // actionsPadding: EdgeInsets.all(2.0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TabsWeb(title: "Login", route: '/login'),
            SizedBox(width: 20.0),
            TabsWeb(title: "Register", route: '/register'),
          ],
        ),
      ),
      body: widget.child,
    );
  }
}