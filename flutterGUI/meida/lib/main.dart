import 'backend/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';
import 'package:go_router/go_router.dart';
import 'screens/generator_screen.dart';
import 'screens/authentication/login_screen.dart';
import 'screens/authentication/sign_up_screen.dart';
import 'screens/authentication/guest_login.dart';
import 'screens/authentication/password_recovery_screen.dart';
import 'screens/authentication/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/authentication/password_reset.dart';

// Programm entry point
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyAppState()),
        ChangeNotifierProvider(create: (_) => AppSettings()),
      ],
      child: MyApp(),
    )
  );
}

/*
The code in MyApp sets up the whole app. It creates the app-wide state, names the app, defines the visual theme, and sets "home"
widget-the starting point of your app 
*/

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // _MyAppState createState() => _MyAppState();
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState(){
    super.initState();
    // _initSeverConnection(); // Delay connecting to the server until the user tries to use a funcion of authorization page (login, etc.)
  }

  // // Function to initialize server connection
  // Future<void> _initSeverConnection() async {
  //   final appState = Provider.of<MyAppState>(context, listen: false); // Access appState after context is available
  //   await appState.connectToServer();
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAppState>(
      builder: (context, appState, child) {
        final GoRouter router = GoRouter(
          initialLocation: '/login', // Redirect the initial route to '/login'
          routes: [
            ShellRoute(
              navigatorKey: _navigatorKey,
              builder: (context, state, child) {
                return AuthenticationPage(childWidget: child);
              },
              routes: [
                GoRoute(
                  path: '/login',
                  name: 'login',
                  builder: (context, state) => LoginPage(),
                ),
                GoRoute(
                  path: '/sign_up',
                  name: 'sign_up',
                  builder: (context, state) => SignUpPage(),
                ),
                GoRoute(
                  path: '/guest_login',
                  name: 'guest_login',
                  builder: (context, state) => GuestLoginPage(),
                ),
                GoRoute(
                  path: '/password_reset',
                  name: 'password_reset',
                  builder: (context, state) => PasswordResetPage(),
                ),
                GoRoute(
                  path: '/password_recovery',
                  name: 'password_recovery',
                  builder: (context, state) => PasswordRecoveryPage(),
                ),
              ],
            ),
            ShellRoute(
              navigatorKey: _navigatorKey,
              builder: (context, state, child) {
                return HomePage(childWidget: child);
              },
              routes: [
                GoRoute(
                  path: '/generator',
                  name: 'generator',
                  builder: (context, state) => GeneratorPage(),
                ),
                GoRoute( // This is temporary solution, ===========================================
                  path: '/',
                  name: '/',
                  builder: (context, state) => GeneratorPage(),
                ),
                GoRoute(
                  path: '/messages',
                  name: 'messages',
                  builder: (context, state) => MessagesScreen(),
                ),
                GoRoute(
                  path: '/logout',
                  name: 'logout',
                  builder: (context, state) => LoginPage(),
                ),
                GoRoute(
                  path: '/find_user',
                  name: 'find_user',
                  builder: (context, state) => Scaffold(),
                ),
              ],
            ),
          ],
          redirect: (BuildContext context, GoRouterState state) {
            // final isLoggingIn = state.matchedLocation == '/login';
            final loggedIn = appState.loggedInAsUser;

            final unauthRoutes = {
              '/login',
              '/sign_up',
              '/guest_login',
              '/password_reset',
              '/password_recovery',
            };

            final isInAuthPage = unauthRoutes.contains(state.matchedLocation);
            
            if (!loggedIn && isInAuthPage) {
              return state.matchedLocation;
            } else if (loggedIn && isInAuthPage) {
              return '/generator';
            }
            return null;
          },
        );

        return MaterialApp.router(
          title: "Meida",
          routerConfig: router,  // Here we pass the router
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            brightness: Brightness.light,
          ),
        );
      },
    );
  }
}
