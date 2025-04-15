import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../app_data.dart';


/*
A wrapper that provides main menu
*/
class HomePage extends StatefulWidget {
  final Widget childWidget;
  const HomePage({super.key, required this.childWidget});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {

  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  selectedIconTheme: IconThemeData(color: Colors.deepOrange),
                  extended: constraints.maxWidth >= 600, // Will Automatically show labels in the navigation rail if there is enough room
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      // icon: Icon(Icons.message),
                      icon: Icon(Icons.send),
                      label: Text('Messaging'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.logout),
                      label: Text('Logout'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_box),
                      label: Text('Find user'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_circle_outlined),
                      label: Text('My Account'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                  
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                      if (selectedIndex == 0) {
                        context.go('/generator');
                      } else if (selectedIndex == 1) {
                        context.go('/messages');
                      } else if (selectedIndex == 2) {
                        appState.logOut();
                        context.go('/login');
                      } else if (selectedIndex == 3) {
                        context.go('/home'); // Place holder to make sure I could go back in case logout button does not work
                      } else if (selectedIndex == 4) {
                        context.go('/generator');
                      } else if (selectedIndex == 5) {
                        context.go('/generator');
                      }
                    });
                  },
                ),
              ),
              SizedBox(child: VerticalDivider(width: 1.5, color: Colors.black)),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: widget.childWidget,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}