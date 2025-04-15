import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


/*
This class is essentially a wrapper for authentication pages: 
login, sign up, guest login, password recovery, password update
*/
class AuthenticationPage extends StatefulWidget {
  final Widget childWidget;
  const AuthenticationPage({super.key, required this.childWidget});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> with SingleTickerProviderStateMixin {
  int selectedScreen = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        selectedScreen = _tabController.index;
      });
    });
  }

  void switchScreen(int index) {
    setState(() {
      selectedScreen = index;
      _tabController.animateTo(index); // Sync the TabController with the index
    });
  }

  @override
  Widget build(BuildContext context) {
    // var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);
    // final style = theme.textTheme.headlineSmall!.copyWith(
    //   color: theme.colorScheme.primary, // Color suitable to be placed on top or primary color
    // );

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 50),
          Container(
            color: theme.canvasColor, // Changes TabBar background color
            child: TabBar(
              onTap: (value) => {
                if (value == 0) {
                  context.go('/login'),
                } else if (value == 1) {
                  context.go('/sign_up'),
                } else if (value == 2) {
                  context.go('/guest_login'),
                },
              },
              isScrollable: true,
              controller: _tabController,
              labelColor: Colors.deepOrange,
              indicatorColor: Colors.deepOrange,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
              tabAlignment: TabAlignment.center,
              tabs: [
                Tab(text: 'Log in'),
                Tab(text: 'Sign Up'),
                Tab(text: 'Continue as Guest'),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(child: widget.childWidget),
        ],
      ),
    );
  }
}
