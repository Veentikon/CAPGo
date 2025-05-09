import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meida/app_data.dart';
import 'package:meida/components/misc.dart';
import 'package:provider/provider.dart';

class HomeWeb extends StatefulWidget {
  final Widget child;
  const HomeWeb({super.key, required this.child});

  @override
  State<HomeWeb> createState() => _HomeWebState();
}

class _HomeWebState extends State<HomeWeb> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Color.fromRGBO(44, 44, 44, 1.0),
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  selectedIconTheme: IconThemeData(color:Color.fromRGBO(136, 48, 78, 1.0)),
                  extended: constraints.maxWidth >= 900,
                  backgroundColor: Color.fromRGBO(44, 44, 44, 1.0),
                  minExtendedWidth: 170,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home, color: Color.fromRGBO(230, 67, 86, 1),), 
                      label: Sans(text: "Home", size: 15.0),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.message_outlined, color: Color.fromRGBO(230, 67, 86, 1),), 
                      label: Sans(text: "Messages", size: 15.0),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_circle_outlined, color: Color.fromRGBO(230, 67, 86, 1),),
                      label: Sans(text: "Profile", size: 15.0),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings, color: Color.fromRGBO(230, 67, 86, 1)),
                      label: Sans(text: "Setting", size: 15.0,),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.logout, color: Color.fromRGBO(230, 67, 86, 1)),
                      label: Sans(text: "Logout", size: 15.0,),
                    ),
                  ], 
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {

                      selectedIndex = value;
                      switch (selectedIndex) {
                        case 0:
                          context.go('/');
                        case 1:
                          context.go('/messages');
                        case 2:
                          context.go('/profile');
                        case 3:
                          context.go('/settings');
                        case 4:
                          appState.logOut();
                        default:
                          //Do something else
                      }
                    });
                  },
                )
              ),
              SizedBox(child: VerticalDivider(width: 0.6, color: Color.fromRGBO(230, 67, 86, 1))),
                Expanded(
                  child: Container(
                  color: Color.fromRGBO(61, 61, 61, 1),
                  child: widget.child,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}