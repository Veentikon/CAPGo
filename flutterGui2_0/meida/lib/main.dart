import 'package:flutter/material.dart';
import 'package:meida/app_data.dart';
import 'package:meida/mobile/sign_up_mobile.dart';
import 'package:meida/web/login_web.dart';
import 'package:meida/web/sign_up_web.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:meida/mobile/login_mobile.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyAppState()),
        // ChangeNotifierProvider(create: (_) => AppSettings()),
      ],
      child: MyApp(),
    )
    // const MyApp()
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // final deviceWidth = WidgetsBinding.instance.window.physicalSize.width /
    //     WidgetsBinding.instance.window.devicePixelRatio;
    // final deviceWidth = View.of(context).devicePixelRatio;
    _router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) {
            final width = MediaQuery.of(context).size.width;
            return width > 800 ? LoginWeb() : LoginMobile();
          }
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) {
            final width = MediaQuery.of(context).size.width;
            return width > 800 ? SignUpWeb() : SignUpMobile();
          }
        ),
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}

