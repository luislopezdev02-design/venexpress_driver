import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import '../widgets/common_widgets.dart';
import 'available_deliveries_screen.dart';
import 'commissions_screen.dart';
import 'delivery_claim_scanner_screen.dart';
import 'login_screen.dart';
import 'my_delivery_route_screen.dart';
import 'package_detail_screen.dart';
import 'packages_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  final _screens = const [
    _DashboardTab(),
    AvailableDeliveriesScreen(),
    PackagesScreen(),
    MyDeliveryRouteScreen(),
    CommissionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: _screens),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DeliveryClaimScannerScreen()),
          );
          if (mounted) {
            context.read<DriverProvider>().loadDashboard();
          }
        },
        backgroundColor: kPrimaryDark,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Reclamar Pedido'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(icon: Icons.dashboard_outlined, label: 'Inicio', index: 0),
            _navItem(icon: Icons.inbox_outlined, label: 'Disponibles', index: 1),
            const SizedBox(width: 48),
            _navItem(icon: Icons.alt_route, label: 'Mi Ruta', index: 3),
            _navItem(icon: Icons.attach_money, label: 'Comisiones', index: 4),
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

                      // Acceso directo a Pedidos Disponibles
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AvailableDeliveriesScreen()),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF2563EB)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.inbox_outlined, color: Color(0xFF2563EB)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Ver pedidos disponibles para reclamar',
                                  style: TextStyle(fontSize: 13, color: kPrimaryDark, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Icon(Icons.chevron_right, color: kMuted),
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
                        'Pedidos que tienes reclamados',
                        style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDark, fontSize: 16),
                      ),
                      const SizedBox(height: 10),

                      if (driverProvider.packages.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No tienes pedidos reclamados todavía. Ve a "Disponibles" para tomar uno.',
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
