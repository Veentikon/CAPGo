import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meida/app_data.dart';
import 'package:meida/components/misc.dart';
import 'package:provider/provider.dart';

class HomeMobile extends StatefulWidget {
  final Widget child;
  const HomeMobile({super.key, required this.child});

  @override
  State<HomeMobile> createState() => _HomeMobileState();
}

class _HomeMobileState extends State<HomeMobile> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Color.fromRGBO(44, 44, 44, 1.0),
          appBar: AppBar(
            backgroundColor: Color.fromRGBO(61, 61, 61, 1),
            iconTheme: IconThemeData(
              size: 35.0,
              color: Color.fromRGBO(230, 67, 86, 1),
            ),
          ),
          endDrawer: Drawer(
            width: 100,
            backgroundColor: Color.fromRGBO(44, 44, 44, 1.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 20.0,
              children: [
                IconButton(onPressed: ()=>context.go('/'), icon: Icon(Icons.home), color: Color.fromRGBO(230, 67, 86, 1)),
                IconButton(onPressed: ()=>context.go('/messages'), icon: Icon(Icons.message_outlined), color: Color.fromRGBO(230, 67, 86, 1)),
                IconButton(onPressed: ()=>context.go('/profile'), icon: Icon(Icons.account_circle_outlined), color: Color.fromRGBO(230, 67, 86, 1)),
                IconButton(onPressed: ()=>context.go('/settings'), icon: Icon(Icons.settings), color: Color.fromRGBO(230, 67, 86, 1),),
                IconButton(onPressed: ()=>appState.logOut(), icon: Icon(Icons.logout), color: Color.fromRGBO(230, 67, 86, 1),),
                // TabsMobile(text: "Home", route: '/'),
                // SizedBox(height: 20.0,),
                // TabsMobile(text: "Messages", route: '/messages'),
                // SizedBox(height: 20.0),
                // TabsMobile(text: "Profile", route: '/profile'),
                // SizedBox(height: 20.0,),
                // TabsMobile(text: "Settings", route: '/settings'),
                // SizedBox(height: 20.0,),
                // TabsMobile(text: 'Logout', route: '/logout'),
              ],
            ),
          ),
          body: widget.child,
        );
      }
    );
  }
}


// SafeArea(
                //   child: NavigationRail(
                //     selectedIconTheme: IconThemeData(color:Color.fromRGBO(136, 48, 78, 1.0)),
                //     extended: constraints.maxWidth >= 900,
                //     backgroundColor: Color.fromRGBO(44, 44, 44, 1.0),
                //     minExtendedWidth: 170,
                //     destinations: [
                //       NavigationRailDestination(
                //         icon: Icon(Icons.home, color: Color.fromRGBO(230, 67, 86, 1),), 
                //         label: Sans(text: "Home", size: 15.0),
                //       ),
                //       NavigationRailDestination(
                //         icon: Icon(Icons.message_outlined, color: Color.fromRGBO(230, 67, 86, 1),), 
                //         label: Sans(text: "Messages", size: 15.0),
                //       ),
                //       NavigationRailDestination(
                //         icon: Icon(Icons.account_circle_outlined, color: Color.fromRGBO(230, 67, 86, 1),),
                //         label: Sans(text: "Profile", size: 15.0),
                //       ),
                //       NavigationRailDestination(
                //         icon: Icon(Icons.settings, color: Color.fromRGBO(230, 67, 86, 1)),
                //         label: Sans(text: "Setting", size: 15.0,),
                //       ),
                //       NavigationRailDestination(
                //         icon: Icon(Icons.logout, color: Color.fromRGBO(230, 67, 86, 1)),
                //         label: Sans(text: "Logout", size: 15.0,),
                //       ),
                //     ], 
                //     selectedIndex: selectedIndex,
                //     onDestinationSelected: (value) {
                //       setState(() {
            
                //         selectedIndex = value;
                //         switch (selectedIndex) {
                //           case 0:
                //             context.go('/');
                //           case 1:
                //             context.go('/messages');
                //           case 2:
                //             context.go('/profile');
                //           case 3:
                //             context.go('/settings');
                //           case 4:
                //             appState.logOut();
                //           default:
                //             //Do something else
                //         }
                //       });
                //     },
                //   )
                // ),
                // SizedBox(child: VerticalDivider(width: 1.5, color: Color.fromRGBO(230, 67, 86, 1))),
                //   Expanded(
                //     child: Container(
                //     color: Color.fromRGBO(61, 61, 61, 1),
                //     child: widget.child,
                //   ),
                // ),