import 'package:flutter/material.dart';
import 'package:meida/app_data.dart';
import 'package:meida/components/misc.dart';
import 'package:meida/mobile/home_mobile.dart';
import 'package:meida/mobile/messages_mobile.dart';
import 'package:meida/mobile/profile_mobile.dart';
import 'package:meida/mobile/settings_mobile.dart';
import 'package:meida/mobile/sign_up_mobile.dart';
import 'package:meida/web/auth_window.dart';
import 'package:meida/web/home_web.dart';
import 'package:meida/web/login_web.dart';
import 'package:meida/web/message_screen_web.dart';
import 'package:meida/web/profile_web.dart';
import 'package:meida/web/settings_web.dart';
import 'package:meida/web/sign_up_web.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
// import 'package:meida/mobile/login_mobile.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyAppState()),
        // ChangeNotifierProvider(create: (_) => AppSettings()),
      ],
      child: MyApp(),
    )
  );
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoRouter? _router;
  bool? _isMobile;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MyAppState>(context);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    if (_isMobile != isMobile || _router == null) {
      _isMobile = isMobile;

      _router = GoRouter(
        initialLocation: '/login',
        refreshListenable: appState,
        routes: [
          ShellRoute(
            builder: (context, state, child) {
              return AuthWindowWeb(child: child); // Update if you have mobile variant
            },
            routes: [
              GoRoute(
                path: '/login',
                // builder: (context, state) => isMobile ? LoginMobile() : LoginWeb(),
                builder: (context, state) => LoginWeb(),
              ),
              GoRoute(
                path: '/register',
                builder: (context, state) => isMobile ? SignUpMobile() : SignUpWeb(),
              ),
            ],
          ),
          ShellRoute(
            builder: (context, state, child) {
              return isMobile ? HomeMobile(child: child) : HomeWeb(child: child);
            },
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                  backgroundColor: Color.fromRGBO(61, 61, 61, 1),
                  body: Center(child: SansBold(text: "This is home screen", size: 22.0)),
                ),
              ),
              GoRoute(
                path: '/messages',
                builder: (context, state) => isMobile ? MessageScreenMobile() : MessageScreenWeb(),
              ),
              GoRoute(
                path: '/profile', 
                builder: (context, state) => isMobile ? ProfileMobile() : ProfileWeb(),
              ),
              GoRoute(
                path: '/settings', 
                builder: (context, state) => isMobile ? SettingsMobile() : SettingsWeb(),
              ),
            ],
          ),
        ],
        redirect: (context, state) {
          final loggedIn = appState.loggedIn;
          final unauthRoutes = {'/login', '/register'};
          final isInAuthPage = unauthRoutes.contains(state.matchedLocation);

          if (!loggedIn && isInAuthPage) return state.matchedLocation;
          if (!loggedIn && !isInAuthPage) return '/login';
          if (loggedIn && isInAuthPage) return '/';
          return null;
        },
      );
    }

    return MaterialApp.router(routerConfig: _router!);
  }
}
