import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class PasswordResetPage extends StatelessWidget {
  const PasswordResetPage({super.key});

  @override
  Widget build(BuildContext context) {
    // var appState = context.watch<MyAppState>();
    // final theme = Theme.of(context);
    // final style = theme.textTheme.headlineSmall!.copyWith(
    //   color: theme.colorScheme.primary, // Color suitable to be placed on top or primary color
    // );

    // TextField controllers, retrieve string user input
    var pswrdController = TextEditingController();
    var confrController = TextEditingController();

    // Visuals Control parameters
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
              controller: pswrdController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(boxCornerRadius),
                ),
                hintText: 'enter new password',
              ),
              obscureText: true,
            ),
          ),
        SizedBox(height: verticalSpacing),
        SizedBox(
            width: inputWidth,
            child: TextField(
              controller: confrController,
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
        ElevatedButton(
          onPressed: () => context.go('/login'),
          child: Text("Change"),
          )
      ],
    );
  }
}