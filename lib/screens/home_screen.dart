import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import '../widgets/common_widgets.dart';
import 'my_route_screen.dart';
import 'commissions_screen.dart';
import 'login_screen.dart';
import 'package_detail_screen.dart';
import 'packages_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  final _screens = const [
    _DashboardTab(),
    PackagesScreen(),
    CommissionsScreen(),
    MyRouteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: _screens),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
          );
        },
        backgroundColor: kPrimaryDark,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Realizar Pedidos'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(icon: Icons.dashboard_outlined, label: 'Inicio', index: 0),
            _navItem(icon: Icons.route_outlined, label: 'Mi Ruta', index: 3),
            _navItem(icon: Icons.inventory_2_outlined, label: 'Pedidos', index: 1),
            const SizedBox(width: 48),
            _navItem(icon: Icons.attach_money, label: 'Comisiones', index: 2),
            IconButton(
              icon: const Icon(Icons.logout, color: kMuted),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DriverProvider>();
      provider.loadDashboard();
      provider.loadPackages();
      provider.loadActiveRoute();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driverProvider = context.watch<DriverProvider>();
    final dashboard = driverProvider.dashboard;

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
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DriverProvider>().loadDashboard(),
        child: driverProvider.isLoadingDashboard && dashboard == null
            ? const Center(child: CircularProgressIndicator())
            : driverProvider.dashboardError != null && dashboard == null
                ? Center(
                    child: Text(driverProvider.dashboardError!, style: const TextStyle(color: kMuted)),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          StatCard(
                            label: 'Por entregar',
                            value: '${dashboard?.pendingToDeliver ?? 0}',
                            icon: Icons.local_shipping_outlined,
                            accentColor: const Color(0xFF2563EB),
                          ),
                          StatCard(
                            label: 'Entregados hoy',
                            value: '${dashboard?.deliveredToday ?? 0}',
                            icon: Icons.today_outlined,
                            accentColor: const Color(0xFF16A34A),
                          ),
                          StatCard(
                            label: 'Total entregados',
                            value: '${dashboard?.delivered ?? 0}',
                            icon: Icons.inventory_2_outlined,
                          ),
                          StatCard(
                            label: 'COD por cobrar',
                            value: '${dashboard?.codPending ?? 0}',
                            icon: Icons.payments_outlined,
                            accentColor: const Color(0xFFB45309),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Banner de estado de la ruta
                      if (driverProvider.activeRoute != null)
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MyRouteScreen()),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: driverProvider.activeRoute!.isInProgress
                                  ? const Color(0xFF16A34A).withOpacity(0.08)
                                  : const Color(0xFFF59E0B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: driverProvider.activeRoute!.isInProgress
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  driverProvider.activeRoute!.isInProgress
                                      ? Icons.route
                                      : Icons.pending_actions,
                                  color: driverProvider.activeRoute!.isInProgress
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFB45309),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    driverProvider.activeRoute!.isInProgress
                                        ? 'Ruta en curso: ${driverProvider.activeRoute!.visitedStops}/${driverProvider.activeRoute!.totalStops} agencias visitadas'
                                        : 'Tienes una ruta asignada por iniciar',
                                    style: const TextStyle(fontSize: 13, color: kPrimaryDark, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: kMuted),
                              ],
                            ),
                          ),
                        ),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: kPrimaryDark,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Comisiones pendientes', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(
                              '\$${dashboard?.commissionPendingUsd.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ya pagado: \$${dashboard?.commissionPaidUsd.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  '\$${dashboard?.commissionRatePerPackage.toStringAsFixed(2) ?? '0.00'} / paquete',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Pedidos pendientes',
                        style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDark, fontSize: 16),
                      ),
                      const SizedBox(height: 10),

                      if (driverProvider.packages.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No tienes pedidos pendientes. Escanea una guía para empezar.',
                            style: TextStyle(color: kMuted),
                          ),
                        )
                      else
                        ...driverProvider.packages.take(5).map((package) {
                          return PackageListTile(
                            package: package,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PackageDetailScreen(packageId: package.id),
                                ),
                              );
                            },
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}
