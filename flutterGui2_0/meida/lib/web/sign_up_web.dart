import 'package:flutter/material.dart';
import 'package:meida/components/misc.dart';

class SignUpWeb extends StatefulWidget {
  const SignUpWeb({super.key});

  @override
  State<SignUpWeb> createState() => _SignUpWebState();
}

class _SignUpWebState extends State<SignUpWeb> {
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

    final TextEditingController uNameController = TextEditingController();
    final TextEditingController pswrdController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController pConfController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        elevation: 10.0,
        shadowColor: Colors.black,
        backgroundColor: color4Accent,
        actions: [
          SansBold(text: "Login", size: 18.0),
          SansBold(text: "Sign up", size: 18.0),
        ],
      ),
      backgroundColor: color4,
      body: Center(
        child: Column(
          spacing: 11.0,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 100,),
            SansBold(text: "Sign up", size: 23.0),
            TextForm(text: "Email", controller: emailController, containerWidth: 320.0,),
            TextForm(text: "Username", controller: uNameController, containerWidth: 320.0,),
            TextForm(text: "Password", controller: pswrdController, containerWidth: 320.0,obscure: true,),
            TextForm(text: "Confirm Password", controller: pConfController, containerWidth: 320.0,obscure: true,),
            MaterialButton(
              elevation: 20.0,
              color: color1Accent,
              focusColor: color1Accent,
              height: 50,
              minWidth: 90,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              onPressed: () {},
              child: Sans(text: "Submit", size: 17.0)
            ),
          ],
        ),
      ),
    );
  }
}