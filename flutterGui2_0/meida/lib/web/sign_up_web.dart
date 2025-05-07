import 'package:flutter/material.dart';
import 'package:meida/app_data.dart';
import 'package:meida/components/misc.dart';
import 'package:provider/provider.dart';

class SignUpWeb extends StatefulWidget {
  const SignUpWeb({super.key});

  @override
  State<SignUpWeb> createState() => _SignUpWebState();
}

class _SignUpWebState extends State<SignUpWeb> {
  final TextEditingController uNameController = TextEditingController();
  final TextEditingController pswrdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pConfController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    uNameController.dispose();
    pswrdController.dispose();
    emailController.dispose();
    pConfController.dispose();

  }

  @override
  Widget build(BuildContext context) {
    Color color1 = Color.fromRGBO(247, 55, 79, 1.0);
    Color color1b = Color.fromRGBO(139, 39, 51, 1);
    Color color1Accent = Color.fromRGBO(230, 67, 86, 1);
    Color color2 = Color.fromRGBO(136, 48, 78, 1.0);
    Color color2Accent = Color.fromRGBO(97, 37, 57, 1);
    Color color3 = Color.fromRGBO(82, 37, 70, 1.0);
    Color color3Accent = Color.fromRGBO(145, 63, 123, 1);
    Color color4 = Color.fromRGBO(44, 44, 44, 1.0);
    Color color4Accent = Color.fromRGBO(61, 61, 61, 1);
    var appState = context.watch<MyAppState>();

    return Scaffold(
      
      // appBar: AppBar(
      //   elevation: 10.0,
      //   shadowColor: Colors.black,
      //   backgroundColor: color4Accent,
      //   // actionsPadding: EdgeInsets.all(2.0),
      //   title: Row(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     // crossAxisAlignment: CrossAxisAlignment.center,
      //     children: [
      //       SansBold(text: "Login", size: 18.0),
      //       SizedBox(width: 10.0,),
      //       SansBold(text: "Sign up", size: 18.0),
      //     ],
      //   ),
      // ),
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
            Consumer<MyAppState>(
              builder: (_, appState, __) => MaterialButton(
                elevation: 20.0,
                color: color1b,
                focusColor: color1Accent,
                height: 50,
                minWidth: 90,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                onPressed: appState.isLoading ? null : () async {
                  String result = await appState.signUp(uNameController.text, pswrdController.text, emailController.text);
                  // Upon success redirection happens automatically due to Consumer and notification
                  if (result != "" && context.mounted) { // In case of failed login we want to show an error message.
                    // appState.setNotLoading();
                    uNameController.clear();
                    pswrdController.clear();
                    pConfController.clear();
                    emailController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result))); // Propagate the error message to the user
                  }
                },
                child: appState.isLoading 
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.5,),
                      ),
                      SizedBox(width: 8),
                      Sans(text: "Loading", size: 17.0),
                    ],
                  )
                  : Sans(text: "Sign up", size: 17.0),
              )
            ),
          ],
        ),
      ),
    );
  }
}