import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_data.dart';
import 'package:go_router/go_router.dart';


class GuestLoginPage extends StatelessWidget { // If state is not logged in, this is the first page the user sees
  const GuestLoginPage({super.key,});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    // final theme = Theme.of(context);
    // final style = theme.textTheme.headlineSmall!.copyWith(
    //   color: theme.colorScheme.primary, // Color suitable to be placed on top or primary color
    // );

    // TextField controllers
    var usrnmController = TextEditingController();
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        SizedBox(
          width: 350,
          child: TextField(
            controller: usrnmController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              hintStyle: TextStyle(
              ),
              hintText: 'username',
            )
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            appState.logIn("admin", "password");
            context.go('/generator');
          }, 
          child: Text("Log in"),
        ),
      ],
    );
  }
}
