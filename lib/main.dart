import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/driver_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/common_widgets.dart';

void main() {
  runApp(const VenexpressDriverApp());
}

class VenexpressDriverApp extends StatelessWidget {
  const VenexpressDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: MaterialApp(
        title: 'Venexpress Repartidor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: kBackground,
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimaryDark,
            primary: kPrimaryDark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
          ),
        ),
        home: const _SplashGate(),
      ),
    );
  }
}

/// Pantalla invisible que decide a dónde navegar apenas abre la app:
/// si hay un token guardado y válido, entra directo al Home; si no,
/// muestra el login.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AuthProvider>().checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.unknown) {
      return const Scaffold(
        backgroundColor: kPrimaryDark,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (auth.status == AuthStatus.authenticated) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
