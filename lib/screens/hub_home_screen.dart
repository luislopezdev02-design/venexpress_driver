import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/route_model.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import '../widgets/common_widgets.dart';
import 'available_routes_screen.dart';
import 'hub_scanner_screen.dart';
import 'login_screen.dart';
import 'my_route_screen.dart';

/// Shell de navegación para el repartidor de HUB (driver_type =
/// 'hub'): rutas hub_transfer (recolección Aliado -> HUB) y
/// hub_distribution (HUB -> almacén destino). Equivalente móvil del
/// dashboard web para este mismo rol.
class HubHomeScreen extends StatefulWidget {
  const HubHomeScreen({super.key});

  @override
  State<HubHomeScreen> createState() => _HubHomeScreenState();
}

class _HubHomeScreenState extends State<HubHomeScreen> {
  int _tabIndex = 0;

  final _screens = const [
    _HubDashboardTab(),
    AvailableRoutesScreen(),
    MyRouteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final activeRoute = context.watch<DriverProvider>().activeRoute;

    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: _screens),
      floatingActionButton: activeRoute != null && activeRoute.isInProgress
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HubScannerScreen()),
                );
                if (!context.mounted) return;
                context.read<DriverProvider>().loadActiveRoute();
              },
              backgroundColor: kPrimaryDark,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(icon: Icons.dashboard_outlined, label: 'Inicio', index: 0),
            _navItem(icon: Icons.alt_route, label: 'Disponibles', index: 1),
            const SizedBox(width: 48),
            _navItem(icon: Icons.map_outlined, label: 'Mi Ruta', index: 2),
          ],
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int index}) {
    final isSelected = _tabIndex == index;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? kPrimaryDark : kMuted, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: isSelected ? kPrimaryDark : kMuted)),
          ],
        ),
      ),
    );
  }
}

class _HubDashboardTab extends StatefulWidget {
  const _HubDashboardTab();

  @override
  State<_HubDashboardTab> createState() => _HubDashboardTabState();
}

class _HubDashboardTabState extends State<_HubDashboardTab> {
  bool _isLoadingAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<DriverProvider>();
    await provider.loadActiveRoute();

    // Si no tiene ruta activa, adelantamos cuántas hay disponibles
    // para que el CTA de abajo diga algo más útil que "ve a revisar".
    if (!mounted || provider.activeRoute != null) return;

    setState(() => _isLoadingAvailable = true);
    await provider.loadAvailableRoutes();
    if (mounted) setState(() => _isLoadingAvailable = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driverProvider = context.watch<DriverProvider>();
    final activeRoute = driverProvider.activeRoute;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Hola, ${auth.user?.name.split(' ').first ?? ''}',
          style: const TextStyle(color: kPrimaryDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: kMuted),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: driverProvider.isLoadingRoute && activeRoute == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  const Text(
                    'Repartidor de HUB',
                    style: TextStyle(color: kMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Acción de escaneo vigente, calculada por el backend
                  // con el mismo criterio que el dashboard web (qué debe
                  // escanear ahora mismo: recolección, salida o recepción).
                  if (activeRoute?.hubScan != null) ...[
                    _HubScanCard(route: activeRoute!, hubScan: activeRoute.hubScan!),
                    const SizedBox(height: 20),
                  ],

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeRoute == null ? 'Sin ruta activa' : (activeRoute.name ?? 'Ruta #${activeRoute.id}'),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDark, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeRoute == null
                              ? (_isLoadingAvailable
                                  ? 'Buscando rutas disponibles...'
                                  : driverProvider.availableRoutes.isEmpty
                                      ? 'No hay rutas disponibles por el momento.'
                                      : '${driverProvider.availableRoutes.length} ruta(s) disponible(s) para tomar.')
                              : '${activeRoute.routeTypeLabel} · ${activeRoute.visitedStops} de ${activeRoute.totalStops} paradas',
                          style: const TextStyle(color: kMuted, fontSize: 13),
                        ),
                        if (activeRoute == null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AvailableRoutesScreen()),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimaryDark,
                                side: const BorderSide(color: kPrimaryDark),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Ver rutas disponibles'),
                            ),
                          ),
                        ] else if (activeRoute.isAssigned) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MyRouteScreen()),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimaryDark,
                                side: const BorderSide(color: kPrimaryDark),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Iniciar ruta'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Tarjeta de acción principal del dashboard de HUB: qué escanear
/// ahora mismo, con el mismo texto que ya usa dashboard.blade.php en
/// el portal web (RECOLECCIÓN EN ALIADO / SALIDA DESDE HUB / RECEPCIÓN
/// EN ALMACÉN) para que ambas experiencias digan siempre lo mismo.
class _HubScanCard extends StatelessWidget {
  final RouteModel route;
  final HubScanInfo hubScan;

  const _HubScanCard({required this.route, required this.hubScan});

  String get _contextLine {
    switch (hubScan.operation) {
      case 'collection':
        return 'Siguiente parada: ${hubScan.nextStopName ?? '—'}';
      case 'hub_departure':
        return 'Paquetes pendientes: ${hubScan.pendingCount ?? 0}';
      case 'hub_arrival':
        return 'Almacén: ${hubScan.warehouseName ?? '—'} · '
            'Paquetes por recibir: ${hubScan.pendingCount ?? 0}';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HubScannerScreen()),
        );
        if (context.mounted) context.read<DriverProvider>().loadActiveRoute();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kPrimaryDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      hubScan.title,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hubScan.subtitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _contextLine,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
