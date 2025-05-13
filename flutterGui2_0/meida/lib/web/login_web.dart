import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meida/app_data.dart';
import 'package:meida/components/misc.dart';
import 'package:provider/provider.dart';
import 'package:meida/backend/server_conn_controller.dart';

class LoginWeb extends StatefulWidget {
  const LoginWeb({super.key});

  @override
  State<LoginWeb> createState() => _LoginWebState();
}

class _LoginWebState extends State<LoginWeb> {
  final TextEditingController uNameController = TextEditingController();
  final TextEditingController pswrdController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    uNameController.dispose();
    pswrdController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    Color color1 = Color.fromRGBO(247, 55, 79, 1.0);
    Color color1b = Color.fromRGBO(139, 39, 51, 1);
    Color color1Accent = Color.fromRGBO(230, 67, 86, 1);
    Color color2 = Color.fromRGBO(136, 48, 78, 1.0);
    Color color2Accent = Color.fromRGBO(97, 37, 57, 1);
    Color color3 = Color.fromRGBO(82, 37, 70, 1.0);
    Color color3Accent = Color.fromRGBO(145, 63, 123, 1);
    Color color4 = Color.fromRGBO(44, 44, 44, 1.0);
    Color color4Accent = Color.fromRGBO(61, 61, 61, 1);

    return Scaffold(
      backgroundColor: color4,
      body: Center(
        child: Column(
          spacing: 20.0,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 100,),
            SansBold(text: "Login", size: 23.0),
            TextForm(text: "Username", controller: uNameController, containerWidth: 320.0,),
            TextForm(text: "Password", controller: pswrdController, containerWidth: 320.0,obscure: true,),
            Consumer<MyAppState>(
              builder: (_, appState, __) => MaterialButton(
                elevation: 20.0,
                color: color1b,
                focusColor: color1Accent,
                height: 50,
                minWidth: 90,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                onPressed: appState.isLoading ? null : () async {
                  try {
                    String result = await appState.logIn(uNameController.text, pswrdController.text);
                    // Upon success redirection happens automatically due to Consumer and notification
                    if (result != "" && context.mounted) { // In case of failed login we want to show an error message.
                      // appState.setNotLoading();
                      uNameController.clear();
                      pswrdController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result))); // Propagate the error message to the user
                    }
                  } catch (e) {
                    logger.w("Login error");
                    appState.isLoading = false;
                  }
                },
                child: appState.isLoading 
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: color1),
                      ),
                      SizedBox(width: 8),
                      Sans(text: "Loading", size: 17.0),
                    ],
                  )
                  : Sans(text: "Login", size: 17.0),
              )
            ),
          ],
        ),
      ),
    );
  }
}
