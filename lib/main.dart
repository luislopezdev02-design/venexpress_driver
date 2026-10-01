import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/driver_provider.dart';
import 'screens/home_screen.dart';
import 'screens/hub_home_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/common_widgets.dart';

/// Permite volver al login desde fuera de un BuildContext (ver
/// AuthProvider.onSessionExpired), igual que el botón de "Salir".
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const VenexpressDriverApp());
}

class VenexpressDriverApp extends StatelessWidget {
  const VenexpressDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()
            ..onSessionExpired = () {
              appNavigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
        ),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
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

    if (auth.status == AuthStatus.offline) {
      return Scaffold(
        backgroundColor: kPrimaryDark,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                  auth.errorMessage ?? 'No se pudo conectar con Venexpress.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.read<AuthProvider>().checkSession(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (auth.status == AuthStatus.authenticated) {
      return auth.driver?.driverType == 'hub' ? const HubHomeScreen() : const HomeScreen();
    }

    return const LoginScreen();
  }
}
