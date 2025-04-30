import 'package:flutter/material.dart';
// import 'package:meida/backend/server_conn_controller.dart';
import 'package:provider/provider.dart';
import '../../app_data.dart';
import 'package:go_router/go_router.dart';



class LoginPage extends StatefulWidget { // If state is not logged in, this is the first page the user sees
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // TextField controllers that allow for retrieval / update of text in text input fields
  final usrnmController = TextEditingController();
  final pswrdController = TextEditingController();

  // Visual control parameters
  final inputWidth = 350.0;
  final verticalSpacing = 20.0;
  final boxCornerRadius = 8.0;

  @override
  void dispose() {
    usrnmController.dispose();
    pswrdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    
    return Builder(
      builder: (context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: verticalSpacing),
            SizedBox(
              width: inputWidth,
              child: TextField(
                controller: usrnmController, // Add controller to text input
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(boxCornerRadius),
                  ),
                  hintStyle: TextStyle(
                  ),
                  hintText: 'username',
                )
              ),
            ),
            SizedBox(height: verticalSpacing),
            SizedBox(
              width: inputWidth,
              child: TextField(
                controller: pswrdController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(boxCornerRadius),
                  ),
                  hintStyle: TextStyle(
                  ),
                  hintText: 'password',
                )
              ),
            ),
            SizedBox(height: verticalSpacing),
            Consumer<MyAppState>(
              builder: (_, appState, __) => ElevatedButton(
                onPressed: appState.isLoading ? null : () async {
                  String result = await appState.logIn(usrnmController.text, pswrdController.text);
                  // Upon success redirection happens automatically due to Consumer and notification
                  if (result != "" && context.mounted) { // In case of failed login we want to show an error message.
                    // appState.setNotLoading();
                    usrnmController.clear();
                    pswrdController.clear();
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
                      Text("Logging in ..."),
                    ],
                  )
                  : Text("Login"),
              )
            ),
            SizedBox(height: verticalSpacing),
            TextButton(
              onPressed: () => {
                context.go('/password_recovery'),
              },
              child: Text("Forgot Password?"),
            ),
          ],
        );
      }
    );
  }
}


