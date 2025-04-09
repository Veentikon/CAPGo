import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import '../app_data.dart';


class PasswordRecoveryPage extends StatelessWidget { // If state is not logged in, this is the first page the user sees
  // final Function() toReset;
  // const PasswordRecoveryPage({super.key, required this.toReset});
  const PasswordRecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // var appState = context.watch<MyAppState>();
    // final theme = Theme.of(context);
    // final style = theme.textTheme.headlineSmall!.copyWith(
    //   color: theme.colorScheme.primary, // Color suitable to be placed on top or primary color
    // );

    // TextField controllers
    var emailController = TextEditingController();
    var codeController = TextEditingController();

    // Customization parameters
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
            controller: emailController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(boxCornerRadius),
              ),
              hintStyle: TextStyle(
              ),
              hintText: 'email',
            )
          ),
        ),
        SizedBox(height: verticalSpacing),
        ElevatedButton(
          onPressed: () => {print("code requested")}, 
          child: Text("Send code"),
        ),
        SizedBox(height: verticalSpacing),
        SizedBox(
          width: inputWidth,
          child: TextField(
            controller: codeController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(boxCornerRadius),
              ),
              hintStyle: TextStyle(
              ),
              hintText: 'enter received code',
            )
          ),
        ),
        SizedBox(height: verticalSpacing),
        ElevatedButton(
          onPressed: () => context.go('/password_reset'),
          child: Text("Confirm"),
        ),
      ],
    );
  }
}
