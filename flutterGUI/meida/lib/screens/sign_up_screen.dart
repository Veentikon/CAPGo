import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meida/backend/server_conn_controller.dart';
import 'package:provider/provider.dart';
import '../app_data.dart';


class SignUpPage extends StatefulWidget {
  // final Function(int) onSwitch;
  // const SignUpPage({super.key, required this.onSwitch});
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpState();
}

class _SignUpState extends State<SignUpPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    final pswrdController = TextEditingController();
    final pConfController = TextEditingController();
    final usrnmController = TextEditingController();
    final emailController = TextEditingController();

    // var appState = context.watch<MyAppState>();
    // final theme = Theme.of(context);
    // final style = theme.textTheme.headlineSmall!.copyWith(
    //   color: theme.colorScheme.primary, // Color suitable to be placed on top or primary color
    // );

    // Parameters to control some visuals
    // Later will change it so that it is sized dynamically.
    var inputWidth = 350.0;
    var verticalSpacing = 20.0;
    var boxCornerRadius = 8.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: verticalSpacing),
        SizedBox(
            width: inputWidth,
            child: TextField(
              controller: usrnmController, // Add controller to retrieve user input
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(boxCornerRadius),
                ),
                hintText: 'username',
              ),
              obscureText: false,
            ),
          ),
        SizedBox(height: verticalSpacing),
        SizedBox(
            width: inputWidth,
            child: TextField(
              controller: pswrdController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(boxCornerRadius),
                ),
                hintText: 'password',
              ),
              obscureText: true,
            ),
          ),
        SizedBox(height: verticalSpacing),
        SizedBox(
            width: inputWidth,
            child: TextField(
              controller: pConfController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(boxCornerRadius),
                ),
                hintText: 'confirm password',
              ),
              obscureText: true,
            ),
          ),
        SizedBox(height: verticalSpacing),
        SizedBox(
            width: inputWidth,
            child: TextField(
              controller: emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(boxCornerRadius),
                ),
                hintText: 'email',
              ),
              obscureText: false,
            ),
          ),
        SizedBox(height: verticalSpacing),
        ElevatedButton(
          onPressed: () async {
            if (pswrdController.text != pConfController.text || !emailController.text.contains("@")) {
              // Leave username
              pswrdController.clear();
              pConfController.clear();
              emailController.clear();
              logger.w("Passwords do not match or invalid email");
            } else {
              bool result = await appState.signUp(usrnmController.text, pswrdController.text, emailController.text); // Don't wait for server confirmation?
              if (!mounted) { return; }
              if (result) {
                context.go('/login');
              } else if (!result) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Sign-up failed. Please try again."))
                );
              }
            }
          }, 
          child: Text("Sign up"),
          )
      ],
    );
  }
}